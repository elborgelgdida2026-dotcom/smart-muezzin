# Fonts — الخطوط

Bundled fonts, declared in `pubspec.yaml` under `flutter/fonts`.
All are licensed under the SIL Open Font License (OFL) and were
downloaded from the official Google Fonts repository — no font file
was fabricated or modified.

## Files

| File | Family / Weight | Source | Size |
|---|---|---|---|
| `Cairo-Variable.ttf` | Cairo, variable weight 200–1000 (declared as 400 Regular and 700 Bold) | https://github.com/google/fonts/raw/main/ofl/cairo/Cairo%5Bslnt%2Cwght%5D.ttf (official google/fonts repo; Cairo is distributed only as a variable font there — no static Regular/Bold TTF exists in that repo) | 599,548 bytes |
| `Amiri-Regular.ttf` | Amiri, Regular 400 | https://github.com/google/fonts/raw/main/ofl/amiri/Amiri-Regular.ttf | 431,116 bytes |
| `Amiri-Bold.ttf` | Amiri, Bold 700 | https://github.com/google/fonts/raw/main/ofl/amiri/Amiri-Bold.ttf | 413,480 bytes |

## Verification

Each file was verified on 2026-11-26 as a valid TrueType font
(magic bytes `00 01 00 00`, parsed table directory):
- `Cairo-Variable.ttf` — 21 tables, contains an `fvar` table
  (variable font, weights 200–1000, slant axis).
- `Amiri-Regular.ttf` — 15 tables, static.
- `Amiri-Bold.ttf` — 15 tables, static.

## Notes

- Cairo is used as the app's UI font (`fontFamily: 'Cairo'`),
  Amiri for Quranic / devotional text (`fontFamily: 'Amiri'`).
- If the fonts are removed, the app falls back to the system font;
  nothing else breaks.
- Tajawal is **not** bundled (the original spec mentioned it as an
  option); Cairo covers the UI and Amiri the Quranic text.
- The OFL licence texts live in the upstream repos
  (`ofl/cairo/OFL.txt`, `ofl/amiri/OFL.txt` in google/fonts).
