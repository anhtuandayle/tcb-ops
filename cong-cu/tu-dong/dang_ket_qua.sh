#!/usr/bin/env bash
# Đăng kết quả trong <thư mục ket-qua> lên nhánh tu-dong-ket-qua (gộp với kết quả các bài khác, giữ bài không chạy lần này).
# In ra (stdout) DUY NHẤT mã commit vừa đăng – dong_bo_docs.sh dùng mã này để Apps Script đọc đúng bản mới.
# Nhánh chưa có (repo mới) → tự tạo. Nhiều bài cùng đăng → lấy bản mới nhất, gộp, đăng lại.
# Dùng: GH_TOKEN=… bash dang_ket_qua.sh <thư mục ket-qua> "<lời commit>" [mã yêu cầu]
set -uo pipefail
KQ=$(realpath "$1"); LOI_COMMIT=$2; MA_YC=${3:-}
TD=$(cd "$(dirname "$0")" && pwd)
KHO="https://x-access-token:${GH_TOKEN:?thiếu GH_TOKEN}@github.com/${GITHUB_REPOSITORY:?thiếu GITHUB_REPOSITORY}.git"
for lan in $(seq 1 12); do
  rm -rf xuat
  if ! git clone -q --depth 1 -b tu-dong-ket-qua "$KHO" xuat 2>/dev/null; then
    if git ls-remote --exit-code --heads "$KHO" tu-dong-ket-qua >/dev/null 2>&1; then sleep 3; continue; fi
    mkdir xuat && git -C xuat init -q -b tu-dong-ket-qua && git -C xuat remote add origin "$KHO"   # lần đầu
  fi
  python3 -I "$TD/tong_hop.py" "$KQ" xuat $MA_YC >&2
  cp "$KQ"/h-*.html "$KQ"/h-*.json xuat/ 2>/dev/null || true          # kết quả ghép HTML (nếu có)
  ls xuat/h-*.json 2>/dev/null | sort | head -n -300 | sed 's/\.json$//' | while read -r f; do rm -f "$f.json" "$f.html"; done   # giữ 300 yêu cầu gần nhất
  git -C xuat add -A
  if git -C xuat diff --cached --quiet; then git -C xuat rev-parse HEAD 2>/dev/null; exit 0; fi
  git -C xuat commit -qm "$LOI_COMMIT"
  if git -C xuat push -q origin HEAD:tu-dong-ket-qua; then git -C xuat rev-parse HEAD; exit 0; fi
  sleep $(( (RANDOM % 5) + lan ))
done
echo "Không đăng được lên tu-dong-ket-qua sau 12 lần" >&2
exit 1
