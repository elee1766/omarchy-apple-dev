#!/usr/bin/env bash
# Prepare an Expo / React Native app's iOS workspace for a Linux build with sweetpad (Swift Build).
#   pods/prepare.sh <app-dir>
# app-dir holds package.json and app.config.*; node_modules must be installed. ios/ is regenerated.
# Needs: sweetpad setup done (Swift + Darwin SDK), CocoaPods, rsync, and bsdtar as /usr/bin/tar.
# Then build with pods/build.sh <app-dir>.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
app=$(cd "${1:?usage: prepare.sh <app-dir>}" && pwd)
export PATH="$here/bin:$PATH"

# Expo's precompiled-module check reads tarball members with a glob, which only bsdtar supports.
# It runs /usr/bin/tar by absolute path.
if ! /usr/bin/tar --version 2>/dev/null | grep -q bsdtar; then
	echo "prepare: /usr/bin/tar must be bsdtar (libarchive) for Expo's precompiled modules" >&2
	exit 1
fi

cd "$app"
nm=$(node -p "require('path').resolve(require.resolve('expo/package.json'),'../..')")

# expo-modules-macros ships the Swift macro plugin for macOS in apple/ and for Linux in
# @expo/modules-macros-linux-<arch>. swiftc loads the apple/ path, so put the Linux binary there.
macro=$nm/expo-modules-macros/apple/ExpoModulesMacros
arch=$(node -p process.arch)
linux_macro=$nm/@expo/modules-macros-linux-$arch/ExpoModulesMacros
if [ -f "$macro" ] && file "$macro" | grep -q Mach-O; then
	[ -x "$linux_macro" ] || { echo "prepare: $linux_macro missing; install optional dependencies" >&2; exit 1; }
	mv "$macro" "$macro.macos"
	cp "$linux_macro" "$macro"
fi

# expo-modules-autolinking skips the @ExpoModule class scan off macOS, so the modules provider
# misses packages that rely on it. The scanner has a Linux build; lift the platform check.
apple_js=$nm/expo-modules-autolinking/build/platforms/apple/apple.js
python3 - "$apple_js" <<'EOF'
import re, sys
path = sys.argv[1]
text = open(path).read()
new = re.sub(r"\n\s*if \(process\.platform !== 'darwin'\) \{\n\s*return null;\n\s*\}", "", text, count=1)
if new != text:
    open(path, "w").write(new)
EOF

npx expo prebuild --platform ios --no-install
printf 'export NODE_BINARY=%s\n' "$(command -v node)" > ios/.xcode.env.local

(cd ios && pod install)
ruby "$here/fix-pods-project.rb" "$app/ios"
