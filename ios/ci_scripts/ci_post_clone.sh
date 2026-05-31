#!/bin/zsh
set -euo pipefail

echo "Preparing Flutter for Xcode Cloud"

SCRIPT_DIR="${0:A:h}"
IOS_DIR="${SCRIPT_DIR:h}"
REPO_ROOT="${IOS_DIR:h}"

export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"

if [[ -d "$FLUTTER_HOME/.git" ]]; then
  echo "Updating Flutter $FLUTTER_VERSION"
  git -C "$FLUTTER_HOME" fetch --depth 1 origin "$FLUTTER_VERSION"
  git -C "$FLUTTER_HOME" checkout --force FETCH_HEAD
elif [[ ! -x "$FLUTTER_HOME/bin/flutter" ]]; then
  echo "Installing Flutter $FLUTTER_VERSION"
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"

flutter config --no-analytics
flutter --version
flutter precache --ios
xattr -cr "$FLUTTER_HOME/bin/cache/artifacts/engine/ios" 2>/dev/null || true
xattr -cr "$FLUTTER_HOME/bin/cache/artifacts/engine/ios-release" 2>/dev/null || true

cd "$REPO_ROOT"
flutter pub get

cd "$IOS_DIR"
if ! command -v pod >/dev/null 2>&1; then
  echo "Installing CocoaPods"
  gem install cocoapods --user-install --no-document
  export PATH="$HOME/.gem/ruby/$(ruby -e 'print RUBY_VERSION[/\d+\.\d+/]')/bin:$PATH"
fi

pod install
