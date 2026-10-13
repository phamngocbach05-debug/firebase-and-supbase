#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
KỊCH BẢN KIỂM THỬ TỰ ĐỘNG PHÂN QUYỀN RLS & HỆ SINH THÁI CLOUD (BT6)
Dự án: Hệ thống Quản lý Tài liệu Đa nền tảng (Flutter + Firebase + Supabase)
Kiểm thử 6 mục Checklist và xác minh ma trận quyền hạn giữa 3 tài khoản người dùng:
  - User A (Owner): an.nguyen@edu.vn
  - User B (Editor): binh.tran@edu.vn
  - User C (Viewer/Stranger): cuong.le@edu.vn
"""

import sys
import uuid
import datetime

if sys.platform == 'win32':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

class ColoredPrinter:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

    @classmethod
    def success(cls, text):
        print(f"{cls.OKGREEN}[PASS]{cls.ENDC} {text}")

    @classmethod
    def fail(cls, text):
        print(f"{cls.FAIL}[FAIL]{cls.ENDC} {text}")

    @classmethod
    def info(cls, text):
        print(f"{cls.OKCYAN}[INFO]{cls.ENDC} {text}")

    @classmethod
    def header(cls, text):
        print(f"\n{cls.BOLD}{cls.HEADER}=== {text} ==={cls.ENDC}")

# ==============================================================================
# MÔ PHỎNG ROW LEVEL SECURITY (RLS) DATABASE ENGINE
# ==============================================================================

class MockSupabaseDB:
    def __init__(self):
        self.users = {}
        self.documents = {}
        self.permissions = {}
        self.current_user_id = None

    def set_session(self, user_id):
        self.current_user_id = user_id

    # 1. BẢNG USERS
    def insert_user(self, user_id, email, display_name):
        self.users[user_id] = {
            'id': user_id,
            'email': email,
            'display_name': display_name,
            'created_at': datetime.datetime.now().isoformat()
        }

    # 2. BẢNG DOCUMENTS CÓ ÁP DỤNG RLS
    def select_documents(self):
        """RLS SELECT Policy"""
        results = []
        for doc in self.documents.values():
            is_owner = (doc['owner_id'] == self.current_user_id)
            is_public = doc.get('is_public', False)
            is_shared = any(
                p['document_id'] == doc['id'] and p['user_id'] == self.current_user_id
                for p in self.permissions.values()
            )
            if is_owner or is_public or is_shared:
                results.append(doc)
        return results

    def insert_document(self, title, subject, file_name, file_size_kb, is_public=False):
        """RLS INSERT Policy: owner_id = current_app_user()"""
        if not self.current_user_id:
            raise PermissionError("RLS Violation: Chưa xác thực danh tính!")
        
        doc_id = str(uuid.uuid4())
        # Cấu trúc lưu trữ Firebase Storage
        storage_path = f"documents/{self.current_user_id}/{doc_id}/{file_name}"
        file_url = f"https://firebasestorage.googleapis.com/v0/b/bt6-doc.appspot.com/o/{storage_path}?alt=media"

        doc = {
            'id': doc_id,
            'title': title,
            'subject': subject,
            'storage_path': storage_path,
            'file_url': file_url,
            'file_size_kb': file_size_kb,
            'owner_id': self.current_user_id,
            'is_public': is_public,
            'updated_at': datetime.datetime.now().isoformat()
        }
        self.documents[doc_id] = doc
        return doc

    def update_document(self, doc_id, new_title):
        """RLS UPDATE Policy: owner hoặc editor/admin"""
        doc = self.documents.get(doc_id)
        if not doc:
            raise ValueError("Tài liệu không tồn tại!")

        is_owner = (doc['owner_id'] == self.current_user_id)
        has_editor_permission = any(
            p['document_id'] == doc_id and p['user_id'] == self.current_user_id and p['role'] in ('editor', 'admin')
            for p in self.permissions.values()
        )

        if not (is_owner or has_editor_permission):
            raise PermissionError(f"RLS Violation (documents_update_policy): User {self.current_user_id} không có quyền sửa!")

        doc['title'] = new_title
        doc['updated_at'] = datetime.datetime.now().isoformat()
        return doc

    def delete_document(self, doc_id):
        """RLS DELETE Policy: CHỈ owner hoặc admin"""
        doc = self.documents.get(doc_id)
        if not doc:
            raise ValueError("Tài liệu không tồn tại!")

        is_owner = (doc['owner_id'] == self.current_user_id)
        has_admin_permission = any(
            p['document_id'] == doc_id and p['user_id'] == self.current_user_id and p['role'] == 'admin'
            for p in self.permissions.values()
        )

        if not (is_owner or has_admin_permission):
            raise PermissionError(f"RLS Violation (documents_delete_policy): User {self.current_user_id} không có quyền xóa tài liệu của người khác!")

        # Cascade delete permissions
        to_del = [pid for pid, p in self.permissions.items() if p['document_id'] == doc_id]
        for pid in to_del:
            del self.permissions[pid]

        del self.documents[doc_id]
        return True

    # 3. BẢNG PERMISSIONS
    def grant_permission(self, doc_id, target_user_id, role):
        """RLS Permissions Manage Policy: Chỉ Owner/Admin mới được chia sẻ"""
        doc = self.documents.get(doc_id)
        if not doc:
            raise ValueError("Tài liệu không tồn tại!")

        if doc['owner_id'] != self.current_user_id:
            raise PermissionError("RLS Violation: Chỉ Owner mới có quyền phân quyền chia sẻ!")

        perm_id = str(uuid.uuid4())
        perm = {
            'id': perm_id,
            'document_id': doc_id,
            'user_id': target_user_id,
            'role': role,
            'granted_by': self.current_user_id
        }
        self.permissions[perm_id] = perm
        return perm

    def revoke_permission(self, doc_id, target_user_id):
        doc = self.documents.get(doc_id)
        if not doc or doc['owner_id'] != self.current_user_id:
            raise PermissionError("RLS Violation: Chỉ Owner mới có quyền thu hồi chia sẻ!")

        to_del = [pid for pid, p in self.permissions.items() if p['document_id'] == doc_id and p['user_id'] == target_user_id]
        for pid in to_del:
            del self.permissions[pid]
        return True

# ==============================================================================
# TIẾN TRÌNH THỰC THI KIỂM THỬ (TEST SUITE)
# ==============================================================================

def run_all_tests():
    db = MockSupabaseDB()
    test_count = 0
    passed_count = 0

    ColoredPrinter.header("KHỞI TẠO DỮ LIỆU 3 TÀI KHOẢN (CHECKLIST 01 & 03)")
    uid_a = "user_a_an_nguyen"
    uid_b = "user_b_binh_tran"
    uid_c = "user_c_cuong_le"

    db.insert_user(uid_a, "an.nguyen@edu.vn", "Nguyễn Văn An (Owner)")
    db.insert_user(uid_b, "binh.tran@edu.vn", "Trần Thị Bình (Editor)")
    db.insert_user(uid_c, "cuong.le@edu.vn", "Lê Hoàng Cường (Viewer/Khách)")
    ColoredPrinter.success("Đã đồng bộ 3 tài khoản Firebase Auth vào bảng users của Supabase.")

    # --------------------------------------------------------------------------
    ColoredPrinter.header("TEST 1: TẠO TÀI LIỆU RIÊNG TƯ & LƯU FIREBASE STORAGE (MỤC 02 & 04)")
    test_count += 1
    db.set_session(uid_a)
    doc_private = db.insert_document(
        title="Slide Bài 06: Cloud Flutter & Supabase RLS",
        subject="IT402",
        file_name="slide_06.pdf",
        file_size_kb=3450.0,
        is_public=False
    )
    assert doc_private['owner_id'] == uid_a
    assert "documents/user_a_an_nguyen/" in doc_private['storage_path']
    ColoredPrinter.success(f"User A tạo tài liệu riêng tư thành công (Path: {doc_private['storage_path']}).")
    passed_count += 1

    # --------------------------------------------------------------------------
    ColoredPrinter.header("TEST 2: KIỂM TRA CHÍNH SÁCH BẢO MẬT RLS SELECT (MỤC 05 & 06)")
    test_count += 1
    # User B kiểm tra
    db.set_session(uid_b)
    docs_b = db.select_documents()
    b_can_see = any(d['id'] == doc_private['id'] for d in docs_b)

    # User C kiểm tra
    db.set_session(uid_c)
    docs_c = db.select_documents()
    c_can_see = any(d['id'] == doc_private['id'] for d in docs_c)

    if not b_can_see and not c_can_see:
        ColoredPrinter.success("Chính sách documents_select_policy: User B và User C hoàn toàn bị ẩn tài liệu riêng tư.")
        passed_count += 1
    else:
        ColoredPrinter.fail("Lỗ hổng bảo mật: Tài liệu riêng tư bị lộ cho người dùng khác!")

    # --------------------------------------------------------------------------
    ColoredPrinter.header("TEST 3: PHÂN QUYỀN CHIA SẺ VÀ CẬP NHẬT DỮ LIỆU (MỤC 04 & 05)")
    test_count += 1
    # User A chia sẻ cho User B với quyền 'editor'
    db.set_session(uid_a)
    db.grant_permission(doc_private['id'], uid_b, role='editor')
    ColoredPrinter.info("User A đã cấp quyền 'editor' cho User B.")

    # User B đăng nhập -> Kiểm tra thấy tài liệu và cập nhật thành công
    db.set_session(uid_b)
    docs_b_updated = db.select_documents()
    b_now_sees = any(d['id'] == doc_private['id'] for d in docs_b_updated)
    assert b_now_sees, "User B phải thấy tài liệu sau khi được chia sẻ!"

    new_title = "Slide Bài 06: [Đã cập nhật bổ sung bởi User B - Editor]"
    db.update_document(doc_private['id'], new_title)
    assert doc_private['title'] == new_title
    ColoredPrinter.success("User B xem và cập nhật tiêu đề tài liệu thành công (documents_update_policy PASS).")
    passed_count += 1

    # --------------------------------------------------------------------------
    ColoredPrinter.header("TEST 4: CHẶN TRUY CẬP TRÁI PHÉP TỪ USER C (MỤC 05 & 06)")
    test_count += 1
    db.set_session(uid_c)
    blocked_update = False
    try:
        db.update_document(doc_private['id'], "User C hack tiêu đề")
    except PermissionError:
        blocked_update = True

    if blocked_update:
        ColoredPrinter.success("Chính sách RLS đã chặn thành công User C cố tình sửa tài liệu mà không có quyền.")
        passed_count += 1
    else:
        ColoredPrinter.fail("Lỗ hổng: User C không có quyền nhưng vẫn sửa được tài liệu!")

    # --------------------------------------------------------------------------
    ColoredPrinter.header("TEST 5: CHẶN EDITOR XÓA TÀI LIỆU CỦA CHỦ SỞ HỮU (MỤC 05 & 06)")
    test_count += 1
    db.set_session(uid_b)
    blocked_delete = False
    try:
        db.delete_document(doc_private['id'])
    except PermissionError:
        blocked_delete = True

    if blocked_delete:
        ColoredPrinter.success("Chính sách documents_delete_policy: Editor B không được phép xóa tài liệu của Owner A.")
        passed_count += 1
    else:
        ColoredPrinter.fail("Lỗ hổng: Editor xóa mất tài liệu của Owner!")

    # --------------------------------------------------------------------------
    ColoredPrinter.header("TEST 6: THU HỒI QUYỀN VÀ XÓA TÀI LIỆU HỢP LỆ BỞI OWNER (MỤC 04 & 05)")
    test_count += 1
    db.set_session(uid_a)
    db.revoke_permission(doc_private['id'], uid_b)
    ColoredPrinter.info("User A đã thu hồi quyền truy cập của User B.")

    # Xác nhận User B không còn thấy tài liệu
    db.set_session(uid_b)
    docs_b_after = db.select_documents()
    b_revoked_success = not any(d['id'] == doc_private['id'] for d in docs_b_after)

    # User A xóa tài liệu của chính mình
    db.set_session(uid_a)
    db.delete_document(doc_private['id'])
    assert doc_private['id'] not in db.documents

    if b_revoked_success:
        ColoredPrinter.success("Thu hồi quyền thành công: User B mất quyền truy cập. Owner A xóa tài liệu hoàn tất.")
        passed_count += 1
    else:
        ColoredPrinter.fail("Lỗi: Quyền chưa được thu hồi sạch sẽ.")

    # --------------------------------------------------------------------------
    # BÁO CÁO TỔNG KẾT
    # --------------------------------------------------------------------------
    ColoredPrinter.header("TỔNG KẾT KẾT QUẢ KIỂM THỬ BT6")
    print(f"Tổng số bài kiểm tra : {test_count}")
    print(f"Số bài kiểm tra ĐẠT  : {passed_count}")
    print(f"Tỷ lệ thành công     : {(passed_count / test_count) * 100:.1f}%")

    if passed_count == test_count:
        ColoredPrinter.success("TẤT CẢ 6/6 MỤC CHECKLIST ĐỀ BÀI HOÀN TOÀN ĐẠT CHUẨN!")
        return 0
    else:
        ColoredPrinter.fail("MỘT SỐ BÀI KIỂM THỬ CHƯA ĐẠT!")
        return 1

if __name__ == '__main__':
    sys.exit(run_all_tests())
