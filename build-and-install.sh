#!/usr/bin/env bash

set -e

cd "$(dirname ${BASH_SOURCE[0]})"

MANIFEST='io.github.TeamWheelWizard.WheelWizard.yaml'

BUILDER_APP_ID='org.flatpak.Builder'

CLEAN=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --clean)
      CLEAN=1
      shift
      ;;
    *)
      ;;
  esac
done

cleanup() {
  if [ "$CLEAN" -eq 1 ]; then
    rm -rf .flatpak-builder
    rm -rf build-dir
    rm -rf repo
  fi
}

flatpak remote-add --user --if-not-exists flathub 'https://dl.flathub.org/repo/flathub.flatpakrepo'
flatpak install --user --noninteractive flathub "$BUILDER_APP_ID"

cleanup

flatpak run --user "$BUILDER_APP_ID" \
  --user \
  --install-deps-from=flathub \
  --install-deps-only \
  build-dir \
  "$MANIFEST"

cleanup

flatpak run --user "$BUILDER_APP_ID" \
  --user \
  --force-clean \
  --install \
  --repo=repo \
  --disable-rofiles-fuse \
  build-dir \
  "$MANIFEST"

cleanup
