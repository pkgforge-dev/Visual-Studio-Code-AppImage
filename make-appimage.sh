#!/bin/sh

set -eu

ARCH=$(uname -m)
export ARCH
export OUTPATH=./dist
export ADD_HOOKS="self-updater.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export ICON=https://raw.githubusercontent.com/microsoft/vscode/refs/heads/main/resources/linux/code.png
export DEPLOY_GTK=1

# Deploy dependencies
quick-sharun ./AppDir/bin/code ./AppDir/bin/code-tunnel \
  /usr/bin/gnome* \
  /usr/lib/gnome-keyring/devel/gkm*.so* \
  /usr/lib/pkcs11/gnome*.so* \
  /usr/lib/security/pam*.so*

# Additional changes can be done in between here

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the app for 12 seconds, if the test fails due to the app
# having issues running in the CI use --simple-test instead
quick-sharun --simple-test ./dist/*.AppImage
