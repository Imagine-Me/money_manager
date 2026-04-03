#!/usr/bin/env bash
# Build signed release AAB for Play Store
# --no-tree-shake-icons is required because CategoryEntity reconstructs
# IconData at runtime from stored code points (legitimate DB-backed usage).
set -e
flutter build appbundle --release --no-tree-shake-icons "$@"
echo ""
echo "AAB: build/app/outputs/bundle/release/app-release.aab"
