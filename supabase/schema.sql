-- ============================================================================
-- DỰ ÁN QUẢN LÝ TÀI LIỆU ĐA NỀN TẢNG (FLUTTER + FIREBASE + SUPABASE) - BÀI TẬP 6 (BT6)
-- TẬP LỆNH KHỞI TẠO CƠ SỞ DỮ LIỆU VÀ CHÍNH SÁCH BẢO MẬT (ROW LEVEL SECURITY - RLS)
-- ============================================================================

-- BẬT CÁC EXTENSION CẦN THIẾT
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 1. THIẾT KẾ BẢNG DỮ LIỆU (CHECKLIST MỤC 03)
-- ============================================================================

-- XÓA BẢNG CŨ (NẾU ĐÃ TỒN TẠI ĐỂ TÁI KHỞI TẠO SẠCH SẼ)
DROP TABLE IF EXISTS permissions CASCADE;
DROP TABLE IF EXISTS documents CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ----------------------------------------------------------------------------
-- BẢNG 1: users (QUẢN LÝ DANH TÍNH NGƯỜI DÙNG TỪ HỆ THỐNG FIREBASE AUTH)
-- ----------------------------------------------------------------------------
CREATE TABLE users (
    id VARCHAR(128) PRIMARY KEY,             -- Ánh xạ trực tiếp từ Firebase Auth UID
    email VARCHAR(255) NOT NULL UNIQUE,     -- Địa chỉ Google Email
    display_name VARCHAR(255),               -- Tên hiển thị người dùng
    photo_url TEXT,                          -- Ảnh đại diện từ tài khoản Google
    created_at TIMESTAMPTZ DEFAULT NOW(),    -- Thời điểm tạo tài khoản
    last_sign_in_at TIMESTAMPTZ DEFAULT NOW()-- Thời điểm đăng nhập gần nhất
);

COMMENT ON TABLE users IS 'Bảng lưu trữ thông tin người dùng được đồng bộ từ Firebase Authentication';
COMMENT ON COLUMN users.id IS 'Firebase UID đóng vai trò định danh duy nhất của người dùng';

-- ----------------------------------------------------------------------------
-- BẢNG 2: documents (QUẢN LÝ THÔNG TIN SIÊU DỮ LIỆU CỦA TÀI LIỆU)
-- ----------------------------------------------------------------------------
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- Khóa chính UUIDv4 duy nhất
    title VARCHAR(255) NOT NULL,                   -- Tiêu đề tài liệu
    description TEXT,                              -- Mô tả tóm tắt nội dung
    subject VARCHAR(100) NOT NULL,                 -- Môn học (CS301, IT402, CS205,...)
    file_url TEXT NOT NULL,                        -- URL tải file vật lý từ Firebase Storage
    storage_path TEXT NOT NULL,                    -- Đường dẫn file trên Firebase Storage bucket
    file_size_kb NUMERIC(12, 2) DEFAULT 0,         -- Dung lượng tệp tin (KB)
    file_type VARCHAR(50) NOT NULL,                -- Phân loại: pdf, docx, pptx, zip, image,...
    owner_id VARCHAR(128) NOT NULL REFERENCES users(id) ON DELETE CASCADE, -- Khóa ngoại trỏ đến chủ sở hữu
    is_public BOOLEAN NOT NULL DEFAULT FALSE,      -- Trạng thái: Công khai (TRUE) hoặc Riêng tư (FALSE)
    created_at TIMESTAMPTZ DEFAULT NOW(),          -- Thời điểm tạo
    updated_at TIMESTAMPTZ DEFAULT NOW()           -- Thời điểm cập nhật lần cuối
);

COMMENT ON TABLE documents IS 'Bảng quản lý siêu dữ liệu tài liệu học tập kết nối Firebase Storage';
COMMENT ON COLUMN documents.storage_path IS 'Đường dẫn phân cấp trên Firebase Storage dạng documents/{user_id}/{doc_id}/{filename}';

-- ----------------------------------------------------------------------------
-- BẢNG 3: permissions (QUẢN LÝ PHÂN QUYỀN TRUY CẬP VÀ CHIA SẺ TÀI LIỆU)
-- ----------------------------------------------------------------------------
CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- Khóa chính định danh phân quyền
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    user_id VARCHAR(128) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL CHECK (role IN ('viewer', 'editor', 'admin')), 
    -- viewer: Chỉ đọc và tải file
    -- editor: Được quyền cập nhật thông tin tài liệu
    -- admin: Toàn quyền quản trị tài liệu và chia sẻ
    granted_by VARCHAR(128) NOT NULL REFERENCES users(id), -- Người đã cấp quyền
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_document_user_permission UNIQUE(document_id, user_id)
);

COMMENT ON TABLE permissions IS 'Bảng định nghĩa quyền truy cập chia sẻ an toàn giữa các tài khoản';

-- ----------------------------------------------------------------------------
-- TẠO CÁC CHỈ MỤC (INDEXES) TỐI ƯU HÓA HIỆU NĂNG TÌM KIẾM VÀ TRUY VẤN
-- ----------------------------------------------------------------------------
CREATE INDEX idx_documents_owner_id ON documents(owner_id);
CREATE INDEX idx_documents_is_public ON documents(is_public);
CREATE INDEX idx_documents_subject ON documents(subject);
CREATE INDEX idx_documents_title ON documents USING gin(to_tsvector('vietnamese', title));
CREATE INDEX idx_permissions_doc_user ON permissions(document_id, user_id);
CREATE INDEX idx_permissions_user_id ON permissions(user_id);

-- TRIGGER TỰ ĐỘNG CẬP NHẬT updated_at KHI BẢNG documents THAY ĐỔI
CREATE OR REPLACE FUNCTION update_timestamp_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_documents_timestamp
BEFORE UPDATE ON documents
FOR EACH ROW
EXECUTE FUNCTION update_timestamp_column();

-- ============================================================================
-- 2. THIẾT LẬP CHÍNH SÁCH BẢO MẬT ROW LEVEL SECURITY (RLS) (CHECKLIST MỤC 05)
-- ============================================================================

-- BẬT TÍNH NĂNG RLS TRÊN TẤT CẢ CÁC BẢNG QUAN TRỌNG
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE permissions ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------------------
-- HÀM TIỆN ÍCH LẤY USER ID HIỆN TẠI (HỖ TRỢ CẢ SUPABASE AUTH & FIREBASE JWT/HEADER)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION current_app_user() 
RETURNS VARCHAR AS $$
BEGIN
    -- Kiểm tra nếu có custom header từ request hoặc fallback về auth.uid()
    RETURN COALESCE(
        current_setting('request.jwt.claim.sub', true),
        current_setting('request.headers', true)::json->>'x-firebase-uid',
        auth.uid()::text
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- ----------------------------------------------------------------------------
-- A. CHÍNH SÁCH BẢO MẬT TRÊN BẢNG USERS
-- ----------------------------------------------------------------------------
-- 1. Mọi người dùng đã đăng nhập đều có thể xem danh sách users để phục vụ tính năng chia sẻ
CREATE POLICY "users_select_authenticated"
ON users FOR SELECT
USING (true);

-- 2. Người dùng chỉ được sửa đổi thông tin cá nhân của chính mình
CREATE POLICY "users_update_own"
ON users FOR UPDATE
USING (id = current_app_user())
WITH CHECK (id = current_app_user());

-- 3. Cho phép hệ thống ghi nhận tài khoản mới khi đăng nhập lần đầu
CREATE POLICY "users_insert_any"
ON users FOR INSERT
WITH CHECK (true);

-- ----------------------------------------------------------------------------
-- B. CHÍNH SÁCH BẢO MẬT TRÊN BẢNG DOCUMENTS
-- ----------------------------------------------------------------------------

-- 1. SELECT: Người dùng được xem tài liệu NẾU:
--    - Là chủ sở hữu (owner_id = current_app_user())
--    - HOẶC tài liệu có trạng thái Công khai (is_public = TRUE)
--    - HOẶC được cấp quyền truy cập trong bảng permissions (viewer/editor/admin)
CREATE POLICY "documents_select_policy"
ON documents FOR SELECT
USING (
    owner_id = current_app_user()
    OR is_public = TRUE
    OR EXISTS (
        SELECT 1 FROM permissions p
        WHERE p.document_id = documents.id
        AND p.user_id = current_app_user()
    )
);

-- 2. INSERT: Chỉ cho phép người dùng tạo tài liệu mang tên chính họ (owner_id = current_app_user)
CREATE POLICY "documents_insert_policy"
ON documents FOR INSERT
WITH CHECK (
    owner_id = current_app_user()
);

-- 3. UPDATE: Người dùng chỉ được phép sửa thông tin tài liệu NẾU:
--    - Là chủ sở hữu (owner_id = current_app_user())
--    - HOẶC được cấp quyền 'editor' hoặc 'admin' trong bảng permissions
CREATE POLICY "documents_update_policy"
ON documents FOR UPDATE
USING (
    owner_id = current_app_user()
    OR EXISTS (
        SELECT 1 FROM permissions p
        WHERE p.document_id = documents.id
        AND p.user_id = current_app_user()
        AND p.role IN ('editor', 'admin')
    )
)
WITH CHECK (
    owner_id = current_app_user()
    OR EXISTS (
        SELECT 1 FROM permissions p
        WHERE p.document_id = documents.id
        AND p.user_id = current_app_user()
        AND p.role IN ('editor', 'admin')
    )
);

-- 4. DELETE: Chỉ chủ sở hữu (hoặc người có quyền 'admin') mới có quyền xóa tài liệu
CREATE POLICY "documents_delete_policy"
ON documents FOR DELETE
USING (
    owner_id = current_app_user()
    OR EXISTS (
        SELECT 1 FROM permissions p
        WHERE p.document_id = documents.id
        AND p.user_id = current_app_user()
        AND p.role = 'admin'
    )
);

-- ----------------------------------------------------------------------------
-- C. CHÍNH SÁCH BẢO MẬT TRÊN BẢNG PERMISSIONS
-- ----------------------------------------------------------------------------

-- 1. SELECT: Người dùng được xem bản ghi quyền NẾU:
--    - Bản ghi quyền đó thuộc về chính họ (user_id = current_app_user())
--    - HOẶC họ là người cấp quyền (granted_by = current_app_user())
--    - HOẶC họ là chủ sở hữu của tài liệu liên quan
CREATE POLICY "permissions_select_policy"
ON permissions FOR SELECT
USING (
    user_id = current_app_user()
    OR granted_by = current_app_user()
    OR EXISTS (
        SELECT 1 FROM documents d
        WHERE d.id = permissions.document_id
        AND d.owner_id = current_app_user()
    )
);

-- 2. INSERT/UPDATE/DELETE: CHỈ chủ sở hữu tài liệu (hoặc admin tài liệu) mới được phân quyền
CREATE POLICY "permissions_manage_policy"
ON permissions FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM documents d
        WHERE d.id = permissions.document_id
        AND (
            d.owner_id = current_app_user()
            OR EXISTS (
                SELECT 1 FROM permissions p_admin
                WHERE p_admin.document_id = d.id
                AND p_admin.user_id = current_app_user()
                AND p_admin.role = 'admin'
            )
        )
    )
);

-- ============================================================================
-- 3. DỮ LIỆU MẪU KIỂM THỬ (SEED DATA CHO 3 TÀI KHOẢN THEO CHECKLIST MỤC 06)
-- ============================================================================

-- TẠO 3 TÀI KHOẢN KIỂM THỬ THỰC TẾ
INSERT INTO users (id, email, display_name, photo_url) VALUES
('uid_user_a', 'an.nguyen@edu.vn', 'Nguyễn Văn An (Giảng viên / Owner)', 'https://api.dicebear.com/7.x/avataaars/svg?seed=AnNguyen'),
('uid_user_b', 'binh.tran@edu.vn', 'Trần Thị Bình (Sinh viên / Editor)', 'https://api.dicebear.com/7.x/avataaars/svg?seed=BinhTran'),
('uid_user_c', 'cuong.le@edu.vn', 'Lê Hoàng Cường (Khách / Viewer)', 'https://api.dicebear.com/7.x/avataaars/svg?seed=CuongLe')
ON CONFLICT (id) DO UPDATE 
SET email = EXCLUDED.email, display_name = EXCLUDED.display_name, photo_url = EXCLUDED.photo_url;

-- TẠO DỮ LIỆU TÀI LIỆU CỦA USER A (GIẢNG VIÊN NGUYỄN VĂN AN)
INSERT INTO documents (id, title, description, subject, file_url, storage_path, file_size_kb, file_type, owner_id, is_public) VALUES
('11111111-1111-1111-1111-111111111111', 
 'Slide Bài 06: Tích hợp Đám mây Flutter, Firebase và Supabase', 
 'Bộ bài giảng chi tiết về kiến trúc phân tầng, phân quyền RLS và bảo mật đa tài khoản.', 
 'IT402 - Phát triển Ứng dụng Di động', 
 'https://firebasestorage.googleapis.com/v0/b/bt6-doc-manager.appspot.com/o/documents%2Fuid_user_a%2Fslide_bai_06.pdf?alt=media', 
 'documents/uid_user_a/11111111-1111-1111-1111-111111111111/slide_bai_06.pdf', 
 4250.00, 'pdf', 'uid_user_a', FALSE),

('22222222-2222-2222-2222-222222222222', 
 'Đề thi Tham khảo và Hướng dẫn Đáp án Cơ sở Dữ liệu Nâng cao', 
 'Tài liệu ôn tập toàn diện kèm bài giải mẫu cấu trúc truy vấn SQL và RLS Policies.', 
 'CS205 - Cơ sở Dữ liệu Nâng cao', 
 'https://firebasestorage.googleapis.com/v0/b/bt6-doc-manager.appspot.com/o/documents%2Fuid_user_a%2Fde_thi_cs205.docx?alt=media', 
 'documents/uid_user_a/22222222-2222-2222-2222-222222222222/de_thi_cs205.docx', 
 1820.50, 'docx', 'uid_user_a', FALSE),

('33333333-3333-3333-3333-333333333333', 
 'Quy định Chuẩn Đầu Ra & Hướng dẫn Làm Đồ án Môn học', 
 'Tài liệu công khai cho toàn thể sinh viên và cán bộ giảng viên tra cứu tự do.', 
 'CHUNG - Quy định Học vụ', 
 'https://firebasestorage.googleapis.com/v0/b/bt6-doc-manager.appspot.com/o/documents%2Fuid_user_a%2Fquy_dinh_do_an.pdf?alt=media', 
 'documents/uid_user_a/33333333-3333-3333-3333-333333333333/quy_dinh_do_an.pdf', 
 950.00, 'pdf', 'uid_user_a', TRUE)
ON CONFLICT (id) DO NOTHING;

-- TẠO QUYỀN CHIA SẺ TỪ USER A CHO USER B VÀ USER C
-- 1. User A chia sẻ tài liệu Slide Bài 06 cho User B với quyền 'editor' (Được phép sửa)
INSERT INTO permissions (document_id, user_id, role, granted_by) VALUES
('11111111-1111-1111-1111-111111111111', 'uid_user_b', 'editor', 'uid_user_a')
ON CONFLICT (document_id, user_id) DO UPDATE SET role = EXCLUDED.role;

-- 2. User A chia sẻ tài liệu Đề thi CS205 cho User B với quyền 'viewer' (Chỉ đọc)
INSERT INTO permissions (document_id, user_id, role, granted_by) VALUES
('22222222-2222-2222-2222-222222222222', 'uid_user_b', 'viewer', 'uid_user_a')
ON CONFLICT (document_id, user_id) DO UPDATE SET role = EXCLUDED.role;

-- GHI CHÚ: User C hiện tại KHÔNG được chia sẻ bất kỳ tài liệu riêng tư nào.
-- User C chỉ xem được tài liệu công khai ('33333333-3333-3333-3333-333333333333').
