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
	"Software"
	{
		"Valve"
		{
			"Steam"
			{
				"apps"
				{
					"123"
					{
						"LaunchOptions"		"-vulkan"
					}
					"456"
					{
					}
					"789"
					{
						"LaunchOptions"		"gamescope -f -- %command%"
					}
				}
			}
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

commandlineLaunchOptions prepend 789 'steamtinkerlaunch %command%'
[ "$(getLocalConfigLaunchOptions 789)" = 'gamescope -f -- %command%' ]

commandlineLaunchOptions prepend 999 'steamtinkerlaunch %command%'
[ "$(getLocalConfigLaunchOptions 999)" = 'steamtinkerlaunch %command%' ]

commandlineLaunchOptions prepend installed 'steamtinkerlaunch %command%'
[ "$(getLocalConfigLaunchOptions 123)" = 'steamtinkerlaunch %command% -vulkan' ]
[ "$(getLocalConfigLaunchOptions 456)" = 'steamtinkerlaunch %command%' ]

echo 'launch-options manager regression test passed'
