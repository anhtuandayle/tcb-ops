#!/usr/bin/env bash
# Tự chép bản mới vào file Google Docs cố định của bài, không cần ai bấm "Mở file Docs".
# Gọi trang web Apps Script (google-apps-script/DongBoDocs.gs, link ở dong-bo-url.txt) với mã bài + mã commit
# vừa đăng lên nhánh tu-dong-ket-qua → Apps Script đọc đúng bản đó và chép đè vào Docs (link Docs không đổi).
# Dùng: bash dong_bo_docs.sh <sha commit tu-dong-ket-qua> <mã bài>...
# Lỗi đồng bộ KHÔNG làm hỏng lượt chạy: chỉ cảnh báo, bản mới vẫn có trên app để Chép tay.
set -uo pipefail
SHA=${1:-}; shift || true
TD=$(cd "$(dirname "$0")" && pwd)
URL=$(tr -d ' \n\r' < "$TD/dong-bo-url.txt" 2>/dev/null)
TOM=${GITHUB_STEP_SUMMARY:-/dev/null}
if ! [[ $URL =~ ^https://script\.google\.com/macros/s/[A-Za-z0-9_-]+/exec$ ]]; then
  echo "::warning::Chưa cài đồng bộ Docs (cong-cu/tu-dong/dong-bo-url.txt trống) – bỏ qua bước chép vào Docs."
  exit 0
fi
[[ $SHA =~ ^[0-9a-f]{40}$ ]] || SHA=""
for MA in "$@"; do
  [[ $MA =~ ^[a-z0-9-]{2,40}$ ]] || continue
  OK=""
  for lan in 1 2 3; do                      # Apps Script thỉnh thoảng bận/khởi động chậm → thử lại
    J=$(curl -sfL -m 90 "$URL?ma=$MA${SHA:+&sha=$SHA}&t=$(date +%s)") || J=""
    LINK=$(printf '%s' "$J" | python3 -I -c 'import json,sys
try: d=json.load(sys.stdin)
except Exception: d={}
u=str(d.get("url","")); print(u if u.startswith("https://docs.google.com/") else "")')
    if [ -n "$LINK" ]; then OK=1; break; fi
    sleep $((lan * 10))
  done
  if [ -n "$OK" ]; then
    echo "✔ Docs $MA: $LINK"; echo "- ✔ **$MA** đã chép vào Docs: $LINK" >> "$TOM"
  else
    LOI=$(printf '%s' "$J" | python3 -I -c 'import json,sys
try: print(str(json.load(sys.stdin).get("loi",""))[:200])
except Exception: print("không có phản hồi")')
    echo "::warning::Chưa chép được $MA vào Docs: $LOI"; echo "- ✘ **$MA** chưa chép được vào Docs: $LOI" >> "$TOM"
  fi
done
exit 0
