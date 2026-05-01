# PROJECT CONTEXT — PLAYLIST ĐỀ THI TƯƠNG TÁC (TOÁN CÁ CHÉP)
Môi trường: Thư mục gốc `List_Test_Web` | Ngày tạo: 01/05/2026
Trạng thái: 🟢 Production — Đang hoạt động trên GitHub Pages

---

## 1. MỤC TIÊU & DEFINITION OF DONE

**Dự án này là gì?**
`List_Test_Web` là hệ thống **phân phối đề thi** tập trung. Học sinh truy cập 1 URL → thấy danh sách đề → chọn đề → làm bài ngay.

**Mối quan hệ với `Test_Web`:**
- `Test_Web` = **Nhà máy sản xuất** → xuất ra các file `*_Unified.html` (đề thi tương tác).
- `List_Test_Web` = **Cửa hàng trưng bày** → Robot tự động copy, tổ chức thành Playlist.

```text
Test_Web (Sản xuất)          List_Test_Web (Phân phối)
┌─────────────────┐          ┌─────────────────────────┐
│ PDF → OCR → HTML│ ──robot──▶│ Playlist Hub + /de/     │ ──URL──▶ Học sinh
│ *_Unified.html  │          │ Auto-Discovery + SHA-256 │
└─────────────────┘          └─────────────────────────┘
```

**Dự án đã ĐẠT CHUẨN (01/05/2026):**
- [x] Trang Playlist Hub hoạt động mượt trên Mobile (Safari iOS đã fix).
- [x] Mở đề ở tab mới — không lazy-load trong iframe, tránh scroll conflict.
- [x] MathJax render đúng 100% công thức toán trong mọi đề.
- [x] JS tính điểm, đếm giờ hoạt động bình thường.
- [x] 7 đề thi trong 1 giao diện, tải trang Hub < 1 giây trên 4G.
- [x] Hệ thống mật khẩu SHA-256 cho đề thi bảo mật.
- [x] Robot Auto-Discovery tự quét → copy → build → push GitHub.

---

## 2. KIẾN TRÚC KỸ THUẬT (Đã triển khai)

### 2.1. Cấu trúc file

```text
List_Test_Web/
├── 01_Kho_De_Goc/          ← Source of Truth (7 file đề gốc)
│   ├── 11_HKII_02.html       (123 KB)
│   ├── 11_HKII_03.html       (128 KB)
│   ├── 11_HKII_04.html       (127 KB)
│   ├── 11_HKII_05.html       (126 KB)
│   ├── 12_CKII_02.html       (147 KB)
│   ├── 12_HKII_02.html       (147 KB)
│   └── 12_THPTQG_07.html     (101 KB)
├── Pic/                     ← Logo retina 2x (đã tối ưu)
│   ├── logoleft.png           (10 KB — hiển thị 72px)
│   └── logoright.png          (24 KB — hiển thị 88px)
├── de/                      ← Output BUILD tự sinh (KHÔNG SỬA TAY)
├── index.html               ← Trang Playlist Hub (18 KB)
├── quan_ly_de_thi.csv       ← Cấu hình metadata + mật khẩu đề thi
├── sync_playlist.ps1        ← Robot Auto-Discovery + Build + Push
├── Sync_Len_Web.bat         ← Nút 1-click cho Tí
├── PROJECT_CONTEXT.md       ← File này
└── README.md                ← Báo cáo + hướng dẫn vận hành
```

### 2.2. Luồng hoạt động

```text
[Tí tạo đề ở Test_Web]
       ↓
[Click Sync_Len_Web.bat]
       ↓
[Robot quét Test_Web → phát hiện _Unified.html mới]
       ↓
[Copy vào 01_Kho_De_Goc/ → thêm dòng CSV → build index.html]
       ↓
[Đề có mật khẩu? → SHA-256 hash → đổi tên file]
       ↓
[Git push → GitHub Pages → Live!]
```

### 2.3. Cách mở đề trên Mobile (Safari-safe)

| Loại đề | Kỹ thuật | Lý do |
|---|---|---|
| **Không mật khẩu** | `<a href="..." target="_blank">` (link HTML thật) | Safari KHÔNG BAO GIỜ chặn link thật |
| **Có mật khẩu** | `window.open('about:blank')` synchronous → `await sha256()` → redirect | Safari chỉ cho mở tab trong sync user gesture |

### 2.4. Hệ thống mật khẩu

- CSV: Cột `Mat_Khau` chứa plaintext (local only, không push lên git)
- Robot: Tính `SHA-256(mật_khẩu)` → đổi tên file thành `de/de_{hash}.html`
- Client: Nhập mật khẩu → tính hash → `fetch HEAD` kiểm tra file tồn tại
- **Không ai đọc được mật khẩu từ source code**

### 2.5. Thiết kế giao diện

| Thành phần | Giá trị |
|---|---|
| **Nền trang** | `#FFFFFF` (trắng) |
| **Hero** | Nền `#003B99` (xanh đậm), chữ `#F7C800` (vàng) |
| **Font display** | Unbounded (800 weight) |
| **Font body** | Manrope |
| **Logo trái** | `logoleft.png` — 72px |
| **Mascot phải** | `logoright.png` — 88px, animation float |
| **Hover đề thi** | Nền xanh đậm + chữ trắng |
| **Mobile** | `touch-action:manipulation`, debounce 800ms |

---

## 3. QUY TẮC KỸ THUẬT

| Quy tắc | Giải thích |
|---|---|
| **Mở tab mới** | Đề thi luôn mở ở tab mới (`_blank`), KHÔNG load trong iframe |
| **File đề self-contained** | Mỗi file `de_XX.html` chạy được độc lập (CSS/JS riêng) |
| **Không hardcode path** | Danh sách đề lấy từ mảng JS `EXAMS[]` trong `index.html` |
| **Mobile-First** | Giao diện Hub hoạt động trên 375px trở lên |
| **Encoding UTF-8** | Bắt buộc! Nếu sử dụng Excel mở CSV → encoding bị đổi → lỗi font |
| **Thư mục `de/` là auto-gen** | Robot tự sinh nội dung. KHÔNG BAO GIỜ sửa tay trong `de/` |

**KHÔNG được làm:**
- Không nhúng nội dung đề vào `index.html`.
- Không dùng `<iframe>` (gây scroll conflict trên mobile).
- Không dùng `window.open()` sau `await` (Safari chặn).
- Không sửa file trong thư mục `de/` (Robot sẽ ghi đè).

---

## 4. TRẠNG THÁI ĐỀ THI (Cập nhật: 01/05/2026 — 18:41)

| ID | Tên đề | Lớp | Dạng | Số câu | Thời gian | Mật khẩu |
|---|---|---|---|---|---|---|
| de_01 | Đề 07 — Thi thử THPTQG | 12 | thptqg | 22 | 90' | 🔒 Có |
| de_02 | Đề 02 — Cuối kỳ II | 12 | hk | 35 | 60' | 🔓 Mở |
| de_03 | Đề 02 — Học kỳ II | 11 | hk | 30 | 90' | 🔓 Mở |
| de_04 | Đề 02 — Cuối kỳ II | 12 | hk | 24 | 90' | 🔒 Có |
| de_05 | Đề 03 — Học kỳ II | 11 | hk | 24 | 90' | 🔒 Có |
| de_06 | Đề 04 — Học kỳ II | 11 | hk | 24 | 90' | 🔒 Có |
| de_07 | Đề 05 — Học kỳ II | 11 | hk | 24 | 90' | 🔒 Có |

---

## 5. QUY TRÌNH VẬN HÀNH CHO TÍ

### Thêm đề mới
1. Tạo đề ở `Test_Web` → workflow `/TaoHTML_BaiThi`
2. Click đúp `Sync_Len_Web.bat` → Robot tự xử lý → push GitHub

### Đặt / đổi mật khẩu
1. Mở `quan_ly_de_thi.csv` → sửa cột `Mat_Khau`
2. **Ctrl + S** (PHẢI lưu trước!!!)
3. Click đúp `Sync_Len_Web.bat`

### Ẩn đề thi
1. `quan_ly_de_thi.csv` → đổi `Trang_Thai` thành `An`
2. **Ctrl + S** → Click đúp `Sync_Len_Web.bat`

---

## 6. HOSTING

| Hạng mục | Giá trị |
|---|---|
| **Nền tảng** | GitHub Pages |
| **Repo** | `LopToanCaChep/toancachep-playlist` |
| **URL** | `https://loptcachep.github.io/toancachep-playlist/` |
| **Nhúng** | Embed trong Ghost CMS qua iframe |
| **Deploy** | Tự động qua `sync_playlist.ps1` (git push → live) |

---

## 7. LỊCH SỬ PHIÊN LÀM VIỆC

### 📌 Phiên 01/05/2026 (15 commits)
- UI overhaul: nền trắng, hero xanh/vàng, xóa math-deco
- Logo integration: `logoleft.png` + `logoright.png` (tối ưu 637→34 KB)
- Safari Mobile Fix: 3 vòng sửa lỗi popup blocking + scroll conflict + double-tap
- Hệ thống mật khẩu SHA-256 hoạt động
- Robot Auto-Discovery tự quét + build + push

---

## 8. TÔ ĐỌC FILE NÀY → LÀM GÌ

Nếu có request liên quan đến `List_Test_Web`, Tô tự kiểm tra:
1. ✅ **Mở tab mới** — Đề thi luôn mở ở tab mới, KHÔNG load trong iframe.
2. ✅ **Safari-safe** — Đề không mật khẩu dùng `<a>` tag thật. Đề mật khẩu dùng pre-open tab.
3. ✅ **File đề bất biến** — Copy từ `Test_Web`, KHÔNG sửa nội dung.
4. ✅ **Mobile-First** — Mọi component test trên 375px trước.
5. ✅ **UTF-8** — Encoding bắt buộc cho CSV/HTML.
6. ✅ **Thư mục `de/` tự sinh** — Robot quản lý, không sửa tay.
7. ✅ **Ctrl + S trước bat** — CSV phải lưu trước khi chạy Robot.
