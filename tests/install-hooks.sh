# Run with: bash tests/install-hooks.sh
set -eu
source "${BASH_SOURCE[0]%/*}/../wireless-reg-unlocked-cachyos.install"

# All system-changing commands are shell mocks; no host boot files are touched.
command() {
  [[ $1 == -v ]] || { echo 'Unexpected command invocation' >&2; exit 1; }
  case ":${available}:" in
    *":$2:"*) return 0 ;;
    *) return 1 ;;
  esac
}
depmod() { calls+=("depmod $*"); return "${depmod_status}"; }
limine-mkinitcpio() { calls+=("limine $*"); return "${builder_status}"; }
dracut() { calls+=("dracut $*"); return "${builder_status}"; }
mkinitcpio() { calls+=("mkinitcpio $*"); return "${builder_status}"; }
kernel-install() { echo 'Unexpected kernel-install' >&2; exit 1; }
modprobe() { echo 'Unexpected module reload' >&2; exit 1; }
systemctl() { echo 'Unexpected service change' >&2; exit 1; }
uname() { echo 'Unexpected running-kernel fallback' >&2; exit 1; }

assert_calls() {
  [[ ${calls[*]} == "$1" ]] || {
    printf 'Expected: %s\nActual: %s\n' "$1" "${calls[*]}" >&2
    exit 1
  }
}
depmod_status=0 builder_status=0
available=limine-mkinitcpio:dracut:mkinitcpio:kernel-install
for phase in post_install post_upgrade post_remove; do
  calls=()
  "$phase" >/dev/null
  assert_calls "depmod -a ${_target_kernel} limine "
done

available=dracut:mkinitcpio:kernel-install
calls=()
post_install >/dev/null
assert_calls "depmod -a ${_target_kernel} dracut --force --kver ${_target_kernel}"

available=mkinitcpio:kernel-install
calls=()
post_install >/dev/null
assert_calls "depmod -a ${_target_kernel} mkinitcpio -P"

available=limine-mkinitcpio:dracut:mkinitcpio
depmod_status=1
calls=()
if post_remove >/dev/null 2>&1; then exit 1; fi
assert_calls "depmod -a ${_target_kernel}"

depmod_status=0 builder_status=1
calls=()
if post_upgrade >/dev/null 2>&1; then exit 1; fi
assert_calls "depmod -a ${_target_kernel} limine "

builder_status=0 available=kernel-install
calls=()
if post_install >/dev/null 2>&1; then exit 1; fi
assert_calls "depmod -a ${_target_kernel}"
echo 'PASS: lifecycle target, builder selection, failure propagation, no live reload'
