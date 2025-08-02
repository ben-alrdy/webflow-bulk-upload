#!/usr/bin/env bash
# bulk-upload.sh   -- run inside the repo or give the path as $1
set -euo pipefail

SRC_DIR="${1:-$(pwd)}"               # default = current dir
LOGO_FOLDER="${2:-}"                  # folder containing logos
CSV_OUT="$SRC_DIR/logos.csv"

# Check if logo folder is provided
if [[ -z "$LOGO_FOLDER" ]]; then
    echo "❌  Please provide a folder name containing logos"
    echo "Usage: $0 [repo_path] <logo_folder_name>"
    exit 1
fi

# Check if logo folder exists
if [[ ! -d "$SRC_DIR/$LOGO_FOLDER" ]]; then
    echo "❌  Logo folder '$LOGO_FOLDER' not found in $SRC_DIR"
    exit 1
fi

# --- Identify the GitHub repo & active branch ---------------------------
REMOTE_URL=$(git -C "$SRC_DIR" remote get-url origin)
[[ $REMOTE_URL =~ github.com[:/]([^/]+)/([^/.]+) ]] \
  || { echo "❌  Can't parse GitHub remote"; exit 1; }
GH_USER="${BASH_REMATCH[1]}"
REPO="${BASH_REMATCH[2]}"
BRANCH=$(git -C "$SRC_DIR" symbolic-ref --quiet --short HEAD || echo main)

# --- Commit and push the logos -------------------------------------------------------
cd "$SRC_DIR"

echo "🚀  Committing and pushing logos to GitHub..."
git add "$LOGO_FOLDER"/
git commit -m "Add logos from $LOGO_FOLDER" || {
    echo "⚠️  No changes to commit (logos may already exist)"
}
git push origin "$BRANCH"

# --- Build CSV -----------------------------------------------------------
echo 'name,slug,alt text,image' > "$CSV_OUT"

shopt -s nullglob                 # skip loop when no matches
for file in "$LOGO_FOLDER"/*.{png,jpg,jpeg,svg,gif,webp}; do
  # Skip if no files found
  [[ -f "$file" ]] || continue
  
  filename=$(basename "$file")
  stem="${filename%.*}"
  name="$(tr '[:lower:]' '[:upper:]' <<<"${stem:0:1}")${stem:1}"  # Capitalise 1st
  slug="$(tr '[:upper:]' '[:lower:]' <<<"$stem" | tr ' ' '-')"  # lower-kebab
  alt="$name Logo"
  url="https://raw.githubusercontent.com/$GH_USER/$REPO/$BRANCH/$LOGO_FOLDER/$(printf '%s' "$filename" | sed 's/ /%20/g')"
  printf '"%s","%s","%s","%s"\n' "$name" "$slug" "$alt" "$url" >> "$CSV_OUT"
done

echo "✅  Updated $CSV_OUT and pushed images to $GH_USER/$REPO ($BRANCH)"