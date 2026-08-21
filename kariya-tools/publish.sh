#!/usr/bin/env bash
# زنجیره‌ی «تا انتشار»: منتظر بیلد فعلی می‌ماند، بیلد نسخه‌ی برنددار را می‌فرستد،
# فایل خروجی را می‌گیرد و روی صفحه‌ی دانلود سرور می‌گذارد.
#
#   bash publish.sh <run-id-بیلد-فعلی>
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/upstream" || exit 1
CURRENT_RUN="${1:-}"
LOG=../publish.log
say() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG"; }

if [ -n "$CURRENT_RUN" ]; then
  say "منتظر پایان بیلد $CURRENT_RUN (کش vcpkg را پر می‌کند)"
  gh run watch "$CURRENT_RUN" --interval 120 >/dev/null 2>&1
  say "بیلد فعلی: $(gh run view "$CURRENT_RUN" --json conclusion --jq .conclusion)"
fi

say "شروع بیلد نسخه‌ی برنددار"
gh workflow run kariya-windows.yml >/dev/null 2>&1
sleep 25
RUN=$(gh run list --workflow=kariya-windows.yml --limit 1 --json databaseId --jq '.[0].databaseId')
say "بیلد تازه: $RUN"

gh run watch "$RUN" --interval 120 >/dev/null 2>&1
CONC=$(gh run view "$RUN" --json conclusion --jq .conclusion)
say "نتیجه: $CONC"
[ "$CONC" = "success" ] || { say "ناموفق — انتشار انجام نشد"; exit 1; }

rm -rf ../artifact && mkdir -p ../artifact
say "گرفتن فایل خروجی"
gh run download "$RUN" -D ../artifact >>"$LOG" 2>&1 || { say "دانلود آرتیفکت نشد"; exit 1; }

EXE=$(find ../artifact -iname "*.exe" | head -1)
[ -n "$EXE" ] || { say "فایل exe در خروجی پیدا نشد"; find ../artifact -type f | head -20 >>"$LOG"; exit 1; }
say "فایل: $EXE ($(du -h "$EXE" | cut -f1))"

DEST="KariyaDesk-1.4.9-x64.exe"
scp -o BatchMode=yes "$EXE" "sa:/var/lib/kariyadesk/app/downloads/$DEST" >>"$LOG" 2>&1 &&
  ssh -o BatchMode=yes sa "chown kariyahesab-desk:kariyahesab-desk /var/lib/kariyadesk/app/downloads/$DEST; chmod 644 /var/lib/kariyadesk/app/downloads/$DEST" &&
  say "منتشر شد: https://desk.kariyahesab.com/download/$DEST" ||
  say "انتقال به سرور ناموفق بود"
