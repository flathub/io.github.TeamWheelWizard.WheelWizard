#!/usr/bin/env bash

set -eo pipefail

cd "$(dirname ${BASH_SOURCE[0]})"

REPO_GITHUB_USER='TeamWheelWizard'
REPO_NAME='WheelWizard'

WII_REPO_GITHUB_USER='patchzyy'
WII_REPO_NAME='Wiicompiled'

NOD_REPO_GITHUB_USER='encounter'
NOD_REPO_NAME='nod'

GENERATOR_PYPROJECT='pyproject.toml'
GENERATOR_UV_LOCK='uv.lock'

FLATPAK_BUILDER_TOOLS_URL='https://raw.githubusercontent.com/flatpak/flatpak-builder-tools/master'

DOTNET_GENERATOR='flatpak-dotnet-generator.py'
DOTNET_GENERATOR_URL="$FLATPAK_BUILDER_TOOLS_URL/dotnet/$DOTNET_GENERATOR"
DOTNET_GENERATOR_PROJECT_URL="$FLATPAK_BUILDER_TOOLS_URL/dotnet/$GENERATOR_PYPROJECT"
CARGO_GENERATOR='flatpak-cargo-generator.py'
CARGO_GENERATOR_URL="$FLATPAK_BUILDER_TOOLS_URL/cargo/$CARGO_GENERATOR"
CARGO_GENERATOR_PROJECT_URL="$FLATPAK_BUILDER_TOOLS_URL/cargo/$GENERATOR_PYPROJECT"
PIP_GENERATOR='flatpak-pip-generator.py'
PIP_GENERATOR_URL="$FLATPAK_BUILDER_TOOLS_URL/pip/$PIP_GENERATOR"
PIP_GENERATOR_PROJECT_URL="$FLATPAK_BUILDER_TOOLS_URL/pip/$GENERATOR_PYPROJECT"

MANIFEST='io.github.TeamWheelWizard.WheelWizard.yaml'

DOTNET_VERSION=''
WII_DOTNET_VERSION=''
QT_VERSION=''
COMMIT=''
WII_COMMIT=''
NOD_COMMIT=''

usage() {
  echo "Usage: $0 --dotnet <version> --wii-dotnet <version> --qt <version> --ww-commit <commit> --wii-commit <commit> --nod-commit <commit>"
  exit 1
}

cleanup() {
  rm -rf "$REPO_NAME"
  rm -f "$DOTNET_GENERATOR"
  rm -f "$CARGO_GENERATOR"
  rm -f "$PIP_GENERATOR"
  rm -f "$GENERATOR_PYPROJECT"
  rm -rf .venv
  rm -rf "$NOD_REPO_NAME"
  rm -rf "$WII_REPO_NAME"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dotnet)
      if [ -n "$2" ] && [ "${2:0:2}" != "--" ]; then
        DOTNET_VERSION="$2"
        shift 2
      else
        echo "[-] --dotnet requires a version argument."
        usage
      fi
      ;;
    --wii-dotnet)
      if [ -n "$2" ] && [ "${2:0:2}" != "--" ]; then
        WII_DOTNET_VERSION="$2"
        shift 2
      else
        echo "[-] --wii-dotnet requires a version argument."
        usage
      fi
      ;;
    --qt)
      if [ -n "$2" ] && [ "${2:0:2}" != "--" ]; then
        QT_VERSION="$2"
        shift 2
      else
        echo "[-] --qt requires a version argument."
        usage
      fi
      ;;
    --commit)
      if [ -n "$2" ] && [ "${2:0:2}" != "--" ]; then
        COMMIT="$2"
        shift 2
      else
        echo "[-] --commit requires a commit argument."
        usage
      fi
      ;;
    --wii-commit)
      if [ -n "$2" ] && [ "${2:0:2}" != "--" ]; then
        WII_COMMIT="$2"
        shift 2
      else
        echo "[-] --wii-commit requires a commit argument."
        usage
      fi
      ;;
    --nod-commit)
      if [ -n "$2" ] && [ "${2:0:2}" != "--" ]; then
        NOD_COMMIT="$2"
        shift 2
      else
        echo "[-] --nod-commit requires a commit argument."
        usage
      fi
      ;;
    -*)
      echo "[-] Unknown option $1"
      usage
      ;;
    *)
      echo "[-] Invalid argument $1"
      usage
      ;;
  esac
done

if [ -z "$DOTNET_VERSION" ] || [ -z "$WII_DOTNET_VERSION" ] || [ -z "$QT_VERSION" ] || [ -z "$COMMIT" ] || [ -z "$WII_COMMIT" ] || [ -z "$NOD_COMMIT" ]; then
  echo "[-] Options --dotnet, --wii-dotnet, --qt, --commit, --wii-commit, and --nod-commit are required."
  usage
fi

flatpak remote-add --user --if-not-exists flathub 'https://dl.flathub.org/repo/flathub.flatpakrepo'

FREEDESKTOP_VERSION=$(
  flatpak --user remote-info --show-metadata flathub "org.kde.Sdk//$QT_VERSION" |
    awk '
      # We need to look for the Freedesktop version as we require the .NET SDK extension in the manifest.
      # This tries to match the extension point that the KDE SDK inherits.
      !found && /^\[Extension org\.freedesktop\.Sdk\.Extension\]/ {
        found = 1
        next
      }

      found {
        # Stop at the first blank line or line beginning with a `[`
        if ($0 == "" || $0 ~ /^\[/) {
          exit
        }
        # Extract the required version number
        if ($0 ~ /^[[:space:]]*version[[:space:]]*=/) {
          sub(/^[[:space:]]*version[[:space:]]*=[[:space:]]*/, "")
          print
          exit
        }
      }
    '
)

if [ -z "$FREEDESKTOP_VERSION" ]; then
  echo "[-] Freedesktop version could not be determined."
  exit 1
fi

cleanup

# Required Flatpaks for the .NET generator
flatpak install --user --noninteractive flathub "org.freedesktop.Sdk//$FREEDESKTOP_VERSION"
flatpak install --user --noninteractive flathub "org.freedesktop.Sdk.Extension.dotnet$DOTNET_VERSION//$FREEDESKTOP_VERSION"
flatpak install --user --noninteractive flathub "org.freedesktop.Sdk.Extension.dotnet$WII_DOTNET_VERSION//$FREEDESKTOP_VERSION"

mkdir -p sources/nuget/WheelWizard
mkdir -p sources/cargo/Wiicompiled
mkdir -p sources/cmake/Wiicompiled
mkdir -p sources/nuget/Wiicompiled
mkdir -p modules/pip/Wiicompiled

git clone "https://github.com/$REPO_GITHUB_USER/$REPO_NAME" "$REPO_NAME"
pushd "$REPO_NAME"
git checkout "$COMMIT"
for patch in ~1/patches/WheelWizard/*.patch; do
  [ -e "$patch" ] || continue
  git apply "$patch"
done
popd

curl -OL "$DOTNET_GENERATOR_PROJECT_URL"
uv venv
curl -OL "$DOTNET_GENERATOR_URL"
uv run "$DOTNET_GENERATOR" --dotnet "$DOTNET_VERSION" --freedesktop "$FREEDESKTOP_VERSION" \
  sources/nuget/WheelWizard/wheelwizard-nuget-sources.json \
  "$REPO_NAME/$REPO_NAME/$REPO_NAME.csproj"

git clone "https://github.com/$WII_REPO_GITHUB_USER/$WII_REPO_NAME" "$WII_REPO_NAME"
pushd "$WII_REPO_NAME"
git checkout "$WII_COMMIT"
for patch in ~1/patches/Wiicompiled/*.patch; do
  [ -e "$patch" ] || continue
  git apply "$patch"
done
popd

uv run "$DOTNET_GENERATOR" \
  --dotnet "$WII_DOTNET_VERSION" \
  --freedesktop "$FREEDESKTOP_VERSION" \
  --destdir wiicompiled-setup-nuget-sources \
  sources/nuget/Wiicompiled/wiicompiled-setup-nuget-sources.json \
  "$WII_REPO_NAME/Launcher/WiiCompiled.Setup.Linux/WiiCompiled.Setup.Linux.csproj"

uv run "$DOTNET_GENERATOR" \
  --dotnet "$WII_DOTNET_VERSION" \
  --freedesktop "$FREEDESKTOP_VERSION" \
  --destdir translator-nuget-sources \
  sources/nuget/Wiicompiled/translator-nuget-sources.json \
  "$WII_REPO_NAME/translator/src/Translator.Cli/Translator.Cli.csproj"

rm -f "$GENERATOR_PYPROJECT"
rm -f "$GENERATOR_UV_LOCK"
rm -rf .venv

git clone "https://github.com/$NOD_REPO_GITHUB_USER/$NOD_REPO_NAME" "$NOD_REPO_NAME"
pushd "$NOD_REPO_NAME"
git checkout "$NOD_COMMIT"
for patch in ~1/patches/nod/*.patch; do
  [ -e "$patch" ] || continue
  git apply "$patch"
done
popd
curl -OL "$CARGO_GENERATOR_PROJECT_URL"
uv venv
curl -OL "$CARGO_GENERATOR_URL"
uv run "$CARGO_GENERATOR" "$NOD_REPO_NAME"/Cargo.lock \
  -o sources/cargo/Wiicompiled/nodtool-cargo-sources.json
rm -f "$GENERATOR_PYPROJECT"
rm -f "$GENERATOR_UV_LOCK"
rm -rf .venv

curl -OL "$PIP_GENERATOR_PROJECT_URL"
uv venv
curl -OL "$PIP_GENERATOR_URL"
uv run "$PIP_GENERATOR" --runtime="org.freedesktop.Sdk//$FREEDESKTOP_VERSION" --cleanup all -o tmp.json jinja2
cat tmp.json | yq -y > modules/pip/Wiicompiled/dawn-jinja2-pip-module.yaml
rm -f tmp.json
rm -f "$GENERATOR_PYPROJECT"
rm -f "$GENERATOR_UV_LOCK"
rm -rf .venv

WIICOMP_SETUP_SOURCES="$(cat sources/nuget/Wiicompiled/wiicompiled-setup-nuget-sources.json)"
# Comment or uncomment the line adding the `wiicompiled-setup`
# source depending on whether it needs nuget packages or not
if [ -z "$WIICOMP_SETUP_SOURCES" ] || [ "$WIICOMP_SETUP_SOURCES" == "[]" ]; then
  sed -i '/^[[:space:]]*#/! s|- \./sources/nuget/Wiicompiled/wiicompiled-setup-nuget-sources\.json$|# - ./sources/nuget/Wiicompiled/wiicompiled-setup-nuget-sources.json|' \
    "$MANIFEST"

  sed -E -i \
'/^[[:space:]]*#/! s|^([[:space:]]*)ADDITIONAL_NUGET_SOURCE="\$MAYBE_EMPTY_NUGET_SOURCE"[[:space:]]*$|\1#ADDITIONAL_NUGET_SOURCE="$MAYBE_EMPTY_NUGET_SOURCE"|' \
    "$MANIFEST"
else
  sed -E -i 's|^([[:space:]]*)#[[:space:]]*- \./sources/nuget/Wiicompiled/wiicompiled-setup-nuget-sources\.json$|\1- ./sources/nuget/Wiicompiled/wiicompiled-setup-nuget-sources.json|' \
    "$MANIFEST"

  sed -E -i \
's|^([[:space:]]*)#[[:space:]]*ADDITIONAL_NUGET_SOURCE="\$MAYBE_EMPTY_NUGET_SOURCE"[[:space:]]*$|\1ADDITIONAL_NUGET_SOURCE="$MAYBE_EMPTY_NUGET_SOURCE"|' \
    "$MANIFEST"
fi

echo Make sure the .NET versions used in the manifest are correct.
# The Qt runtime branch
sed -i -e "s|^runtime-version:.*|runtime-version: '$QT_VERSION'|g" "$MANIFEST"
# LLVM's Freedesktop extension branch
sed -i -e "s|^version:.*|version: '$FREEDESKTOP_VERSION'|g" "$MANIFEST"
yq -y . "$MANIFEST" | tee "$MANIFEST.1" >/dev/null
yq -y "(.modules[] \
  | select(has(\"sources\")) \
  | .sources[] \
  | select(type == \"object\") \
  | select(.url == \"https://github.com/$REPO_GITHUB_USER/$REPO_NAME.git\") \
  | .commit) = \"$COMMIT\"" "$MANIFEST" | tee "$MANIFEST.2" >/dev/null
diff "$MANIFEST.1" "$MANIFEST.2" > "$MANIFEST.diff" || true
patch -o "$MANIFEST.new" "$MANIFEST" < "$MANIFEST.diff"
rm -f "$MANIFEST.1" "$MANIFEST.2" "$MANIFEST.diff" "$MANIFEST"
mv "$MANIFEST.new" "$MANIFEST"

# Note that the Freedesktop SDK + .NET extension flatpaks will still be installed for the current user after this!
# A simple `flatpak uninstall --user --all` command can uninstall all per-user installations

cleanup
