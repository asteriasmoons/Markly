# Agent Prompt — Make `IconLibrary.swift` auto-generate from `Assets.xcassets`

Paste everything below this line into the agent working in the target iOS project.
Fill in nothing yourself — the agent discovers project specifics on its own.

---

## Your task

Set up this iOS/SwiftUI project so that its icon library Swift file is **generated
automatically at build time from the asset catalog's folder structure**. After
this, importing a new icon into a category folder in `Assets.xcassets` makes it
appear in the right category with no Swift editing.

There are four pieces of work:
1. Reorganize `Assets.xcassets` so each **category is a group folder**.
2. Add a **generator script** that rebuilds the icon-library Swift file from those folders.
3. **Wire the script into the app target** as a Run Script build phase that runs
   before "Compile Sources".
4. **Disable "User Script Sandboxing"** so the script phase can read/write files.

Then verify by building.

## House rules (follow exactly — these are the project owner's standing rules)

- **Study the project before changing anything.** Read the existing icon-library
  file, the icon picker, the asset catalog, and the `.xcodeproj` before editing.
- **Do not redesign or expand scope.** Preserve the existing public API, type
  names, naming conventions, and architecture. Match existing patterns. Only make
  the changes this task describes.
- **Custom assets only. Never introduce SF Symbols** (`Image(systemName:)`), system
  images, or placeholder art.
- **Do not make avoidable assumptions.** Inspect the codebase to answer questions.
  Only ask the owner when something genuinely cannot be determined from the project
  (e.g. how to categorize icons when no existing categorization exists).
- **Never use `@AppStorage`.**
- **Document everything.** When done, write a Markdown doc that explains, for each
  change: the prior behavior, the cause/need, exactly what you changed and why, and
  the expected outcome. **Send that doc to the owner in the chat** so it can be
  downloaded on mobile.
- Make **backups** of every file you edit before editing it, and **do not commit**
  to git unless explicitly asked.

---

## Step 0 — Discover (do this first, record what you find)

Determine and write down:

1. **The asset catalog path(s).** Usually `<AppName>/Assets.xcassets`. There may be
   more than one catalog (e.g. a share/widget extension has its own). Only operate
   on the catalog used by the icon library you're generating. Note extension
   catalogs but leave them alone unless told otherwise.
2. **The icon-library Swift file** — the file that currently lists the pickable
   icons (in Markly it was `<AppName>/Utilities/IconLibrary.swift`). Identify:
   - the item type (e.g. `struct MarklyIcon`), the category type (e.g.
     `struct IconCategory`), the container (e.g. `enum IconLibrary`),
   - the array that holds the categories (e.g. `static let categories`),
   - any computed properties (e.g. `pickerCategories`, `all`, `pickerIcons`) and
     **which category name is excluded from the picker** (e.g. `name != "UI"`),
   - the exact current **category order** and the ids in each (you'll reuse the order).
3. **How icons are referenced in code** — confirm the app loads them by **bare asset
   name** (e.g. `Image("couch")` / `UIImage(named: "couch")`) and that stored model
   values are bare ids. This is critical for the namespace rule in Step 1. Grep for
   `Image(` and the item type to confirm.
4. **Project format.** Open `<App>.xcodeproj/project.pbxproj` and check
   `objectVersion`. If it uses `fileSystemSynchronizedGroups` (Xcode 16+/objectVersion
   ≥ 70-ish), sources are auto-synced from the folder — meaning the generated Swift
   file is picked up automatically, **and any script you add inside the synced app
   folder would be bundled as a resource.** So put scripts OUTSIDE the synced app
   folder (at repo root). If it's a legacy project with explicit file references,
   the generated file is already a member (you're overwriting it in place), and a
   script placed anywhere non-synced is fine.
5. **The app target name** and its `buildConfigurationList`, plus the **Sources**
   build-phase id for that target.

If the project has **no existing icon-library file or no categorization**, stop and
ask the owner how they want icons categorized before proceeding (don't invent a
scheme silently).

---

## Step 1 — Back up, then reorganize the catalog into category folders

1. Back up the icon-library Swift file and `project.pbxproj` to a repo-root folder
   like `.icon_migration_backup/`.
2. For **each category** in the existing library, create a group folder inside the
   asset catalog whose **name is exactly the category display name** (spaces and `&`
   are fine), and give it a `Contents.json`:
   ```json
   { "info" : { "author" : "xcode", "version" : 1 } }
   ```
   **Do NOT add `"provides-namespace": true`.** (Its absence = namespace OFF.)
3. **Move each `<id>.imageset` directory** from the catalog root into its category
   folder (a directory rename — contents move with it). Leave `AppIcon.appiconset`,
   `AccentColor.colorset`, any `*.colorset`/`*.symbolset`, and the catalog's top-level
   `Contents.json` at the root.

> **CRITICAL — namespace must stay OFF.** The app references icons by bare name.
> Group folders *without* "Provides Namespace" are purely organizational: the runtime
> asset name stays `"couch"`, nothing breaks. If namespace were ON, the name would
> become `"Rooms/couch"` and every `Image(...)` call and every saved icon id would
> break. Never enable it.

**Verify after moving:** every imageset is now exactly one level under a category
folder; zero imagesets remain at the catalog root; the total imageset count is
unchanged; no folder contains `provides-namespace`; every imageset still has its
`Contents.json` and its image payload.

---

## Step 2 — Add the generator script

Create `Scripts/generate_icon_library.sh` at the **repo root** (outside the synced
app folder). Use the reference implementation below. **Customize three things** to
this project:
- `CAT` and `OUT` default paths (catalog path and icon-library file path),
- the `ORDER=( … )` list (the project's existing category order; the excluded
  picker category — e.g. `UI` — stays in this list and is forced last by the script),
- the `HEADER` and `FOOTER` heredocs: paste the **exact** top matter (file comment,
  imports, the item/category/container type definitions) and the **exact** computed-
  property footer (including the project's own picker-exclusion filter) from the
  existing library file, so the generated file is a byte-compatible drop-in. Only the
  `categories` array between HEADER and FOOTER is produced by the loop.

Reference implementation (from a project whose types were `MarklyIcon` /
`IconCategory` / `IconLibrary`, picker excludes `"UI"`):

```bash
#!/bin/bash
# Regenerates the icon-library Swift file from the folder structure of the asset
# catalog. Each group folder (namespace OFF) -> one category; each *.imageset -> one
# icon. Imagesets at the catalog root land in an "Unsorted" category. Idempotent:
# only rewrites the Swift file when the output changes. Written for macOS /bin/bash
# (3.2); LC_ALL=C keeps output byte-identical across machines.
set -euo pipefail
export LC_ALL=C

SRCROOT="${SRCROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
CAT="${1:-$SRCROOT/<AppName>/Assets.xcassets}"                    # <-- customize
OUT="${2:-$SRCROOT/<AppName>/Utilities/IconLibrary.swift}"        # <-- customize
[ -d "$CAT" ] || { echo "error: catalog not found at $CAT" >&2; exit 1; }

ORDER=(                                                           # <-- customize order
  "Bookmarks & Books" "Rooms" "Cleaning" "..." "Misc"
)   # include the picker-excluded category name (e.g. "UI") somewhere in ORDER;
    # the script forces it last regardless.

EXCLUDED_LAST="UI"   # <-- the category your picker excludes; forced last.

MAP="$(mktemp)"; TMPOUT="$(mktemp)"
trap 'rm -f "$MAP" "$TMPOUT" 2>/dev/null || true' EXIT

while IFS= read -r iset; do
  parent="$(dirname "$iset")"; base="$(basename "$iset")"; id="${base%.imageset}"
  if [ "$parent" = "$CAT" ]; then c="Unsorted"; else c="$(basename "$parent")"; fi
  printf '%s\t%s\n' "$c" "$id"
done < <(find "$CAT" -type d -name '*.imageset' | sort) > "$MAP"

PRESENT=(); while IFS= read -r l; do PRESENT+=("$l"); done < <(cut -f1 "$MAP" | sort -u)
contains(){ local n="$1"; shift; local x; for x in "$@"; do [ "$x" = "$n" ] && return 0; done; return 1; }

FINAL=()
for c in "${ORDER[@]}"; do [ "$c" = "$EXCLUDED_LAST" ] && continue
  contains "$c" "${PRESENT[@]}" && FINAL+=("$c"); done
for c in "${PRESENT[@]}"; do case "$c" in "$EXCLUDED_LAST"|"Unsorted") continue;; esac
  contains "$c" "${ORDER[@]}" || FINAL+=("$c"); done
contains "Unsorted" "${PRESENT[@]}" && FINAL+=("Unsorted")
contains "$EXCLUDED_LAST" "${PRESENT[@]}" && FINAL+=("$EXCLUDED_LAST")

emit_category(){ local name="$1" ids=() id np maxlen=0 pad
  while IFS= read -r id; do ids+=("$id"); done < <(awk -F'\t' -v c="$name" '$1==c{print $2}' "$MAP" | sort)
  for id in "${ids[@]}"; do np="MarklyIcon(\"$id\","; [ ${#np} -gt $maxlen ] && maxlen=${#np}; done
  printf '        IconCategory(name: "%s", icons: [\n' "$name"
  for id in "${ids[@]}"; do np="MarklyIcon(\"$id\","; pad=$(( maxlen - ${#np} + 1 ))
    printf '            %s%*scustom: true),\n' "$np" "$pad" ""; done
  printf '        ]),\n'; }

{
cat <<'HEADER'
<<< PASTE the existing file's exact top matter here, ending with:
enum IconLibrary {
    static let categories: [IconCategory] = [
HEADER
for c in "${FINAL[@]}"; do printf '\n'; emit_category "$c"; done
cat <<'FOOTER'
    ]
<<< PASTE the existing file's exact computed-property footer here, e.g.:
    static let pickerCategories: [IconCategory] = categories.filter { $0.name != "UI" }
    static let all: [MarklyIcon] = categories.flatMap { $0.icons }
    static let pickerIcons: [MarklyIcon] = pickerCategories.flatMap { $0.icons }
}
FOOTER
} > "$TMPOUT"

if [ -f "$OUT" ] && cmp -s "$TMPOUT" "$OUT"; then echo "icon library already up to date."
else cp "$TMPOUT" "$OUT"; echo "icon library regenerated ($(grep -c 'MarklyIcon(' "$OUT") icons, ${#FINAL[@]} categories)."; fi
```

Notes:
- If the project's item type isn't `MarklyIcon(...)` or its initializer differs,
  change the two `MarklyIcon("$id",` / `custom: true),` lines in `emit_category`
  (and the `maxlen` calc) to match the project's exact per-icon syntax.
- `bash -n Scripts/generate_icon_library.sh` to syntax-check. Keep it bash-3.2
  compatible (no `mapfile`/`readarray`, no `declare -A`).
- Add a short `Scripts/README.md` explaining the script and the namespace-OFF rule.

---

## Step 3 — Regenerate and validate the Swift file

Run `bash Scripts/generate_icon_library.sh` once. Then verify:
- Every asset in the catalog is referenced exactly once; every referenced id has a
  matching imageset; zero missing, zero orphans.
- The icon count equals the catalog imageset count.
- The generated file's types/computed-properties match the original (diff against the
  backup — the only intended differences are the new "auto-generated" header and that
  **icons within a category are now alphabetical**).
- Braces/parens/brackets balance.
- Running the script a second time prints "already up to date" (idempotent).

If the owner cares about a specific order *within* a category (folder-driven
generation is alphabetical by default), tell them; optionally add a per-category
order override file the script reads.

---

## Step 4 — Wire the script into the app target (Run Script build phase)

Edit `project.pbxproj` **surgically** (back it up first). Do **not** use the
`xcodeproj` Ruby gem on a modern project (objectVersion ≥ 70-ish): it rewrites the
whole file on save and can drop keys it doesn't understand. Hand-edit instead.

1. Generate a new unique 24-hex-uppercase id (not already present in the file).
2. In the **app target's** `buildPhases = ( … );`, insert the new phase **as the
   first entry, before the `Sources` phase**:
   ```
   <NEWID> /* Generate Icon Library */,
   ```
   (Use tabs, matching the file. Make sure you edit the correct target's
   `buildPhases` — disambiguate by a phase unique to that target.)
3. Add a `PBXShellScriptBuildPhase` section (place it just before
   `/* Begin PBXSourcesBuildPhase section */`). Use tabs:
   ```
   /* Begin PBXShellScriptBuildPhase section */
   		<NEWID> /* Generate Icon Library */ = {
   			isa = PBXShellScriptBuildPhase;
   			alwaysOutOfDate = 1;
   			buildActionMask = 2147483647;
   			files = (
   			);
   			inputFileListPaths = (
   			);
   			inputPaths = (
   			);
   			name = "Generate Icon Library";
   			outputFileListPaths = (
   			);
   			outputPaths = (
   			);
   			runOnlyForDeploymentPostprocessing = 0;
   			shellPath = /bin/bash;
   			shellScript = "\"${SRCROOT}/Scripts/generate_icon_library.sh\"\n";
   		};
   /* End PBXShellScriptBuildPhase section */
   ```
   `alwaysOutOfDate = 1` makes it run every build (cheap, because the script skips
   writing when unchanged) and suppresses the "no outputs" warning.
4. Verify: the new id appears exactly twice (once in `buildPhases`, once as the
   section definition); it's the first phase, before `Sources`; other targets are
   untouched; braces/parens still balance.

**Safer manual fallback (for the owner, if the agent can't edit pbxproj reliably):**
In Xcode → select the app target → Build Phases → `+` → New Run Script Phase → set
the script to `"${SRCROOT}/Scripts/generate_icon_library.sh"` → drag the phase
**above "Compile Sources"** → uncheck "Based on dependency analysis".

---

## Step 5 — Disable User Script Sandboxing

New Xcode projects default to `ENABLE_USER_SCRIPT_SANDBOXING = YES`, which sandboxes
Run Script phases and will deny the script access (symptom: a build error like
`Sandbox: bash(…) deny(1) file-read-data …/generate_icon_library.sh`).

Set it to **NO**:
- Search `project.pbxproj` for `ENABLE_USER_SCRIPT_SANDBOXING`.
  - If present as `= YES`, flip the occurrences for the app's build configs (project-
    level or target-level) to `= NO`.
  - If **absent**, it's relying on the YES default — add
    `ENABLE_USER_SCRIPT_SANDBOXING = NO;` to the app target's Debug and Release
    `XCBuildConfiguration` `buildSettings` (or the project-level configs).
- Equivalent in Xcode UI: target/project → Build Settings → search "User Script
  Sandboxing" → set to **No**.

This only relaxes a **build-time** restriction on scripts on the developer machine.
It does **not** affect the shipped app, its runtime/App Sandbox, or App Store review.

---

## Step 6 — Build to verify

Build the app target (Xcode, or `xcodebuild -scheme <Scheme> -destination
'generic/platform=iOS' build` if available). Confirm:
- the build succeeds,
- the "Generate Icon Library" phase ran and the Swift file compiles,
- the icon picker still shows all icons in their categories,
- icons render (names unchanged, so existing `Image(...)` calls resolve).

If the build fails, read the error; if it's the pbxproj edit, restore the backup and
either retry carefully or use the Xcode-UI fallback in Step 4.

---

## Step 7 — Document and report

Write a Markdown doc covering: the catalog reorg (and the namespace-OFF rule), the
generator script (location + behavior + determinism + idempotency + ordering), the
build-phase wiring, the sandbox change, the owner's new workflow for adding/
re-categorizing icons, caveats, backup locations, and the verification you performed.
**Send that doc to the owner in the chat.** Do not commit to git.

## Edge cases / gotchas to handle
- **Multiple asset catalogs** (app + extensions): only generate from the one tied to
  the icon library. Don't touch extension catalogs unless asked.
- **Different type names / initializer**: mirror the existing project's exact syntax
  in the script; never impose names from the reference implementation.
- **Non-template / multicolor images** in the catalog: generation includes them like
  any imageset; if the picker tints with `.renderingMode(.template)` they'll render as
  tinted silhouettes — that's existing behavior, don't change it.
- **Name collisions**: asset names must stay globally unique across the catalog even
  when foldered (namespace OFF). If two imagesets share a name, flag it — don't rename
  silently.
- **Synchronized folder groups**: keep the script OUTSIDE the synced app folder so it
  isn't bundled; the generated Swift file stays INSIDE (it's a source).
- **No Xcode available to the agent**: validate pbxproj structurally (balanced
  braces/parens, new id referenced once + defined once, correct tabs, other targets
  untouched) and tell the owner to open Xcode once to confirm it loads and builds;
  keep the backup for rollback.
```
