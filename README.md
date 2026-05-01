# Playlist Exam Hub — Toán Cá Chép 🐟

> **Mục tiêu:** Hệ thống phân phối đề thi tập trung. Học sinh mở 1 link → thấy danh sách đề → chọn → làm bài → nộp bài.

---

## Cấu Trúc Dự Án

```
List_Test_Web/
├── 01_Kho_De_Goc/          ← 7 file đề gốc (Source of Truth)
│   ├── 11_HKII_02.html       (123 KB)
│   ├── 11_HKII_03.html       (128 KB)
│   ├── 11_HKII_04.html       (127 KB)
│   ├── 11_HKII_05.html       (126 KB)
│   ├── 12_CKII_02.html       (147 KB)
│   ├── 12_HKII_02.html       (147 KB)
│   └── 12_THPTQG_07.html     (101 KB)
├── Pic/                     ← Logo đã tối ưu web
│   ├── logoleft.png           (10 KB — retina 2x)
│   └── logoright.png          (24 KB — retina 2x)
├── de/                      ← Output tự sinh bởi Robot (KHÔNG SỬA TAY)
├── index.html               ← Trang Playlist Hub chính (18 KB)
├── quan_ly_de_thi.csv       ← Cấu hình đề thi + mật khẩu
├── sync_playlist.ps1        ← Robot quét đề + build + push GitHub
├── Sync_Len_Web.bat         ← Nút bấm 1-click cho Tí
├── PROJECT_CONTEXT.md       ← Ngữ cảnh kỹ thuật cho AI
└── README.md                ← File này
```

---

## Trạng Thái Đề Thi (01/05/2026 - Tối)

| ID | Tên đề | Lớp | Mật khẩu |
|---|---|---|---|
| de_01 | Đề 07 - Thi thử THPTQG | 12 | 🔒 Có |
| de_03 | Đề 02 - Học kỳ II | 11 | 🔓 Mở |
| de_05 | Đề 03 - Học kỳ II | 11 | 🔒 Có |
| de_06 | Đề 04 - Học kỳ II | 11 | 🔒 Có |
| de_07 | Đề 05 - Học kỳ II | 11 | 🔒 Có |
| de_08 → de_16 | Đề 01 → Đề 10 - Học kỳ II | 12 | 🔒 Có |

*(Lưu ý: de_17 (Đề 02 - Cuối kỳ II) đã được ẩn)*

---

## Quy Trình Vận Hành

### Thêm đề mới
1. Tạo đề ở `Test_Web` → chạy workflow `/TaoHTML_BaiThi` (Hỗ trợ ném nhiều file vào 1 thư mục)
2. Click đúp **`Sync_Len_Web.bat`** → Robot tự quét, copy, đăng ký, push

### Đặt / đổi mật khẩu
1. Mở `quan_ly_de_thi.csv` → sửa cột `Mat_Khau`
2. **Ctrl + S** (BẮT BUỘC lưu trước!)
3. Click đúp **`Sync_Len_Web.bat`**

### Ẩn đề thi
1. `quan_ly_de_thi.csv` → đổi `Trang_Thai` thành `An`
2. **Ctrl + S** → Click đúp **`Sync_Len_Web.bat`**

---

## Báo Cáo Phiên Làm Việc — 01/05/2026

### Phiên Tối (Nâng cấp Auto-Discovery & UI)
1. **Bulk Exams Support**: Nâng cấp Robot `sync_playlist.ps1` để tự động quét và bóc tách hàng loạt đề thi trong cùng 1 thư mục (VD: `De_01.html` -> `De_10.html`).
2. **Dynamic Number Icons**: Tự động bóc tách số đề (01, 02...) từ tên file để làm icon vuông phong cách iOS thay vì dùng icon Sigma chung chung.
3. **Chuẩn hóa Encoding**: Đồng nhất toàn bộ tên đề thi về định dạng có dấu chuẩn (`Đề XX - Học kỳ II`), xử lý triệt để các lỗi hiển thị UTF-8 trên PowerShell.
4. **Deploy lô 9 đề mới**: Đồng bộ thành công Đề 01 đến Đề 10 (Lớp 12 Học kỳ II), gắn mật khẩu bảo vệ `12` và sắp xếp thứ tự hiển thị tuyến tính hoàn hảo.

### Phiên Chiều (Xây dựng nền móng)
1. **UI Overhaul**: Nền trắng, hero xanh #003B99 + chữ vàng #F7C800, xóa math-deco
2. **Logo Integration**: Thay chữ "Cá Chép" bằng `logoleft.png` + `logoright.png` (72px/88px retina)
3. **Tối ưu hiệu suất**: Logo giảm 637 KB → 34 KB (-95%)
4. **Safari Mobile Fix (3 vòng)**:
   - Đề không mật khẩu: dùng `<a>` tag thật (Safari không bao giờ chặn)
   - Đề có mật khẩu: pre-open tab synchronous trước `await sha256()`, redirect sau
   - Chống nháy: `touch-action:manipulation` + debounce 800ms + event delegation
5. **Mật khẩu SHA-256**: File đề đổi tên thành hash, client-side verify
6. **Auto-Discovery Robot**: Quét `Test_Web`, tự copy + đăng ký + build + push GitHub

---

## Lưu Ý Quan Trọng

- **Encoding UTF-8**: Mọi file CSV/HTML. Nếu mở bằng Excel, lưu lại sẽ đổi encoding → lỗi font.
- **Thư mục `de/`**: Tự sinh. KHÔNG sửa tay.
- **Ctrl + S trước bat**: Nếu không lưu CSV, Robot đọc bản cũ trên ổ cứng.
