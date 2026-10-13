# 🔥 Hướng Dẫn Thiết Lập Firebase & Google Sign-In Cho Flutter (BT6)

Tài liệu này cung cấp hướng dẫn từng bước để thiết lập và tích hợp Firebase Authentication (Google Sign-In) và Firebase Storage cho ứng dụng Flutter.

---

## 1. Thiết Lập Dự Án Firebase Console
1. Truy cập [Firebase Console](https://console.firebase.google.com/) và bấm **Add project**.
2. Đặt tên dự án: ví dụ `bt6-doc-manager`.
3. Bật hoặc tắt Google Analytics theo nhu cầu, sau đó bấm **Create project**.

---

## 2. Kích Hoạt Dịch Vụ Firebase Authentication & Google Sign-In
1. Tại menu bên trái, chọn **Build** -> **Authentication** -> bấm **Get started**.
2. Tại tab **Sign-in method**, chọn **Google**:
   - Bật công tắc **Enable**.
   - Điền **Project support email** của bạn.
   - Bấm **Save**.
3. (Dành cho Android): Cần lấy mã vân tay chứng chỉ SHA-1 của máy:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Sau đó sao chép chuỗi SHA-1 dán vào mục **Project Settings -> Your apps -> Android app -> Add fingerprint**.

---

## 3. Kích Hoạt & Cấu Hình Firebase Storage
1. Tại menu bên trái, chọn **Build** -> **Storage** -> bấm **Get started**.
2. Chọn **Start in production mode**, chọn vị trí máy chủ (Location, ví dụ `asia-southeast1` hoặc `us-central1`).
3. Chuyển sang tab **Rules**, dán nội dung từ file [storage.rules](file:///C:/Users/ADMIN/.gemini/antigravity/scratch/bt6/firebase/storage.rules) và bấm **Publish**.

---

## 4. Cấu Trúc Lưu Trữ Trên Firebase Storage
Ứng dụng tổ chức thư mục tài liệu vật lý theo chuẩn:
```text
gs://bt6-doc-manager.appspot.com/
└── documents/
    └── {user_id}/                   # Firebase UID của người tải lên
        └── {document_id}/           # UUID của tài liệu
            └── {file_name}          # Tên file gốc (ví dụ: slide_bai_06.pdf)
```

**Ưu điểm của cấu trúc này:**
- Cách ly hoàn toàn file giữa các người dùng (`user_id`).
- Mỗi tài liệu (`document_id`) có thư mục riêng, tránh ghi đè khi 2 tài liệu trùng tên file.
- Đường dẫn `storage_path` được lưu đồng bộ vào cột `storage_path` của bảng `documents` trên Supabase để tiện quản lý và dọn dẹp khi xóa tài liệu.
