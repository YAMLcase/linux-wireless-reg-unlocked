# Wireless regulatory experiment for CachyOS

This fork packages TenkyuChimata's patched `iwlwifi` and `cfg80211` modules for
**linux-cachyos 7.2.2-1**, release **7.2.2-1-cachyos**. It uses the matching
CachyOS kernel source and installed headers, with Clang/LLVM, rather than stock
Arch's kernel source and GCC build defaults. It does not rebuild the whole kernel.

**Status:** built and checked on steambox on 2026-09-27. The package has not been
installed or loaded. Successful compilation does not establish that Intel AX211
firmware will permit a 6 GHz / 160 MHz AP. See [build evidence](docs/build-validation.md).

## Scope

The three upstream patches are unchanged. They add `lar_disable`, relax NVM
channel flags, accept unsigned regulatory databases, and reject driver/Country IE
regulatory hints. The channel patch also clears radar and indoor-only flags; it
is broader than a 6 GHz-only change. This remains an experimental patch set.
The fork's changes cover packaging and build/boot integration, not firmware.

The package has a distinct name, `linux-wireless-reg-unlocked-cachyos`, and
conflicts with the original package. It pins both the kernel and headers to an
exact version. It uses checksummed CachyOS sources and rejects mismatched headers
or a different Clang version. The current build expects all five Intel/cfg80211
modules enabled by this kernel configuration.

## Build without installing

On the CachyOS machine with matching kernel, headers and compiler already installed:

```bash
git clone --branch cachyos-support https://github.com/YAMLcase/linux-wireless-reg-unlocked.git
cd linux-wireless-reg-unlocked
pacman -Q linux-cachyos linux-cachyos-headers clang llvm lld
bash tests/install-hooks.sh
MAKEFLAGS=-j4 makepkg
```

Install any missing build dependencies listed in `PKGBUILD` first. Do not use
`makepkg -si` when only building. The build does not load modules, rebuild boot
images, or restart networking. It checks module release strings and the new
`lar_disable` parameter before creating the package.

The source is CachyOS release [`cachyos-7.2.2-1`](https://github.com/CachyOS/linux/releases/tag/cachyos-7.2.2-1),
selected from the corresponding [CachyOS PKGBUILD](https://github.com/CachyOS/linux-cachyos/blob/bd8a07da314743eede668d999d37253c1a77c186/linux-cachyos/PKGBUILD).
Its SHA-256 is pinned in this fork; the downloaded archive also matched the
Blake2 checksum in that upstream PKGBUILD during validation.

## Install and recover

Installation changes the modules used on the next load or boot. Schedule the
reboot as a separate maintenance step and retain Ethernet access.

```bash
sudo pacman -U ./linux-wireless-reg-unlocked-cachyos-7.2.2-1-x86_64.pkg.tar.zst
```

The install/upgrade/removal scriptlet runs `depmod` for the pinned kernel, then
uses `limine-mkinitcpio` if available. Otherwise it uses dracut, then mkinitcpio.
It does not choose `kernel-install` merely because systemd installed it.
Failures are reported and must be resolved before rebooting. No runtime module
reload or network restart is performed; the original package's `WIRELESS_FORCE`
configuration is not used by this fork.

The modules live under `/usr/lib/modules/7.2.2-1-cachyos/updates/`; stock modules
remain installed. After a planned reboot, inspect the loaded module parameter
with `cat /sys/module/iwlwifi/parameters/lar_disable`, along with the kernel
journal and radio channel table. `modinfo -n iwlwifi` alone shows the module that
would be selected on the next load, not proof of which module is already loaded.
Keep AP configuration changes as a separate experiment.

To restore stock modules:

```bash
sudo pacman -R linux-wireless-reg-unlocked-cachyos
```

Removal uses the original target kernel even if another kernel is running,
removes the package's module options, regenerates dependency indexes and boot
images, and leaves currently loaded modules in memory until reboot. If necessary,
boot the installed CachyOS LTS entry to remove the package and refresh images.
The fork does not build LTS modules or provision Secure Boot module signing.

## Kernel upgrades

There is no DKMS or automatic rebuild. An installed package intentionally blocks
a mismatched kernel/header upgrade through exact dependencies. Do not bypass
those dependency checks or use `IgnorePkg` to maintain a partial system upgrade.

For a normal upgrade, remove this experimental package, perform a full
`pacman -Syu`, and reboot with stock modules. To rebuild for the new kernel:

1. Record `pacman -Q linux-cachyos linux-cachyos-headers`, the release under
   `/usr/lib/modules`, and `CONFIG_CC_VERSION_TEXT` in the matching headers.
2. Find the CachyOS packaging commit for that binary release. Set
   `_kernelpkgver` and `_srctag` in `PKGBUILD` from that evidence; a source tag's
   release suffix is not necessarily identical to the binary package release.
3. Update `_target_kernel` in `wireless-reg-unlocked-cachyos.install`, the source
   archive checksum, and the scriptlet checksum. Increment `pkgrel` if the
   upstream kernel version did not change.
4. Review patch application, regenerate `.SRCINFO` with `makepkg --printsrcinfo`,
   run hook tests, and build from a clean source directory with `makepkg -C`.
5. Inspect the resulting package and test it separately before relying on it.

The inherited hourly Arch/AUR workflow is restricted to the original upstream
repository. Its local updater also refuses this CachyOS PKGBUILD. This fork does
not publish to the original author's AUR package.

Upstream patch authorship and license remain in the Git history and [LICENSE](LICENSE).
