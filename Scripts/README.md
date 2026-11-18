# Scripts/generate_icon_library.sh

Regenerates `Markly/Utilities/IconLibrary.swift` from the **folder structure** of
`Markly/Assets.xcassets`.

## How it works
- Each **group folder** inside the asset catalog becomes one `IconCategory`.
- Every `*.imageset` inside that folder becomes a `MarklyIcon`.
- Imagesets left at the catalog **root** are collected into an `Unsorted`
  category (so newly imported icons are never silently missing).
- Category order follows the `ORDER` list in the script; unknown folders are
  appended alphabetically; `Unsorted` then `UI` are forced last.
- Icons within a category are listed alphabetically.

## It runs automatically
It is wired into the **Markly** target as a Run Script build phase named
"Generate Icon Library", positioned **before Compile Sources**, so the Swift
file is always current at build time. The script only rewrites the file when the
output actually changes, so unchanged builds cause no recompile.

## Adding / re-categorizing icons
1. In Xcode, drag the new `.imageset` into the desired **category folder** inside
   `Assets.xcassets` (or make a new folder = a new category).
2. Build. The icon appears in that category automatically.

## Critical rule
Leave **"Provides Namespace" OFF** on every group folder. The app references
icons by bare name (`Image("fullmoon")`), and enabling namespace would rename
assets to `Category/fullmoon` and break every reference and every saved icon id.

## Do not hand-edit IconLibrary.swift
It is overwritten on each build. Change icons by moving assets between folders.
