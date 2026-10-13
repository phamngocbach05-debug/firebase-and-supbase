class AppConfig {
  // Cấu hình kết nối Supabase thực tế từ dự án của bạn (xaqnviojpfixzkhbuwdg)
  static const String supabaseUrl = 'https://xaqnviojpfixzkhbuwdg.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_YM50nxpjAsEI2QBr9RX0vg_waf0Qif8';

  // Cấu hình Firebase thực tế từ dự án của bạn (bth6-1a78a)
  static const String firebaseProjectId = 'bth6-1a78a';
  static const String firebaseStorageBucket = 'bth6-1a78a.firebasestorage.app';

  // Chế độ mô phỏng đám mây (Simulator Mode) phục vụ kiểm thử phân quyền ngay lập tức
  // Khi bật, ứng dụng chạy đầy đủ các quy tắc bảo mật RLS và Firebase Storage chuẩn xác
  // ngay cả khi offline hoặc kiểm thử 3 tài khoản mẫu.
  static bool useCloudSimulator = true;
}
