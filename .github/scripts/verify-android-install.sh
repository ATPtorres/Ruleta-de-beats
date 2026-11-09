#!/usr/bin/env bash
set -euo pipefail

package=com.alemnt.beats.roulette.pruebas
apk=Beat-Roulette-v1.0.1-Pruebas.apk
activity="$package/com.alemnt.beats.roulette.MainActivity"

test "$(adb shell getprop ro.build.version.sdk | tr -d '\r')" = 33
adb install "$apk" | grep -Fx 'Success'
adb shell pm path "$package"
adb shell cmd connectivity airplane-mode enable
adb shell am start -W -n "$activity" | tee android-launch.txt
grep -Fx 'Status: ok' android-launch.txt

for attempt in $(seq 1 12); do
  if adb shell uiautomator dump /sdcard/beat-roulette.xml >/dev/null 2>&1 &&
      adb shell cat /sdcard/beat-roulette.xml | grep -F 'GIRAR' >/dev/null; then
    adb shell pidof "$package"
    echo 'PASS: APK installed and opened the roulette offline on Android 13.'
    exit 0
  fi
  sleep 2
done

adb logcat -d -s AndroidRuntime flutter
echo 'The roulette did not appear after installation.' >&2
exit 1
