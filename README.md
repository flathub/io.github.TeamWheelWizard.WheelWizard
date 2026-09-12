# Flatpak for [Wheel Wizard](https://github.com/TeamWheelWizard/WheelWizard)

This is the Flatpak build repository for Wheel Wizard.
Wheel Wizard is a convenient Mario Kart Wii mod manager and launcher,
designed for the Retro Rewind custom track distribution.
It includes several online features and supports running the game through
either the Dolphin Emulator or Wiicompiled.

## Updating the sources

In order to update the source files, you can use the
`update-sources.sh` script provided in this repository:

```sh
$ ./update-sources.sh --dotnet <dotnet_version> --qt <qt_version> --commit <wheelwizard_commit>
```

The script will patch all .NET/Qt versions along with the commit
of WheelWizard.

**Dependencies**: `awk`, `coreutils`, `diffutils`, `flatpak`, `git`, `grep`, `patch`, `python3`, `sed`, `yq`.

To actually build and install the Flatpak locally using the local sources,
you can use the `build-and-install.sh` script:

```sh
$ ./build-and-install.sh
```
