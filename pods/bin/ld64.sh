# Sourced by pods/bin tools. Sets $LD64: an ld64.lld that links for Apple platforms.
# The Swift toolchain's ld64.lld refuses iOS and macOS ("does not support linking for platform").
# sweetpad ships one that accepts them; LD64_LLD overrides the lookup. Callers such as
# build-xcframework.sh run tools under `env -i` with only PATH and HOME, so the lookup walks PATH.
LD64=${LD64_LLD:-}
if [ -z "$LD64" ]; then
	_sp=$(command -v sweetpad 2>/dev/null || true)
	[ -n "$_sp" ] && _sp=$(dirname "$(readlink -f "$_sp")")
	for _c in ${_sp:+"$_sp/libexec/sweetpad/llvm" "$_sp/../libexec/sweetpad/llvm"} /usr/local/libexec/sweetpad/llvm; do
		[ -x "$_c" ] && { LD64=$_c; break; }
	done
fi
[ -n "$LD64" ] || { echo "$(basename "$0") (linux): no ld64.lld for Apple platforms; install sweetpad or set LD64_LLD" >&2; exit 69; }
# The sweetpad llvm binary is multi-call and picks the tool from its name.
LD64_DIR=${TMPDIR:-/tmp}/pods-ld64-$(id -u)
mkdir -p "$LD64_DIR"
ln -sfn "$LD64" "$LD64_DIR/ld64.lld"
LD64=$LD64_DIR/ld64.lld
