#!/usr/bin/env bash
# Build an Expo / React Native app prepared by pods/prepare.sh, for an arm64 iPhone, with sweetpad.
#   pods/build.sh <app-dir> [Release|Debug] [extra xcodebuild-style settings...]
# Unsigned by default (CODE_SIGNING_ALLOWED=NO); pass CODE_SIGNING_ALLOWED=YES with sweetpad's
# signing variables set to sign. The app lands under $DERIVED_DATA (default <app>/ios/build/dd).
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
app=$(cd "${1:?usage: build.sh <app-dir> [configuration] [settings...]}" && pwd)
config=${2:-Release}
shift $(( $# > 1 ? 2 : 1 ))
export PATH="$here/bin:$PATH"
command -v sweetpad >/dev/null || { echo "build: sweetpad not on PATH" >&2; exit 1; }

workspace=$(ls -d "$app"/ios/*.xcworkspace | head -n1)
scheme=$(basename "$workspace" .xcworkspace)
nm=$(cd "$app" && node -p "require('path').resolve(require.resolve('react-native/package.json'),'../..')")
hermesc=$nm/hermes-compiler/hermesc/linux64-bin/hermesc
derived=${DERIVED_DATA:-$app/ios/build/dd}

cd "$app"
exec sweetpad build --workspace "$workspace" --scheme "$scheme" --configuration "$config" \
	--destination generic/platform=iOS --non-interactive \
	-- -derivedDataPath "$derived" ARCHS=arm64 CODE_SIGNING_ALLOWED=NO HERMES_CLI_PATH="$hermesc" "$@"
