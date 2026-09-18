#!/usr/bin/env bash
set -eo pipefail

STL="$(realpath "$(dirname "$0")/../steamtinkerlaunch")"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

FLCV="$TMPDIR/localconfig.vdf"
PGREP=false

writelog() { :; }
trimWhitespaces() { printf '%s' "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }
setSteamPaths() { :; }
listInstalledGameIDs() { printf '123\n456\n'; }

cat > "$FLCV" <<'VDF'
"UserLocalConfigStore"
{
	"Apps"
	{
		"123"
		{
			"LaunchOptions"		"-vulkan"
		}
	}
}
VDF

source <(sed -n '/### BEGIN TEXT-BASED VDF INTERACTION FUNCTIONS/,/### END TEXT-BASED VDF INTERACTION FUNCTIONS/p' "$STL")

PGREP=true
if commandlineLaunchOptions prepend 123 'steamtinkerlaunch %command%'; then
	echo 'manager modified localconfig.vdf while Steam was running' >&2
	exit 1
fi
[ "$(getLocalConfigLaunchOptions 123)" = '-vulkan' ]
PGREP=false

commandlineLaunchOptions prepend 123 'steamtinkerlaunch %command%'
[ "$(getLocalConfigLaunchOptions 123)" = 'steamtinkerlaunch %command% -vulkan' ]
[ -f "$TMPDIR/localconfig_steamtinkerlaunch.vdf" ]

commandlineLaunchOptions prepend 123 'steamtinkerlaunch %command%'
[ "$(getLocalConfigLaunchOptions 123)" = 'steamtinkerlaunch %command% -vulkan' ]

commandlineLaunchOptions remove 123 'steamtinkerlaunch %command%'
[ "$(getLocalConfigLaunchOptions 123)" = '-vulkan' ]

commandlineLaunchOptions prepend installed 'steamtinkerlaunch %command%'
[ "$(getLocalConfigLaunchOptions 123)" = 'steamtinkerlaunch %command% -vulkan' ]
[ "$(getLocalConfigLaunchOptions 456)" = 'steamtinkerlaunch %command%' ]

echo 'launch-options manager regression test passed'
