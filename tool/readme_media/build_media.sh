#!/usr/bin/env bash
# Rebuilds the README media in docs/media from the app's real rendered frames.
#
#   1. flutter test tool/readme_media/capture_test.dart   (with MEDIA_OUT set)
#   2. tool/readme_media/build_media.sh <MEDIA_OUT dir>
#
# Needs ffmpeg and ImageMagick (magick).
set -euo pipefail

SRC="${1:?usage: build_media.sh <capture output dir>}"
DEST="$(cd "$(dirname "$0")/../.." && pwd)/docs/media"
mkdir -p "$DEST"

# Animated clips: 20 fps frames -> small, looping GIFs with a shared palette.
gif() {
  local clip="$1" width="$2"
  ffmpeg -y -loglevel error -framerate 20 -i "$SRC/frames/$clip/%04d.png" \
    -vf "scale=${width}:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=96:stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
    -loop 0 "$DEST/$clip.gif"
}
for clip in carousel detail search favorites checkout; do gif "$clip" 270; done

# Stills for the screen gallery.
for name in shop detail cart checkout processing confirmation confirmation_confetti favorites orders; do
  magick "$SRC/stills/$name.png" -resize 300x -strip "$DEST/$name.png"
done

# One image showing every shoe's color theme side by side.
magick montage "$SRC"/stills/shoe_{1,2,3,4,5,6}.png \
  -resize 230x -geometry +10+10 -tile 6x1 -background none \
  -strip "$DEST/themes.png"

# Sample receipt: keep the PDF and a preview image of its first page.
if [ -f "$SRC/receipt.pdf" ]; then
  cp "$SRC/receipt.pdf" "$DEST/sample-receipt.pdf"
  if command -v pdftoppm >/dev/null; then
    pdftoppm -png -r 70 -f 1 -l 1 -singlefile "$SRC/receipt.pdf" "$DEST/receipt"
    magick "$DEST/receipt.png" -trim +repage -bordercolor white -border 8 -strip "$DEST/receipt.png"
  else
    echo "pdftoppm not found: skipped receipt.png" >&2
  fi
fi

ls -la "$DEST"
