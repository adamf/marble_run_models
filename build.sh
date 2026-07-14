#!/usr/bin/env bash
# Render every print-ready model from the parametric source into the
# repo's tracked folders (stl/, images/). Run locally OR in CI; either way
# the committed models stay in sync with src/.
set -euo pipefail

SCAD="src/marble_run_baseplate.scad"
mkdir -p stl images

echo ">> 6x6 tile"
openscad -o stl/marble_run_baseplate_6x6.stl   -D 'PART="tile"'        "$SCAD"
echo ">> calibration strip"
openscad -o stl/marble_run_calibration.stl     -D 'PART="calibration"' "$SCAD"

# Preview renders keep the README images current (needs a virtual display).
if command -v xvfb-run >/dev/null 2>&1; then
  echo ">> previews"
  xvfb-run -a openscad -o images/baseplate.png   -D 'PART="tile"' \
    --autocenter --viewall --camera=0,0,0,55,0,25,0 --imgsize=1000,760 "$SCAD" || true
  xvfb-run -a openscad -o images/calibration.png -D 'PART="calibration"' \
    --autocenter --viewall --camera=0,0,0,58,0,20,0 --imgsize=1100,420 "$SCAD" || true
fi

echo ">> done"; ls -la stl images
