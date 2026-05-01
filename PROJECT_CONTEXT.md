# PROJECT CONTEXT — PLAYLIST ĐỀ THI TƯƠNG TÁC (TOÁN CÁ CHÉP)
Môi trường: Thư mục gốc `List_Test_Web` | Ngày tạo: 01/05/2026
Trạng thái: 🔵 Mới khởi tạo — Đang phân tích phương án

---

## 1. MỤC TIÊU & DEFINITION OF DONE

**Dự án này là gì?**
`List_Test_Web` là hệ thống **phân phối đề thi** tập trung. Thay vì gửi link lẻ từng bài cho học sinh, dự án này tạo ra **một giao diện Playlist duy nhất** — nơi học sinh truy cập 1 URL → thấy danh sách đề → chọn đề → làm bài ngay.

**Mối quan hệ với `Test_Web`:**
- `Test_Web` = **Nhà máy sản xuất** → xuất ra các file `*_Unified.html` (đề thi tương tác).
- `List_Test_Web` = **Cửa hàng trưng bày** → lấy các file HTML đã sản xuất xong, tổ chức thành Playlist cho học sinh truy cập.

```text
Test_Web (Sản xuất)          List_Test_Web (Phân phối)
┌─────────────────┐          ┌─────────────────────┐
│ PDF → OCR → HTML│ ──copy──▶│ Playlist Hub + /de/  │ ──URL──▶ Học sinh
│ *_Unified.html  │          │ lazy-load từng đề    │
└─────────────────┘          └─────────────────────┘
```

**Dự án này ĐẠT CHUẨN khi:**
- [ ] Có 1 trang Playlist Hub hoạt động mượt trên Mobile.
- [ ] Lazy-load thành công — chỉ tải đề khi học sinh chọn, không load hết 10 đề cùng lúc.
- [ ] MathJax render đúng 100% công thức toán trong mọi đề.
- [ ] JS tính điểm, đếm giờ, nộp bài về Google Sheets hoạt động bình thường trong môi trường Playlist.
- [ ] Đạt target: **10 đề thi** trong 1 giao diện, tải trang Hub < 2 giây trên 4G.

**Thành công = khi nào?**
> Tí gửi cho học sinh **1 link duy nhất**. Học sinh mở → thấy 10 đề xếp đẹp → chọn đề → làm bài → nộp bài. Không cần tải app, không cần đăng nhập, không cần hỏi "thầy ơi link đề mấy?".

---

## 2. BỐI CẢNH & BÀI TOÁN GỐC

### 2.1. Vấn đề hiện tại
| Vấn đề | Chi tiết |
|---|---|
| **Phân phối lẻ tẻ** | Mỗi đề thi = 1 file HTML riêng, gửi qua Zalo/link riêng → học sinh hay lạc link, quên |
| **Ghost CMS hạn chế** | Nền tảng web Toán Cá Chép chạy trên Ghost → không tách được nhiều post đề thi riêng biệt dễ dàng |
| **File HTML nặng** | Mỗi đề ~100-150 KB, 1 đề ngoại lệ tới 6.3 MB → không nhúng hết vào 1 page được |

### 2.2. Hai phương án đã cân nhắc

#### ❌ Phương án A: Tạo thư mục riêng trên Ghost (Dynamic Routing)
- **Cách làm:** Sửa `routes.yaml` → Collection `/de-thi/` → gán Internal Tag `#de-thi` → mỗi đề = 1 post.
- **Lý do loại:**
  - Ghost HTML Card có thể "nuốt" hoặc modify HTML khi save → **phá vỡ cấu trúc bài thi**.
  - MathJax + JS tính điểm dễ conflict với Ghost theme.
  - Mỗi đề phải copy-paste HTML thủ công vào editor → **ngược lại mục tiêu tự động hóa**.
  - Khó tích hợp vào Pipeline Python hiện có.

#### ✅ Phương án B+: Playlist HTML Standalone (Lazy-Load)
- **Cách làm:** 1 file Hub HTML nhẹ + thư mục `/de/` chứa từng file đề → lazy-load khi chọn.
- **Lý do chọn:**
  - Toàn quyền kiểm soát UI (dùng Design System "Cá Chép" sẵn).
  - Đã có kinh nghiệm với `toan11-playlist.html` & `toan12-playlist.html`.
  - Pipeline Python sinh file trực tiếp → tự động hóa hoàn toàn.
  - MathJax đã chạy ổn, không lo conflict.

---

## 3. KIẾN TRÚC KỸ THUẬT (Phương án B+)

### 3.1. Cấu trúc file

```text
List_Test_Web/
├── PROJECT_CONTEXT.md          ← File này
├── index.html                  ← Trang Playlist Hub (~50 KB)
│                                  - Danh sách đề thi (metadata)
│                                  - CSS/JS skeleton + lazy-load logic
│                                  - KHÔNG chứa nội dung đề
├── de/                         ← Thư mục chứa từng đề thi riêng
│   ├── de_01.html              ← Copy từ Test_Web/*/03_Outputs/
│   ├── de_02.html
│   ├── ...
│   └── de_10.html
└── assets/                     ← Tài nguyên dùng chung (nếu cần)
    ├── css/
    └── img/
```

### 3.2. Luồng hoạt động

```text
Học sinh mở URL
      ↓
[1] Tải index.html (~50 KB) ──▶ Hiện Danh sách 10 đề
      ↓
[2] Click chọn "Đề 03"
      ↓
[3] JS gọi fetch('./de/de_03.html') ──▶ Tải ~100-150 KB
      ↓
[4] Inject HTML vào DOM slot ──▶ MathJax render ──▶ Hiển thị đề
      ↓
[5] Học sinh làm bài ──▶ Nộp bài ──▶ Google Sheets
      ↓
[6] Click "Quay lại" ──▶ Unload đề 03 (giải phóng RAM) ──▶ Về danh sách
```

### 3.3. Quy tắc kỹ thuật

| Quy tắc | Giải thích |
|---|---|
| **Lazy-load bắt buộc** | KHÔNG BAO GIỜ nhúng toàn bộ nội dung 10 đề vào 1 file HTML |
| **1 đề tại 1 thời điểm** | Khi chuyển đề, unload đề cũ khỏi DOM trước khi load đề mới |
| **File đề phải self-contained** | Mỗi file `de_XX.html` phải chạy được độc lập (có CSS/JS riêng) |
| **Không hardcode path** | Danh sách đề lấy từ mảng JS config, không gắn cứng trong HTML |
| **Mobile-First** | Giao diện Hub phải hoạt động tốt trên màn hình 375px trở lên |

### 3.4. Dung lượng ước tính

| Thành phần | Dung lượng | Ghi chú |
|---|---|---|
| `index.html` (Hub) | ~50 KB | Chỉ metadata + UI skeleton |
| Mỗi file đề | ~100-150 KB | Trung bình, không tính ảnh inline |
| Tổng 10 đề | ~1-1.5 MB | NHƯNG chỉ load 1 đề/lần (~150 KB) |
| MathJax CDN | ~0 KB local | Load từ CDN, browser cache |

> ⚠️ **Cảnh báo:** File `THTPQG01_Unified.html` từ `Test_Web` nặng **6.3 MB** (nghi chứa ảnh base64 inline). CẦN tối ưu (tách ảnh ra file riêng) trước khi đưa vào thư mục `de/`.

---

## 4. NGUYÊN TẮC (khi phải trade-off)

*(Thừa hưởng từ `Test_Web`, bổ sung thêm cho Playlist)*

1. **Tốc độ tải > Giao diện đẹp:** Playlist Hub phải tải < 2 giây. Nếu animation làm chậm → bỏ animation.
2. **Bảo toàn tính Học thuật 100%:** File đề copy từ `Test_Web` phải giữ nguyên si — không sửa, không rút gọn.
3. **Mobile-First:** 80%+ học sinh dùng điện thoại → mọi quyết định UI phải ưu tiên Mobile.
4. **Cô lập hoàn toàn:** CSS/JS của Playlist Hub KHÔNG ĐƯỢC ảnh hưởng tới CSS/JS bên trong file đề.

**KHÔNG được làm:**
- Không nhúng nội dung đề trực tiếp vào `index.html`.
- Không dùng `<iframe>` (nặng, khó responsive, SEO kém).
- Không hardcode đường dẫn file giữa `List_Test_Web` và `Test_Web`.

---

## 5. HOSTING & TRIỂN KHAI

### 5.1. Phương án hosting (cần quyết định)

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| **Ghost Custom Page** | Cùng domain Toán Cá Chép | Hạn chế upload static file |
| **GitHub Pages** | Miễn phí, deploy tự động | Domain khác (trừ khi custom domain) |
| **Netlify** | Miễn phí, CI/CD sẵn, nhanh | Domain khác |
| **Upload static lên Ghost** | Cùng domain, đơn giản | Cần zip & upload qua Admin |

> 💡 **Đề xuất:** Bắt đầu bằng GitHub Pages để prototype nhanh, sau đó migrate lên cùng domain Ghost nếu cần.

### 5.2. Quy trình cập nhật đề mới

```text
(1) Sản xuất đề mới ở Test_Web (Pipeline /TaoHTML_BaiThi)
        ↓
(2) Copy file *_Unified.html vào List_Test_Web/de/ → đổi tên thành de_XX.html
        ↓
(3) Cập nhật mảng JS config trong index.html (thêm metadata đề mới)
        ↓
(4) Deploy / Upload lên hosting
```

---

## 6. TODO — VIỆC CẦN LÀM

### Phase 1: Prototype (Ưu tiên cao)
- [ ] Thiết kế UI trang Playlist Hub (wireframe/mockup).
- [ ] Code `index.html` với lazy-load logic cơ bản.
- [ ] Copy 3 đề mẫu từ `Test_Web` vào `de/` để test.
- [ ] Test performance trên điện thoại (MathJax render, JS tính điểm).

### Phase 2: Hoàn thiện
- [ ] Tối ưu file `THTPQG01_Unified.html` (tách ảnh base64).
- [ ] Thêm tính năng: progress tracking, ghi nhớ đề đã làm.
- [ ] Responsive test trên nhiều thiết bị.
- [ ] Quyết định hosting cuối cùng.

### Phase 3: Scale lên 10 đề
- [ ] Copy đủ 10 đề, chuẩn hóa tên file.
- [ ] Cập nhật Pipeline Python để output thẳng vào `de/`.
- [ ] Deploy chính thức, gửi link cho học sinh.

---

## 7. TÔ ĐỌC FILE NÀY → LÀM GÌ

Nếu có request liên quan đến `List_Test_Web`, Tô tự kiểm tra:
1. ✅ **Lazy-load bắt buộc** — Không bao giờ nhúng toàn bộ nội dung đề vào 1 file.
2. ✅ **Cô lập CSS/JS** — Code Playlist Hub không được conflict với code bên trong file đề.
3. ✅ **File đề là bất biến** — Copy từ `Test_Web` về, KHÔNG sửa nội dung.
4. ✅ **Mobile-First** — Mọi component phải test trên 375px trước.
5. ✅ **Kiểm tra dung lượng** — Bất kỳ file đề nào > 500 KB cần báo cảnh báo để tối ưu trước.
