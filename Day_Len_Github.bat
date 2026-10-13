@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo ===================================================================
echo   ĐANG ĐẨY MÃ NGUỒN VÀ BÁO CÁO BT6 LÊN GITHUB...
echo   Kho lưu trữ: https://github.com/phamngocbach05-debug/firebase-and-supbase
echo ===================================================================
echo.
git add .
git commit -m "Cap nhat ma nguon va bao cao BT6 Flutter Firebase Supabase"
git push -u origin main
echo.
echo ===================================================================
echo   ĐÃ HOÀN TẤT! Hãy vào https://github.com/phamngocbach05-debug/firebase-and-supbase
echo   để kiểm tra toàn bộ mã nguồn và báo cáo Bao_Cao_BT6_NopBai.md.
echo ===================================================================
pause
