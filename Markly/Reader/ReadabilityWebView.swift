//
//  ReadabilityWebView.swift
//  Markly
//

import Foundation
import WebKit

@MainActor
final class ReadabilityWebView: NSObject, WKNavigationDelegate {
    private var webView: WKWebView?
    private var continuation: CheckedContinuation<ReaderExtractionPayload, Error>?
    private var timeoutTask: Task<Void, Never>?
    private var hasFinished = false

    func extract(from url: URL) async throws -> ReaderExtractionPayload {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                Task { @MainActor in
                    self.continuation = continuation
                    self.startLoading(url)
                }
            }
        } onCancel: {
            Task { @MainActor in
                self.cancel()
            }
        }
    }

    func cancel() {
        finish(with: .failure(CancellationError()))
    }

    private func startLoading(_ url: URL) {
        hasFinished = false

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.isHidden = true
        self.webView = webView

        var request = URLRequest(url: url)
        request.timeoutInterval = 25
        request.setValue(
            "Mozilla/5.0 AppleWebKit/605.1.15 (KHTML, like Gecko) MarklyReader/1.0",
            forHTTPHeaderField: "User-Agent"
        )

        timeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            await MainActor.run {
                self?.finish(with: .failure(ReaderExtractionError.extractionFailed))
            }
        }

        webView.load(request)
    }

    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            self.runReadability()
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            self.finish(with: .failure(error))
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            self.finish(with: .failure(error))
        }
    }

    private func runReadability() {
        guard let webView else {
            finish(with: .failure(ReaderExtractionError.extractionFailed))
            return
        }

        guard let scriptURL = Bundle.main.url(forResource: "Readability", withExtension: "js"),
              let readabilityScript = try? String(contentsOf: scriptURL, encoding: .utf8)
        else {
            finish(with: .failure(ReaderExtractionError.readabilityUnavailable))
            return
        }

        let script = readabilityScript + "\n" + Self.extractionScript

        webView.evaluateJavaScript(script) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }

                if let error {
                    self.finish(with: .failure(error))
                    return
                }

                guard let json = result as? String,
                      let data = json.data(using: .utf8)
                else {
                    self.finish(with: .failure(ReaderExtractionError.unsupported))
                    return
                }

                do {
                    let payload = try JSONDecoder().decode(ReaderExtractionPayload.self, from: data)
                    self.finish(with: .success(payload))
                } catch {
                    self.finish(with: .failure(error))
                }
            }
        }
    }

    private func finish(with result: Result<ReaderExtractionPayload, Error>) {
        guard !hasFinished else { return }
        hasFinished = true

        timeoutTask?.cancel()
        timeoutTask = nil

        webView?.stopLoading()
        webView?.navigationDelegate = nil
        webView = nil

        guard let continuation else { return }
        self.continuation = nil

        switch result {
        case .success(let payload):
            continuation.resume(returning: payload)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
}

private extension ReadabilityWebView {
    static let extractionScript = """
    (function() {
      function pickMeta(selectors) {
        for (const selector of selectors) {
          const node = document.querySelector(selector);
          if (!node) { continue; }
          const value = node.getAttribute('content') || node.getAttribute('value') || node.getAttribute('datetime') || node.textContent;
          if (value && value.trim()) { return value.trim(); }
        }
        return null;
      }

      function absoluteURL(raw) {
        if (!raw) { return null; }
        try { return new URL(raw, document.baseURI || location.href).href; }
        catch (_) { return null; }
      }

      function firstSrcsetURL(value) {
        if (!value) { return null; }
        const first = value.split(',')[0];
        return first ? first.trim().split(/\\s+/)[0] : null;
      }

      function imageURL(node) {
        if (!node) { return null; }
        return absoluteURL(
          node.getAttribute('src') ||
          node.getAttribute('data-src') ||
          node.getAttribute('data-original') ||
          firstSrcsetURL(node.getAttribute('srcset')) ||
          firstSrcsetURL(node.getAttribute('data-srcset'))
        );
      }

      function cleanText(value) {
        return (value || '').replace(/\\s+/g, ' ').trim();
      }

      function mergeRuns(runs) {
        const merged = [];
        for (const run of runs) {
          if (!run || !run.text) { continue; }
          const previous = merged[merged.length - 1];
          if (
            previous &&
            previous.bold === run.bold &&
            previous.italic === run.italic &&
            previous.code === run.code &&
            previous.href === run.href
          ) {
            previous.text += run.text;
          } else {
            merged.push(run);
          }
        }
        return merged.filter(run => run.text.trim().length > 0);
      }

      function inlineRuns(node, style) {
        const inherited = style || { bold: false, italic: false, code: false, href: null };
        let runs = [];

        if (!node) { return runs; }

        if (node.nodeType === Node.TEXT_NODE) {
          if (node.nodeValue) {
            runs.push({
              text: node.nodeValue,
              bold: inherited.bold,
              italic: inherited.italic,
              code: inherited.code,
              href: inherited.href
            });
          }
          return runs;
        }

        if (node.nodeType !== Node.ELEMENT_NODE) {
          return runs;
        }

        const tag = node.tagName.toLowerCase();
        if (tag === 'script' || tag === 'style' || tag === 'noscript') {
          return runs;
        }

        if (tag === 'br') {
          return [{ text: '\\n', bold: inherited.bold, italic: inherited.italic, code: inherited.code, href: inherited.href }];
        }

        const nextStyle = {
          bold: inherited.bold || tag === 'strong' || tag === 'b',
          italic: inherited.italic || tag === 'em' || tag === 'i',
          code: inherited.code || tag === 'code' || tag === 'kbd' || tag === 'samp',
          href: tag === 'a' ? absoluteURL(node.getAttribute('href')) : inherited.href
        };

        for (const child of Array.from(node.childNodes)) {
          runs = runs.concat(inlineRuns(child, nextStyle));
        }

        return mergeRuns(runs);
      }

      function blockText(node) {
        return cleanText(node ? node.textContent : '');
      }

      function captionFor(figure) {
        const caption = figure ? figure.querySelector('figcaption') : null;
        return caption ? blockText(caption) : null;
      }

      function listItems(node) {
        return Array.from(node.children)
          .filter(child => child.tagName && child.tagName.toLowerCase() === 'li')
          .map(child => inlineRuns(child))
          .filter(item => item.map(run => run.text).join('').trim().length > 0);
      }

      function blocksFromNode(node) {
        if (!node || node.nodeType !== Node.ELEMENT_NODE) { return []; }

        const tag = node.tagName.toLowerCase();
        const blocks = [];

        if (/^h[1-6]$/.test(tag)) {
          const text = inlineRuns(node);
          if (blockText(node)) {
            blocks.push({ type: 'heading', level: Number(tag.substring(1)), text: text });
          }
          return blocks;
        }

        if (tag === 'p') {
          const image = node.querySelector(':scope > img');
          if (image && blockText(node).length < 8) {
            const url = imageURL(image);
            if (url) { blocks.push({ type: 'image', url: url, alt: image.getAttribute('alt') || null, caption: null }); }
            return blocks;
          }

          const text = inlineRuns(node);
          if (!blockText(node)) { return blocks; }
          blocks.push({ type: 'paragraph', text: text });
          return blocks;
        }

        if (tag === 'figure') {
          const image = node.querySelector('img');
          const url = imageURL(image);
          if (url) {
            blocks.push({
              type: 'image',
              url: url,
              alt: image.getAttribute('alt') || null,
              caption: captionFor(node)
            });
          }
          return blocks;
        }

        if (tag === 'img') {
          const url = imageURL(node);
          if (url) { blocks.push({ type: 'image', url: url, alt: node.getAttribute('alt') || null, caption: null }); }
          return blocks;
        }

        if (tag === 'blockquote') {
          const text = inlineRuns(node);
          if (blockText(node)) { blocks.push({ type: 'quote', text: text }); }
          return blocks;
        }

        if (tag === 'ul') {
          const items = listItems(node);
          if (items.length) { blocks.push({ type: 'unorderedList', items: items }); }
          return blocks;
        }

        if (tag === 'ol') {
          const items = listItems(node);
          if (items.length) { blocks.push({ type: 'orderedList', items: items }); }
          return blocks;
        }

        if (tag === 'pre') {
          const codeNode = node.querySelector('code');
          const languageClass = codeNode ? Array.from(codeNode.classList).find(name => name.indexOf('language-') === 0) : null;
          const code = node.textContent || '';
          if (code.trim()) {
            blocks.push({
              type: 'code',
              language: languageClass ? languageClass.replace('language-', '') : null,
              code: code.replace(/^\\n+|\\n+$/g, '')
            });
          }
          return blocks;
        }

        if (tag === 'hr') {
          blocks.push({ type: 'divider' });
          return blocks;
        }

        if (tag === 'a' && blockText(node)) {
          const url = absoluteURL(node.getAttribute('href'));
          if (url) {
            blocks.push({ type: 'link', text: inlineRuns(node), url: url });
          }
          return blocks;
        }

        for (const child of Array.from(node.children)) {
          blocks.push.apply(blocks, blocksFromNode(child));
        }

        return blocks;
      }

      try {
        if (typeof Readability === 'undefined') {
          return JSON.stringify({ blocks: [] });
        }

        const article = new Readability(document.cloneNode(true), { charThreshold: 180 }).parse();
        if (!article || !article.content || !article.textContent || article.textContent.trim().length < 80) {
          return JSON.stringify({ blocks: [] });
        }

        const parser = new DOMParser();
        const articleDocument = parser.parseFromString(article.content, 'text/html');
        const articleBody = articleDocument.body;
        const blocks = [];

        for (const child of Array.from(articleBody.children)) {
          blocks.push.apply(blocks, blocksFromNode(child));
        }

        const firstImage = blocks.find(block => block.type === 'image');
        const heroImageURL =
          article.image ||
          pickMeta([
            'meta[property="og:image"]',
            'meta[name="twitter:image"]',
            'meta[property="twitter:image"]'
          ]) ||
          (firstImage ? firstImage.url : null);

        return JSON.stringify({
          title: article.title || document.title || null,
          byline: article.byline || pickMeta(['meta[name="author"]', 'meta[property="article:author"]']),
          siteName: article.siteName || pickMeta(['meta[property="og:site_name"]', 'meta[name="application-name"]']),
          excerpt: article.excerpt || pickMeta(['meta[name="description"]', 'meta[property="og:description"]']),
          sourceURL: location.href,
          heroImageURL: absoluteURL(heroImageURL),
          publishedTime: article.publishedTime || pickMeta([
            'meta[property="article:published_time"]',
            'meta[name="publishdate"]',
            'meta[name="pubdate"]',
            'meta[itemprop="datePublished"]',
            'time[datetime]'
          ]),
          language: article.lang || document.documentElement.lang || null,
          length: article.length || article.textContent.length,
          textContent: article.textContent,
          content: article.content,
          blocks: blocks
        });
      } catch (error) {
        return JSON.stringify({ blocks: [] });
      }
    })();
    """
}
