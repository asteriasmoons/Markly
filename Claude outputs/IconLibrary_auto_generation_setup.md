# Markly — Auto-Generating IconLibrary from Assets.xcassets

**Date:** 2026-11-17

This sets up `IconLibrary.swift` to be **generated at build time from the asset
catalog's folder structure**, so importing a new icon into a category folder
automatically adds it to the right category — no Swift editing.

---

## What changed (3 parts + backups)

### A. The asset catalog is now organized into category folders
Previously all 606 `*.imageset` assets lived at the root of `Assets.xcassets`
and the categorization lived only in `IconLibrary.swift`. I moved every imageset
into a **group folder named after its category** (the 20 categories from the
current library), e.g.:

```
Markly/Assets.xcassets/
├─ Bookmarks & Books/   (… .imageset)
├─ Rooms/
├─ Moon Phases/
│   ├─ fullmoon.imageset
│   └─ …
├─ UI/
├─ AppIcon.appiconset      (left at root — not an icon category)
├─ AccentColor.colorset    (left at root)
└─ Contents.json
```

**"Provides Namespace" is OFF on every folder.** This is the critical detail:
your code references icons by bare name (`Image("fullmoon")`) and your model
stores bare ids. Folders *without* namespace are purely organizational — the
runtime asset name stays `"fullmoon"`, so nothing breaks. Turning namespace ON
would rename the asset to `"Moon Phases/fullmoon"` and break every reference and
every saved icon id. Each group folder got a `Contents.json` with no
`provides-namespace` key (the default, = off).

The `.imageset` folder names themselves were **not changed**, so every existing
`Image(...)` call and every stored icon id still resolves exactly as before.

### B. A generator script
`Scripts/generate_icon_library.sh` walks the catalog and regenerates
`Markly/Utilities/IconLibrary.swift`:

- Each group folder → one `IconCategory`; each `*.imageset` inside → one `MarklyIcon`.
- Any imageset left at the catalog root → an `Unsorted` category (shown in the
  picker, so a new/unfiled icon is never invisible).
- Category order follows an explicit list in the script (your current order);
  unknown new folders are appended alphabetically; `Unsorted` then `UI` are
  forced last. `UI` stays excluded from the picker via the existing
  `pickerCategories` filter.
- Icons within a category are listed **alphabetically** (see caveat below).
- It is **idempotent**: it only rewrites the Swift file when the output actually
  changes, so unchanged builds trigger no recompile and no source-control churn.

It lives at the **repo root** (`Scripts/`), deliberately *outside* the
synchronized `Markly/` folder, so Xcode's synchronized-group feature doesn't
bundle it as a resource. The script is written for macOS's `/bin/bash` (3.2) and
uses `LC_ALL=C`, so its output is byte-identical on any machine.

A short `Scripts/README.md` documents it at the point of use.

### C. Wired into the Markly target as a build phase
I added a **Run Script build phase** named "Generate Icon Library" to the
`Markly` target, positioned **before Compile Sources**, so the Swift file is
regenerated before it compiles. The phase runs:

```
"${SRCROOT}/Scripts/generate_icon_library.sh"
```

with `alwaysOutOfDate = 1` (runs every build; the script's skip-if-unchanged
logic keeps it cheap). The `MarklyShare` target was **not** touched.

### Backups
Pre-change copies are in `.icon_migration_backup/` at the repo root:
- `IconLibrary.swift.prebak`
- `project.pbxproj.prebak`

Delete that folder whenever you're satisfied (it's outside the Xcode project).

---

## Your new workflow for icons
1. Drag a new `.imageset` into the desired **category folder** in
   `Assets.xcassets` (or create a new folder = a new category).
2. Build. The icon shows up in that category in the picker automatically.
3. To move an icon to a different category, drag its `.imageset` to another
   folder and build.

No more editing `IconLibrary.swift` by hand — it now carries a
`DO NOT EDIT BY HAND` header and is overwritten each build.

---

## Important notes & caveats
- **Open the project in Xcode once to confirm it loads and builds.** This
  environment is Linux with no Xcode/`plutil`, so I validated the `project.pbxproj`
  edit structurally (balanced braces/parens, the new phase referenced exactly
  once and defined once, `MarklyShare` untouched, tabs preserved) but could not
  have Xcode parse it. If anything is off, restore
  `.icon_migration_backup/project.pbxproj.prebak` over
  `Markly.xcodeproj/project.pbxproj`.
- **Intra-category order is now alphabetical**, where before it was hand-ordered.
  Functionally identical; only the on-screen order within a category changes
  (e.g. Moon Phases is now alphabetical, not orbital). If you want a specific
  order inside a category, that's the one thing folder-driven generation can't
  express on its own — tell me and I'll add a lightweight per-category order
  override to the script.
- **Keep "Provides Namespace" OFF.** Repeated because it's the one setting that
  would break everything.
- **New icon with no category folder** (dropped at the catalog root) lands in
  `Unsorted`, which *is* shown in the picker so you'll notice it and can file it.
- **Git** shows the reorg as many `delete`/`add` pairs (assets moved to new
  paths). That's expected; nothing was lost (verified: 606 imagesets, each with
  its `Contents.json` and payload intact). I did **not** commit anything.

---

## Verification performed
- Catalog: 606 imagesets, all exactly one level under a category folder, 0 left
  at root, 0 with `provides-namespace`, 0 missing `Contents.json` or payload.
- Generator: produces 606 `MarklyIcon` entries across 20 categories; re-running
  reports "already up to date" (idempotent); every asset is referenced and every
  reference has an asset (0 missing, 0 orphans); braces/parens/brackets balanced.
- Names unchanged, so existing `Image(...)` usages and stored ids still resolve.
- `project.pbxproj`: new phase is first in the Markly target's `buildPhases`
  (before `Sources`); `PBXShellScriptBuildPhase` section well-formed with tabs;
  new id present exactly twice; braces/parens balanced; `MarklyShare` unchanged.

---

## Files touched
- `Markly/Assets.xcassets/**` — imagesets moved into 20 category folders (+ group `Contents.json`s)
- `Markly/Utilities/IconLibrary.swift` — now generated
- `Scripts/generate_icon_library.sh` — new
- `Scripts/README.md` — new
- `Markly.xcodeproj/project.pbxproj` — added the Run Script build phase
- `.icon_migration_backup/` — pre-change backups
