#!/bin/bash
# Usage: capture.sh WIDTH HEIGHT DENSITY OUT_DIR
# Walks Forma's six store screens on emulator-5554 at the given display size.
set -u
ADB=~/Library/Android/sdk/platform-tools/adb; D=emulator-5554
W=$1; H=$2; DEN=$3; OUT=$4; mkdir -p "$OUT"
a() { "$ADB" -s $D "$@"; }
dp() { python3 -c "print(round($1*$DEN/160))"; }
shot() { sleep "${2:-2}"; a exec-out screencap -p > "$OUT/$1.png"; echo "  $1: $(sips -g pixelWidth -g pixelHeight "$OUT/$1.png" | awk '/pixel/ {printf "%s ", $2}')"; }
tab() { a shell input tap $(( W*(2*$1+1)/8 )) $(( H - $(dp 56) )); }
demo() { a shell am broadcast -a com.android.systemui.demo -e command "$@" >/dev/null; }

echo "== ${W}x${H} @ ${DEN} -> $OUT"
a shell wm size ${W}x${H}; a shell wm density $DEN
a shell am force-stop co.tryforma.app; sleep 2
# Leave demo mode first: re-entering without an exit stacks duplicate
# wifi/signal icons. The emulator's own full wifi and signal icons stay.
demo exit; sleep 1; demo enter; demo clock -e hhmm 0941
demo battery -e level 100 -e plugged false; demo notifications -e visible false
a shell am start -W -n co.tryforma.app/.MainActivity >/dev/null; sleep 12

tab 0; shot 03_progress 3
tab 1; shot 01_train 3
# Start today's workout (button centre 182dp above the bottom), tick two sets
a shell input tap $((W/2)) $(( H - $(dp 182) )); sleep 4
a shell input tap $(( W - $(dp 34) )) $(dp 251); sleep 1
a shell input tap $(( W - $(dp 34) )) $(dp 301); sleep 1
shot 02_live_workout 2
# Leave: X top-left, then "Discard workout" 73dp above the bottom
a shell input tap $(dp 29) $(dp 51); sleep 2
a shell input tap $((W/2)) $(( H - $(dp 117) )); sleep 2
tab 2; shot 04_program 3
tab 1; sleep 2; a shell input tap $((W/2)) $(dp 240); shot 05_exercise_detail 6
a shell input keyevent 4; sleep 1
tab 3; shot 06_profile 3
a shell wm size reset; a shell wm density reset; demo exit
