# Validation: 2026-09-27

Target: steambox, CachyOS, installed and running `7.2.2-1-cachyos`.
Both `linux-cachyos` and `linux-cachyos-headers` were version `7.2.2-1`.
Compiler/linker: Clang 22.1.8 and LLD 22.1.8. Kernel headers enable ThinLTO,
disable MODVERSIONS and CFI, and do not force module signatures.

Built as an unprivileged user with `MAKEFLAGS=-j4 nice -n 10 makepkg --noconfirm`.
The only package installed to support the build was the missing `bc` dependency.
No kernel upgrade or experimental module installation was performed.

## Results

- CachyOS source SHA-256 matched the pinned value. Its Blake2 checksum also
  matched the historical CachyOS PKGBUILD.
- All three unchanged upstream patches applied with line offsets, without fuzz
  or rejected hunks.
- Kbuild and MODPOST passed for `iwlwifi`, `iwlmvm`, `iwldvm`, `iwlmld`, `cfg80211`.
- All five modules have the same full vermagic as the stock driver:
  `7.2.2-1-cachyos SMP preempt mod_unload`.
- `modinfo -p` confirmed `iwlwifi` exposes `lar_disable`.
- The package contains the five modules in the target's `updates/` directory,
  both configuration files, target metadata, and the correct install scriptlet.
- An isolated copy of the stock module tree plus the unpacked package passed
  `depmod`. `modprobe --show-depends` selected patched cfg80211/iwlwifi/iwlmvm
  alongside stock mac80211 and other dependencies. Nothing was loaded.
- Mocked lifecycle tests cover install, upgrade, removal, builder precedence,
  error propagation, and absence of runtime module/service changes.
- Shell syntax checks and `git diff --check` passed.

The compiler emitted three unused-function warnings in `reg.c` because upstream
patch 0003 bypasses `regdb_has_valid_signature`, `reg_set_rd_driver`, and
`reg_set_rd_country_ie`. There were no compiler errors. The patches were kept
unchanged rather than mixing cleanup with CachyOS packaging changes.

## Artifact

On steambox:

```
/home/larryc/builds/linux-wireless-reg-unlocked-cachyos/linux-wireless-reg-unlocked-cachyos-7.2.2-1-x86_64.pkg.tar.zst
```

SHA-256:

```
74b4cf7ff309943b5e7d386e0c6bb135b43ba2442c39ed32568616f4b2bf89a7
```

Build log: `build.log` in the same directory. This checksum identifies this
artifact, not a reproducibility guarantee for later builds.

At 15:08 CDT, the production AP remained enabled on US channel 149 (5745 MHz).
The target and all three services were active, boot autostart remained enabled,
DNS through the AP address worked, and seven containers remained up. Module
resolution on the real host still pointed at the stock driver files.

Module loading, firmware behavior, 6 GHz AP startup, client association, streaming
performance, and a real installation/removal of this package remain untested.
