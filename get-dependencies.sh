#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
    libdbusmenu-glib \
    gnome-keyring

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano

# Comment this out if you need an AUR package
#make-aur-package

# If the application needs to be manually built that has to be done down here
echo "Getting VS Code..."
echo "---------------------------------------------------------------"
case "$ARCH" in
    x86_64)  tgz_arch=x64;;
    aarch64) tgz_arch=arm64;;
esac

DOWNLOAD_URL=$(curl -sI -o /dev/null -w '%{redirect_url}' \
    "https://code.visualstudio.com/sha/download?build=stable&os=linux-$tgz_arch")

if ! wget --retry-connrefused --tries=30 "$DOWNLOAD_URL" -O /tmp/vscode.tar.gz 2>/tmp/download.log; then
    cat /tmp/download.log
    exit 1
fi

mkdir -p ./AppDir/bin
tar -xzf /tmp/vscode.tar.gz -C /tmp

# The tarball extracts to VSCode-linux-tgz_arch/ with a root-level `code` ELF
# (the Electron binary) and a bin/ subdirectory with the CLI script + tunnel.
for item in /tmp/VSCode-linux-${tgz_arch}/*; do
    case "$(basename "$item")" in
        bin) ;;
        *)   mv -v "$item" ./AppDir/bin/ ;;
    esac
done
# Handle the bin/ subdir: code-tunnel binary + CLI script (rename to avoid conflict)
mv -v /tmp/VSCode-linux-${tgz_arch}/bin/code-tunnel ./AppDir/bin/
mv -v /tmp/VSCode-linux-${tgz_arch}/bin/code ./AppDir/bin/code-cli
rm -rf /tmp/VSCode-linux-${tgz_arch}

# Extract version
VERSION=$(awk -F'"' '/"version":/ {print $4}' ./AppDir/bin/resources/app/package.json)
echo "$VERSION" > ~/version
echo "VS Code version: $VERSION"

# Create .desktop entry
cat > ./AppDir/code.desktop << 'EOF'
[Desktop Entry]
Name=Visual Studio Code
Comment=Code Editing. Redefined.
GenericName=Text Editor
Exec=code %F
Icon=code
Type=Application
StartupNotify=false
StartupWMClass=code
Categories=TextEditor;Development;IDE;
MimeType=text/plain;
Actions=new-empty-window;
Keywords=vscode;

[Desktop Action new-empty-window]
Name=New Empty Window
Exec=code --new-window %F
Icon=code
EOF
