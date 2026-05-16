#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT/alfakhir_desktop"

flutter pub get

case "$(uname -s)" in
  Linux)
    flutter run -d linux
    ;;
  Darwin)
    flutter run -d macos
    ;;
  *)
    flutter run -d windows
    ;;
esac
