#!/usr/bin/env bash
set -eo pipefail

STL="$(realpath "$(dirname "$0")/../steamtinkerlaunch")"
TMPDIR="$(mktemp -d)"
SHARED_PATHS="/dev/shm/steamtinkerlaunch/steampaths.txt"
if [ -f "$SHARED_PATHS" ]; then
	cp "$SHARED_PATHS" "$TMPDIR/steampaths.txt"
fi
cleanup() {
	if [ -f "$TMPDIR/steampaths.txt" ]; then
		cp "$TMPDIR/steampaths.txt" "$SHARED_PATHS"
	else
		rm -f "$SHARED_PATHS"
	fi
	rm -rf "$TMPDIR"
}
trap cleanup EXIT
rm -f "$SHARED_PATHS"

mkdir -p "$TMPDIR/bin" "$TMPDIR/home/.config/steamtinkerlaunch" "$TMPDIR/home/.steam/root/config" "$TMPDIR/home/.steam/root/userdata/123/config"
cat > "$TMPDIR/bin/pgrep" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
chmod +x "$TMPDIR/bin/pgrep"

cat > "$TMPDIR/home/.config/steamtinkerlaunch/global.conf" <<'CFG'
STEAMUSERID="123"
CFG

cat > "$TMPDIR/home/.steam/root/config/loginusers.vdf" <<'VDF'
"users"
{
	"123"
	{
		"MostRecent"		"1"
	}
}
VDF

cat > "$TMPDIR/home/.steam/root/userdata/123/config/localconfig.vdf" <<'VDF'
"UserLocalConfigStore"
{
	"Software"
	{
		"Valve"
		{
			"Steam"
			{
				"apps"
				{
					"1"
					{
						"LaunchOptions"		"-vulkan"
					}
				}
			}
		}
	}
}
VDF

env HOME="$TMPDIR/home" PATH="$TMPDIR/bin:$PATH" "$STL" lo prepend 1 'DRI_PRIME=1 steamtinkerlaunch %command%'
grep -F '"LaunchOptions"		"DRI_PRIME=1 steamtinkerlaunch %command% -vulkan"' "$TMPDIR/home/.steam/root/userdata/123/config/localconfig.vdf" >/dev/null

echo 'headless launch-options integration test passed'
