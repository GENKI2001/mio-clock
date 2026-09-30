#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
source_icon="$project_dir/branding/app_icon.png"
icon_dir="$project_dir/ios/Runner/Assets.xcassets/AppIcon.appiconset"

while IFS=$'\t' read -r filename pixels; do
  sips -s format png -z "$pixels" "$pixels" "$source_icon" \
    --out "$icon_dir/$filename" >/dev/null
done < <(
  jq -r '.images[] |
    [.filename,
      ((.size | split("x")[0] | tonumber) *
       (.scale | rtrimstr("x") | tonumber) | floor)
    ] | @tsv' "$icon_dir/Contents.json"
)

for pixels in 192 512; do
  sips -s format png -z "$pixels" "$pixels" "$source_icon" \
    --out "$project_dir/web/icons/Icon-$pixels.png" >/dev/null
  sips -s format png -z "$pixels" "$pixels" "$source_icon" \
    --out "$project_dir/web/icons/Icon-maskable-$pixels.png" >/dev/null
done
sips -s format png -z 32 32 "$source_icon" \
  --out "$project_dir/web/favicon.png" >/dev/null

launch_dir="$project_dir/ios/Runner/Assets.xcassets/LaunchImage.imageset"
for scale in 1 2 3; do
  pixels=$((120 * scale))
  if [ "$scale" -eq 1 ]; then
    suffix=""
  else
    suffix="@$scale""x"
  fi
  sips -s format png -z "$pixels" "$pixels" "$source_icon" \
    --out "$launch_dir/LaunchImage$suffix.png" >/dev/null
done

printf 'Updated iOS icon sizes from %s\n' "$source_icon"
