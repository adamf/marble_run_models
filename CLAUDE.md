# marble_run_models — context for Claude Code

Parametric, 3D-printable models for a National Geographic (translucent OEM)
marble run. Primary model: a tileable **base plate** that gives marble-run
stacks a stable footing.

## Repo layout
```
src/    marble_run_baseplate.scad   # parametric source — edit this
stl/    *.stl                       # rendered, print-ready (CI regenerates)
images/ *.png                       # preview + connection renders
build.sh                            # renders everything from src/
.github/workflows/build.yml         # CI: re-render + commit STLs on push
```

## Build
`./build.sh` renders the STLs into `stl/` and previews into `images/`.
Requires OpenSCAD on PATH.
> On Apple Silicon use the **snapshot / native** OpenSCAD build — the
> Homebrew `openscad` cask is the deprecated 2021.01 Intel build and needs
> Rosetta. Get it via `brew install --cask openscad@snapshot` or the
> Universal dmg from openscad.org.

Single part manually:
`openscad -o out.stl -D 'PART="tile"' src/marble_run_baseplate.scad`
(`PART` = `"tile"` or `"calibration"`).

## CI
`build.yml` triggers on pushes touching `src/**`, `build.sh`, or the
workflow itself. It installs OpenSCAD, runs `build.sh`, uploads the STLs as
artifacts, and commits the refreshed `stl/` + `images/` back with
`[skip ci]` so it doesn't loop. Editing a parameter and pushing is enough to
get a fresh print-ready STL in the repo.

## Design rationale (don't break these invariants)
- **Pegs plug INTO the tubes' female (cup) socket**, the same way the tubes'
  own male spigots plug together. `peg_od` = socket inner diameter minus a
  snug clearance. Pegs are hollow (`peg_wall`) so they flex and grip.
- **Grid continuity:** footprint = `grid * pitch`, so pegs sit `pitch/2`
  from every edge and the grid stays continuous across tiled seams. Keep
  this relationship if changing sizing.
- **Tile connectors (jigsaw):** male tabs on the +X/+Y edges, female sockets
  on the −X/−Y edges. Sockets must carve **inward**: `rotate([0,0,-90])` on
  the −X edge and no rotation on the −Y edge. (A bug had them cutting
  outward into empty space — only male tabs, no pockets.)
- **Peg/connector collisions** are avoided by auto-omitting the edge peg at
  any cell that hosts a connector (`conn_cells`). Don't place connectors at
  cells that keep their peg.
- Key params: `peg_od`, `pitch`, `grid_x`/`grid_y`, `peg_h`, `tab_tol`.

## Calibration (measured on the user's Bambu)
- **`peg_od = 23.9`** — firm/snug fit, shaved from 24.0 for a little more
  give on/off. `23.5` is a looser fallback. This number bakes in the user's
  printer tolerance; trust it over generic values.
- **`pitch = 30`, grid `6×6`** → 180×180mm tile, 36 pegs. Pitch is HALF
  the span/ramp module (~60mm foot-to-foot), so a span sits with its feet
  on pegs 2 apart. Grid continuity means the same 60mm span also fits
  across tile seams: A's last peg sits 15mm from the seam and B's first
  peg 15mm past it, distance 60mm. Don't shrink pitch below 30mm — pegs
  (~Ø24) would collide with each other.
- **Internal-only flare, no outer lip.** Earlier revisions flared each
  peg's base outward (`peg_skirt`) for strength; the user pulled that
  reinforcement inside so the outer diameter stays flat and tube feet seat
  flush. The bore is closed (r=0) at the underside and tapers out to the
  nominal bore radius over `peg_flare_h` (2mm), then goes straight. Wall
  is thickest at the base = strongest where the peg meets the plate.
- `tab_tol` (default 0.40) tunes the plate-to-plate joint: raise toward 0.6
  if tiles are too stiff to press together, lower toward 0.25 if loose.

## Print settings (Bambu)
Flat, pegs up, **no supports**. 0.2mm layers, 3–4 walls, 15–20% infill,
5mm brim to stop corner lift. PLA works; PETG is tougher and snaps nicer.
Printer is a Bambu (user called it "x2d"; most likely an H2D — its larger
bed allows bigger single tiles, e.g. `grid_x`/`grid_y` = 8).

## Current state / next steps
The intended-correct `src` has: sockets cutting **inward** (connector fix)
and **`peg_od = 24.0`**. Verify both are present; if the socket lines still
read `rotate([0,0,90])` / `rotate([0,0,180])`, apply the fix. Then
`./build.sh`, commit, push (CI regenerates STLs).

Open ideas the user may pick up:
- A fine calibration strip, pegs 23.0–24.0 in 0.25 steps, to pin the exact
  fit below the current 0.5 granularity.
- A larger single tile (8×8) sized for the H2D bed.
- An **inverted "socket plate"** variant — holes instead of pegs — for any
  pieces that present a *male stub* on the bottom rather than a female cup.
