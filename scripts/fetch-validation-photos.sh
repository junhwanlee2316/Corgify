#!/usr/bin/env bash
# Downloads public-domain portraits used to validate FaceAnalyzer.
# Usage: ./scripts/fetch-validation-photos.sh && swift run corgify-analyze .validation/*.jpg
set -euo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)/.validation"
mkdir -p "$DIR"
UA="CorgifyValidation/1.0 (https://github.com/junhwanlee2316/Corgify)"

fetch() {
  local title="$1" out="$2"
  local url
  url=$(curl -s -A "$UA" \
    "https://en.wikipedia.org/w/api.php?action=query&titles=File:${title}&prop=imageinfo&iiprop=url&iiurlwidth=500&format=json" \
    | python3 -c "import sys,json;p=list(json.load(sys.stdin)['query']['pages'].values())[0];print(p['imageinfo'][0]['thumburl'])")
  curl -s -A "$UA" -o "$DIR/$out" "$url"
  echo "  $out"
}

echo "Fetching validation photos into .validation/"
fetch "Albert_Einstein_Head.jpg" einstein.jpg
fetch "Marie_Curie_c._1920s.jpg" curie.jpg
fetch "Katherine_Johnson_1983.jpg" johnson.jpg
fetch "Alan_Turing_(1912-1954)_in_1936_at_Princeton_University.jpg" turing.jpg
echo "Done. Run: swift run corgify-analyze .validation/*.jpg"
