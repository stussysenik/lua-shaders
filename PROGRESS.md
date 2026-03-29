# Progress

## Current State: v0.1 — Foundation

The engine is complete. Chapters 1-2 are written with full pedagogical patterns.
The presentation pipeline records and exports Instagram stories.

---

## What's Working

### Engine (complete)
- [x] Shader loader — read, compile, blank detection, hot-reload
- [x] Koan runner — learn mode with hints, solution view, navigation
- [x] Demo mode — browse all solutions with live animated visuals
- [x] Presenter — 9:16 canvas with timeline-driven text overlays
- [x] Recorder — fixed-timestep PNG frame capture
- [x] Exporter — ffmpeg GIF + MP4 (palette-optimized, IG-compatible)
- [x] Instagram theme — 1080x1920 layout config

### Content (2/7 chapters)
- [x] Chapter 1: Coordinates & UV Space (4 koans)
- [x] Chapter 2: Color Mixing & Palettes (4 koans)
- [ ] Chapter 3: Signed Distance Fields
- [ ] Chapter 4: Waves & Motion
- [ ] Chapter 5: Noise & Randomness
- [ ] Chapter 6: Fractals & Repetition
- [ ] Chapter 7: Raymarching & 3D

### Pedagogy
- [x] Curriculum design guide with 8 teaching patterns
- [x] X-ray vision framing in all lessons
- [x] Chained mental model references
- [x] Forward references ("unlocks...")
- [x] Minimum-viable-math hints
- [x] Chapter READMEs with GPU scale reasoning

---

## Commit History

| Date | Commit | What |
|------|--------|------|
| 2026-03-29 | `fe44ce9` | Design spec |
| 2026-03-29 | `67b682e` | Project scaffold + LOVE config |
| 2026-03-29 | `2e764e6` | Shader loader module |
| 2026-03-29 | `005f1aa` | First koan + curriculum index |
| 2026-03-29 | `2f645c6` | Instagram theme |
| 2026-03-29 | `ee1327b` | Presenter module |
| 2026-03-29 | `bdeb814` | Recorder module |
| 2026-03-29 | `67b08d8` | Exporter module |
| 2026-03-29 | `adc9fdb` | Lua 5.1 os.execute fix |
| 2026-03-29 | `fb58910` | Koan runner (learn mode) |
| 2026-03-29 | `8086bc8` | Chapter 1 koans (4) |
| 2026-03-29 | `40a84ab` | Chapter 2 koans (4) |
| 2026-03-29 | `2d058b7` | Curriculum design guide |
| 2026-03-29 | `507ca7b` | Pedagogical pattern upgrade |
| 2026-03-29 | `0c345d5` | Blank count detection fix |
| 2026-03-30 | `32b27cd` | Demo mode |

---

## Known Issues

- macOS Gatekeeper blocks LOVE on first run — requires manual approval
  (right-click -> Open in Finder, or System Settings -> Privacy & Security)
- Present mode (recording) is slow for large frame counts at 1080x1920
- No custom fonts yet — using LOVE default (Bitstream Vera Sans)
