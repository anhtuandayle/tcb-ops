# TCB ops – Cập nhật bài Techcombank

Bấm nút là có bài Techcombank mới, giá và lãi suất đã cập nhật, chỗ đổi được tô vàng. Chạy miễn phí trên GitHub Actions, không tốn token Claude.
Hai bài lãi suất **tự chạy mỗi sáng và tự chép vào file Google Docs**, không ai phải dán tay.

## Luồng chạy

```
App (GitHub Pages / Netlify)
  └─ nút "Chạy cập nhật" ─► hàm Netlify `chay` ─► workflow tu-dong-cap-nhat.yml (mỗi bài 1 máy)
                                                     └─► nhánh tu-dong-ket-qua (<mã>.html + trang-thai.json)
                                                           ├─► app: nút Chép / Tải Word
                                                           └─► bài lãi suất: Apps Script DongBoDocs ─► Google Docs cố định

Mỗi sáng 6h43 (giờ VN) ─► workflow lai-suat-cong-khai.yml ─► tu-dong-ket-qua ─► TỰ chép vào Docs ─► trang lai-suat/
```

| Thư mục / file | Vai trò |
|---|---|
| `.github/workflows/tu-dong-cap-nhat.yml` | Chạy các bài được bấm trên app |
| `.github/workflows/lai-suat-cong-khai.yml` | Lãi suất hằng ngày, tự vào Docs |
| `.github/workflows/them-bai.yml` | Ghi yêu cầu "Thêm bài mới" từ app |
| `cong-cu/app-cap-nhat/web/` | App chính (gốc trang) |
| `cong-cu/app-lai-suat/web/` | Trang lãi suất (`/lai-suat/`) |
| `cong-cu/tu-dong/` | `chay.sh` (chạy 1 bài), `tong_hop.py`, `dang_ket_qua.sh` (đăng kết quả), `dong_bo_docs.sh` (tự chép vào Docs), `danh-sach.json` (mã bài hợp lệ) |
| `cong-cu/tu-dong/google-apps-script/DongBoDocs.gs` | Chép bản mới vào file Docs cố định (chạy trên tài khoản Google của bạn) |
| `cong-cu/skill-cap-nhat-bai-tcb/cong-thuc/<mã>/` | "Công thức" lấy số của từng bài |
| `cong-cu/cap-nhat-lai-suat/cap-nhat.py` | Công cụ 2 bài lãi suất (VnExpress + Topi) |
| `cong-cu/dang-app/` | `dang.sh` đăng app + hàm Netlify (`chay`, `kq`, `them`) |

## Cài một lần

Tên đang dùng: kho **`anhtuandayle/tcb-ops`** (để công khai), Netlify **`cap-nhat-lai-suat`**. Đổi tên thì tìm và thay 2 chuỗi này trong toàn repo.

1. **GitHub:** tạo kho công khai `tcb-ops` rồi đẩy nhánh `main`. Vào Settings → Pages: Source = nhánh `gh-pages` (nhánh này có sau bước 3).
2. **Apps Script (đồng bộ Docs):** vào script.google.com → Dự án mới → dán `DongBoDocs.gs` (và `appsscript.json` nếu bật hiển thị file kê khai).
   - Sửa `THU_MUC_ID` nếu muốn Docs nằm trong 1 thư mục riêng. Để trống thì Docs nằm ở My Drive.
   - Chọn hàm `thu` → Chạy → cho phép quyền.
   - Triển khai → Ứng dụng web: Thực thi với tư cách **Tôi**, Ai có quyền truy cập **Bất kỳ ai** → chép URL `…/exec`.
   - Dán URL đó vào 3 chỗ: `cong-cu/tu-dong/dong-bo-url.txt`, biến `DONG_BO` trong `cong-cu/app-cap-nhat/web/index.html` và trong `cong-cu/app-lai-suat/web/index.html`.
   - Lần chạy đầu, mỗi bài được tạo 1 file Docs mới. Từ lần sau, script chép đè vào đúng file đó, nên link không đổi và bản cũ vẫn xem được trong Lịch sử phiên bản.
   - Muốn dùng file Docs có sẵn: ghi `{"lai-suat-1": "<id Docs>", …}` vào `cong-cu/tu-dong/file-co-dinh.json`.
3. **Đăng app:** `bash cong-cu/dang-app/dang.sh cong-cu/app-cap-nhat/web .` và `bash cong-cu/dang-app/dang.sh cong-cu/app-lai-suat/web lai-suat`.
4. **Nút "Chạy cập nhật" (Netlify):**
   - Tạo fine-grained token: chỉ kho `tcb-ops`, quyền **Actions: Read and write**.
   - Vào app.netlify.com → Import từ GitHub → kho `tcb-ops`, nhánh `netlify`, tên `cap-nhat-lai-suat` → Environment variables: `GITHUB_TOKEN` = token vừa tạo → Deploy.
   - Không dán token vào chat hay vào repo.

## Lưu ý

- Lịch `schedule` của GitHub có thể trễ khi kho ít hoạt động. Kho không có commit trong 60 ngày thì GitHub tự tắt lịch, khi đó vào Actions bật lại.
- Bài lãi suất luôn ghi **ngày mai** (giờ VN). Các bài khác ghi theo ngày chọn trên app.
- Muốn bài khác cũng tự vào Docs sau khi chạy: thêm mã bài vào `TU_DONG_DOCS` trong `tu-dong-cap-nhat.yml`.
- Thêm bài mới: tạo `cong-cu/skill-cap-nhat-bai-tcb/cong-thuc/<mã>/`, rồi thêm mã vào `cong-cu/tu-dong/danh-sach.json`, `HOP_LE` trong `netlify/functions/chay.mjs` và `du-lieu.json` của app.
