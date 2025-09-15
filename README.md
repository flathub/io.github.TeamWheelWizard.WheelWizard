# Flatpak for [Wheel Wizard](https://github.com/TeamWheelWizard/WheelWizard)

This is the Flatpak build repository for Wheel Wizard.
Wheel Wizard is a convenient Mario Kart Wii mod manager and launcher,
purpose-built for the Retro Rewind custom track distribution
with several online features.

## Updating the sources

In order to update the source files, you can use the
`update-sources.sh` script provided in this repository:

```sh
$ ./update-sources.sh --dotnet <dotnet_version> --freedesktop <freedesktop_version> --commit <wheelwizard_commit>
```

The script will patch all .NET, Freedesktop versions along with the commit
of WheelWizard.

**Dependencies**: `coreutils`, `diffutils`, `flatpak`, `git`, `grep`, `patch`, `python3`, `sed`, `yq`.

To actually build and install the Flatpak locally using the local sources,
you can use the `build-and-install-local.sh` script:

```sh
$ ./build-and-install-local.sh
```

## Fixing environment issues

Users with Flatpak applications in their autostart configuration may
experience issues related to their `XAUTHORITY` environment variable,
since it might not exist in the context from which the Dolphin Flatpak
is spawned.

In order to use `systemd`'s user environment to fetch the `XAUTHORITY`
from there, set `GRAB_SYSTEMD_USER_XAUTHORITY=1` as an environment variable
override (e.g. through Flatseal). The launcher will then use
`systemctl --user show-environment` exclusively to get the value for `XAUTHORITY`,
similar to how you would expect it from `systemd-run --user`.
