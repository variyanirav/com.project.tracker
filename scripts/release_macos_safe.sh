#!/usr/bin/env bash
set -euo pipefail

# Safe macOS release script for Project Tracker.
# What it does:
# 1) Backs up SQLite DB (time_tracker.db) if found
# 2) Runs focused regression tests
# 3) Builds macOS release app
# 4) Replaces Desktop app with rollback backup

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
DESKTOP_DIR="$HOME/Desktop"
BACKUP_DIR="$DESKTOP_DIR/project_tracker_release_backups"
DB_BACKUP_DIR="$BACKUP_DIR/db"
APP_BACKUP_DIR="$BACKUP_DIR/app"
TARGET_APP_PATH="$DESKTOP_DIR/project_tracker.app"

mkdir -p "$DB_BACKUP_DIR" "$APP_BACKUP_DIR"

echo "[1/4] Looking for existing database files..."
DB_FILES=()
while IFS= read -r db_path; do
  [[ -z "$db_path" ]] && continue
  DB_FILES+=("$db_path")
done < <(
  find "$HOME/Library" \
    \( -path '*/Containers/*' -o -path '*/Application Support/*' \) \
    -name 'time_tracker.db' 2>/dev/null || true
)

if [[ ${#DB_FILES[@]} -eq 0 ]]; then
  echo "No existing time_tracker.db found. Continuing..."
else
  for db in "${DB_FILES[@]}"; do
    base_name="$(basename "$(dirname "$db")")"
    cp "$db" "$DB_BACKUP_DIR/time_tracker_${base_name}_${TIMESTAMP}.db"
    echo "Backed up DB: $db"
  done
fi

echo "[2/4] Running focused tests..."
cd "$WORKSPACE_DIR"
flutter test test/providers/reports_provider_test.dart test/screens/reports_screen_test.dart

echo "[3/4] Building macOS release..."
flutter clean
flutter pub get
flutter build macos --release

RELEASE_DIR="$WORKSPACE_DIR/build/macos/Build/Products/Release"
BUILT_APPS=()
while IFS= read -r app_path; do
  [[ -z "$app_path" ]] && continue
  BUILT_APPS+=("$app_path")
done < <(find "$RELEASE_DIR" -maxdepth 1 -type d -name '*.app' | sort)

if [[ ${#BUILT_APPS[@]} -eq 0 ]]; then
  echo "ERROR: No .app found in $RELEASE_DIR"
  exit 1
fi

BUILT_APP_PATH="${BUILT_APPS[0]}"

echo "[4/4] Replacing Desktop app safely..."
if [[ -d "$TARGET_APP_PATH" ]]; then
  mv "$TARGET_APP_PATH" "$APP_BACKUP_DIR/project_tracker_${TIMESTAMP}.app"
  echo "Existing Desktop app moved to backup: $APP_BACKUP_DIR/project_tracker_${TIMESTAMP}.app"
fi

cp -R "$BUILT_APP_PATH" "$TARGET_APP_PATH"

echo "Done."
echo "New app: $TARGET_APP_PATH"
echo "DB backups: $DB_BACKUP_DIR"
echo "App backups: $APP_BACKUP_DIR"
