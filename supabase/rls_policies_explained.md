# 🛡️ Giải Trình Cơ Chế Bảo Mật Row Level Security (RLS) Trên Supabase

Tài liệu này giải thích chi tiết các nguyên tắc thiết kế và hiện thực chính sách bảo mật tầng hàng (**Row Level Security - RLS**) trên Supabase cho bài tập **BT6 - Quản lý Tài liệu Đa nền tảng**.

---

## 1. Mục Tiêu Bảo Mật
Trong mô hình ứng dụng đám mây có phân quyền (Multi-tenant Document Management):
1. **Toàn vẹn dữ liệu (Data Integrity):** Không một người dùng nào có thể sửa đổi hoặc xóa tài liệu mà họ không sở hữu hoặc không được ủy quyền.
2. **Bảo mật truy cập (Confidentiality):** Tài liệu riêng tư (Private) chỉ người sở hữu và người được chia sẻ mới có thể thấy hoặc tải về. Tài liệu công khai (Public) mở cho tất cả.
3. **Phân quyền đa cấp (Role-Based Access Control - RBAC):**
   - **Owner (Chủ sở hữu):** Có toàn quyền (Xem, Sửa, Xóa, Cấp quyền, Thu hồi quyền).
   - **Editor (Người chỉnh sửa):** Được xem và cập nhật thông tin tài liệu; không được xóa tài liệu; không được phân quyền cho người khác.
   - **Viewer (Người xem):** Chỉ được xem siêu dữ liệu và tải file tài liệu.
   - **Stranger (Người ngoài):** Không thấy tài liệu nếu là Private.

---

## 2. Bảng Đối Chiếu Ma Trận Quyền Hạn (Permission Matrix)

| Hành Động | Owner | Editor (được cấp) | Viewer (được cấp) | Người khác (Private) | Người khác (Public) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **SELECT** (Xem danh sách / Chi tiết) | ✅ Có | ✅ Có | ✅ Có | ❌ Không | ✅ Có |
| **INSERT** (Tải lên tài liệu mới) | ✅ Có (của mình) | ✅ Có (của mình) | ✅ Có (của mình) | ✅ Có (của mình) | ✅ Có (của mình) |
| **UPDATE** (Sửa tiêu đề / mô tả / v.v.) | ✅ Có | ✅ Có | ❌ Không | ❌ Không | ❌ Không |
| **DELETE** (Xóa tài liệu khỏi hệ thống) | ✅ Có | ❌ Bị RLS chặn | ❌ Bị RLS chặn | ❌ Bị RLS chặn | ❌ Bị RLS chặn |
| **GRANT/REVOKE** (Chia sẻ / Thu hồi quyền) | ✅ Có | ❌ Bị RLS chặn | ❌ Bị RLS chặn | ❌ Bị RLS chặn | ❌ Bị RLS chặn |

---

## 3. Chi Tiết Các Chính Sách RLS Đã Cài Đặt

### A. Bảng `documents`
- **SELECT Policy (`documents_select_policy`):**
  ```sql
  owner_id = current_app_user()
  OR is_public = TRUE
  OR EXISTS (
      SELECT 1 FROM permissions p
      WHERE p.document_id = documents.id
      AND p.user_id = current_app_user()
  )
  ```
- **INSERT Policy (`documents_insert_policy`):**
  ```sql
  owner_id = current_app_user()
  ```
- **UPDATE Policy (`documents_update_policy`):**
  ```sql
  owner_id = current_app_user()
  OR EXISTS (
      SELECT 1 FROM permissions p
      WHERE p.document_id = documents.id
      AND p.user_id = current_app_user()
      AND p.role IN ('editor', 'admin')
  )
  ```
- **DELETE Policy (`documents_delete_policy`):**
  ```sql
  owner_id = current_app_user()
  OR EXISTS (
      SELECT 1 FROM permissions p
      WHERE p.document_id = documents.id
      AND p.user_id = current_app_user()
      AND p.role = 'admin'
  )
  ```

### B. Bảng `permissions`
- **SELECT Policy:** Người dùng chỉ thấy quyền của chính mình hoặc quyền trên tài liệu do mình sở hữu.
- **MANAGE Policy (INSERT, UPDATE, DELETE):** Chỉ chủ sở hữu tài liệu (`d.owner_id = current_app_user()`) hoặc admin tài liệu mới có quyền gán hoặc gỡ quyền chia sẻ.
