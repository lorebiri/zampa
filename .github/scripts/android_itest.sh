#!/usr/bin/env bash
# Collaudo su emulatore Android (C2-1). I permessi di notifica e di sveglie
# esatte vengono concessi via adb appena l'app è installata, come farebbe
# l'utente toccando «Consenti»: così il test non resta fermo sul dialogo.
set -u
free -m || true
PKG=it.zampa.zampa
df -h / || true
(
  for i in $(seq 1 300); do
    if adb shell pm list packages | grep -q "$PKG"; then
      adb shell pm grant "$PKG" android.permission.POST_NOTIFICATIONS || true
      adb shell appops set "$PKG" SCHEDULE_EXACT_ALARM allow || true
      break
    fi
    sleep 1
  done
) &
flutter test integration_test/app_test.dart -d emulator-5554 2>&1 | tee itest.log
status=${PIPESTATUS[0]}
echo "== Notifiche in attesa secondo il sistema =="
adb shell dumpsys alarm | grep -c "$PKG" || true
exit "$status"
