pkgname=linux-wireless-reg-unlocked-cachyos
_pkgbase=linux-cachyos
_kernelpkgver=7.2.2-1
_kernver=${_kernelpkgver%-*}
_krel=${_kernelpkgver}-cachyos
# Source tag is independent of the binary package release; verify both on updates.
_srctag=cachyos-7.2.2-1
pkgver=${_kernver}
pkgrel=1
pkgdesc='Experimental patched iwlwifi and cfg80211 modules for a pinned CachyOS kernel'
arch=('x86_64')
url='https://github.com/YAMLcase/linux-wireless-reg-unlocked'
license=('GPL-2.0-only')
depends=("${_pkgbase}=${_kernelpkgver}" "${_pkgbase}-headers=${_kernelpkgver}")
makedepends=('bc' 'kmod' 'patch' 'clang' 'llvm' 'lld')
optdepends=('limine-mkinitcpio-hook: refresh Limine boot images'
            'mkinitcpio: refresh initramfs'
            'dracut: refresh initramfs')
conflicts=('linux-wireless-reg-unlocked' 'iwlwifi-lar-patched')
source=("https://github.com/CachyOS/linux/releases/download/${_srctag}/${_srctag}.tar.gz"
        '0001-iwlwifi-add-lar_disable.patch'
        '0002-iwlwifi-nvm-unlock-6ghz-and-relax-channel-flags.patch'
        '0003-cfg80211-allow-unsigned-regdb-and-reject-driver-country-ie-regdom-hints.patch'
        'iwlwifi-lar.conf'
        'dracut-wireless-reg-unlocked.conf'
        'wireless-reg-unlocked-cachyos.install')
sha256sums=('b69413e1941bc9f08d0f5bdf576b4e31ebd948a235d8b8a24a81ba7583e36d77'
            'da2ab52ccdef2b93088c9e0c56bc1c166bf748d021b529cb2af2ff6c5d9e85cc'
            '96f91b3ff8d5caafe4939cb22bb455d34d107d08e14cf3af6dbb47ef70553732'
            'e8574dead1cb1f2b3732b0daeffa5bb9d71e1cc8eee5203348bbe9169c5adbe6'
            'd0f468221c28f5f07a040f36df4dcf571d3931eef7ed273d4e57b631ef9540d3'
            '3758f059f40e24561f588829cb80384324d75b0745d5eba6f4b6313b5809e2d1'
            '812afe6c05bb4a2e88ddce06abceb001d5fe600f31eff23fdb0dc4aa5fdbe4a3')
install=wireless-reg-unlocked-cachyos.install
# Kernel Kbuild controls LTO and stripping; don't inject makepkg's userspace flags.
options=('!debug' '!strip' '!lto')

prepare() {
  # The scriptlet carries its own target, so removal never relies on uname -r.
  grep -qx "_target_kernel='${_krel}'" "${srcdir}/${install}" || {
    echo 'ERROR: Update the install scriptlet target with the kernel pin.' >&2
    return 1
  }
  cd "${srcdir}/${_srctag}"
  local patchfile
  for patchfile in "${srcdir}"/000[123]-*.patch; do
    patch -Np1 -i "${patchfile}"
  done
  # Driver-local includes must resolve against these patched sources.
  sed -i 's|$(srctree)/||g' drivers/net/wireless/intel/iwlwifi/{dvm,mvm,mld}/Makefile
}

build() {
  local builddir="/usr/lib/modules/${_krel}/build"
  local iwlsrc="${srcdir}/${_srctag}/drivers/net/wireless/intel/iwlwifi"
  local cfgsrc="${srcdir}/${_srctag}/net/wireless"
  local release compiler actual_compiler
  [[ -r ${builddir}/Module.symvers && -r ${builddir}/.config ]] || {
    echo "ERROR: Install ${_pkgbase}-headers=${_kernelpkgver}." >&2
    return 1
  }
  release=$(<"${builddir}/include/config/kernel.release")
  [[ ${release} == "${_krel}" ]] || {
    echo "ERROR: Header release ${release} does not match ${_krel}." >&2
    return 1
  }
  compiler=$(sed -n 's/^CONFIG_CC_VERSION_TEXT="\(.*\)"$/\1/p' "${builddir}/.config")
  actual_compiler=$(clang --version | head -n 1)
  [[ ${compiler} == "${actual_compiler}" ]] || {
    echo "ERROR: Headers require ${compiler}; found ${actual_compiler}." >&2
    return 1
  }
  grep -qx 'CONFIG_CC_IS_CLANG=y' "${builddir}/.config" || return 1
  grep -qx 'CONFIG_LD_IS_LLD=y' "${builddir}/.config" || return 1
  export KBUILD_BUILD_USER=builder KBUILD_BUILD_HOST=cachyos
  export KBUILD_BUILD_VERSION=1 KBUILD_BUILD_TIMESTAMP=1970-01-01
  make -C "${builddir}" M="${iwlsrc}" LLVM=1 LLVM_IAS=1 modules
  make -C "${builddir}" M="${cfgsrc}" LLVM=1 LLVM_IAS=1 modules
}

check() {
  local module vermagic
  local iwlsrc="${srcdir}/${_srctag}/drivers/net/wireless/intel/iwlwifi"
  local cfgsrc="${srcdir}/${_srctag}/net/wireless"
  for module in "${iwlsrc}/iwlwifi.ko" "${iwlsrc}/mvm/iwlmvm.ko" \
                "${iwlsrc}/dvm/iwldvm.ko" "${iwlsrc}/mld/iwlmld.ko" \
                "${cfgsrc}/cfg80211.ko"; do
    [[ -f ${module} ]] || return 1
    vermagic=$(modinfo -F vermagic "${module}")
    [[ ${vermagic%% *} == "${_krel}" ]] || {
      echo "ERROR: Wrong vermagic in ${module}: ${vermagic}" >&2
      return 1
    }
  done
  modinfo -p "${iwlsrc}/iwlwifi.ko" | grep -q '^lar_disable:'
}

package() {
  local moddir="${pkgdir}/usr/lib/modules/${_krel}/updates/${pkgname}"
  local iwlsrc="${srcdir}/${_srctag}/drivers/net/wireless/intel/iwlwifi"
  local cfgsrc="${srcdir}/${_srctag}/net/wireless"
  install -dm755 "${moddir}"
  install -m644 "${iwlsrc}/iwlwifi.ko" "${iwlsrc}"/{dvm,mvm,mld}/*.ko \
    "${cfgsrc}/cfg80211.ko" "${moddir}/"
  llvm-strip --strip-debug "${moddir}"/*.ko
  install -Dm644 "${srcdir}/iwlwifi-lar.conf" "${pkgdir}/etc/modprobe.d/iwlwifi-lar.conf"
  install -Dm644 "${srcdir}/dracut-wireless-reg-unlocked.conf" \
    "${pkgdir}/etc/dracut.conf.d/wireless-reg-unlocked.conf"
  install -Dm644 /dev/stdin "${pkgdir}/usr/share/${pkgname}/kernel-version" <<< "${_krel}"
}
