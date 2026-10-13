import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../services/cloud_backend_service.dart';
import '../widgets/account_switcher_sheet.dart';
import '../widgets/document_card.dart';
import 'document_detail_screen.dart';
import 'edit_document_screen.dart';
import 'share_document_dialog.dart';
import 'testing_matrix_screen.dart';
import 'upload_document_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _service = CloudBackendService();
  late final TabController _tabController;
  final _searchController = TextEditingController();

  String _searchKeyword = '';
  String _selectedSubjectFilter = 'Tất cả';

  final List<String> _subjectFilters = [
    'Tất cả',
    'IT402',
    'CS205',
    'CS301',
    'CHUNG',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _service.addListener(_onServiceChanged);
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAccountSwitcher() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AccountSwitcherSheet(),
    );
  }

  Future<void> _handleDelete(StudyDocument doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa tài liệu'),
        content: Text('Bạn có chắc chắn muốn xóa "${doc.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _service.deleteDocument(doc.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa tài liệu thành công.'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _service.currentUser;

    if (currentUser == null) {
      return const LoginScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F4E79),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.cloud_done, size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Quản Lý Tài Liệu (BT6)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Nút mở kiểm thử 3 tài khoản tự động (Mục 06)
          IconButton(
            icon: const Icon(Icons.assignment_turned_in),
            tooltip: 'Kiểm thử 3 Tài khoản (Checklist Mục 06)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TestingMatrixScreen()),
              );
            },
          ),

          // Nút chuyển tài khoản nhanh
          InkWell(
            onTap: _showAccountSwitcher,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white24,
                    child: Text(
                      currentUser.displayName.substring(0, 1),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.folder_shared, size: 18), text: 'Của Tôi'),
            Tab(icon: Icon(Icons.people_alt, size: 18), text: 'Được Chia Sẻ'),
            Tab(icon: Icon(Icons.public, size: 18), text: 'Công Khai'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Banner hiển thị thông tin tài khoản đang đăng nhập
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF163753),
            child: Row(
              children: [
                const Icon(Icons.account_circle, size: 16, color: Colors.amber),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Đăng nhập: ${currentUser.displayName} (${currentUser.email})',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: _showAccountSwitcher,
                  child: const Text('Đổi tài khoản', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Thanh tìm kiếm (Search Bar) - Checklist Mục 04
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tiêu đề, môn học, mô tả...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1F4E79)),
                suffixIcon: _searchKeyword.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchKeyword = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onChanged: (val) {
                setState(() => _searchKeyword = val);
              },
            ),
          ),

          // Bộ lọc môn học
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _subjectFilters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final subj = _subjectFilters[index];
                final isSelected = _selectedSubjectFilter == subj;
                return ChoiceChip(
                  label: Text(subj, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  selected: isSelected,
                  selectedColor: const Color(0xFF1F4E79).withAlpha(38),
                  labelStyle: TextStyle(color: isSelected ? const Color(0xFF1F4E79) : Colors.black87),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedSubjectFilter = subj);
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 6),

          // Nội dung 3 Tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDocumentList('my'),
                _buildDocumentList('shared'),
                _buildDocumentList('public'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1F4E79),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.cloud_upload),
        label: const Text('Tải Lên Tài Liệu', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UploadDocumentScreen()),
          );
        },
      ),
    );
  }

  Widget _buildDocumentList(String categoryTab) {
    final docs = _service.getAccessibleDocuments(
      keyword: _searchKeyword,
      subjectFilter: _selectedSubjectFilter,
      categoryTab: categoryTab,
    );

    if (docs.isEmpty) {
      String emptyMessage;
      IconData emptyIcon;
      switch (categoryTab) {
        case 'my':
          emptyMessage = 'Bạn chưa tải lên tài liệu nào.\nNhấn nút "Tải Lên Tài Liệu" bên dưới để thêm mới!';
          emptyIcon = Icons.folder_open;
          break;
        case 'shared':
          emptyMessage = 'Chưa có tài liệu nào được người khác chia sẻ với bạn.\nHãy chuyển sang Tài khoản A để cấp quyền cho tài khoản này!';
          emptyIcon = Icons.group_off;
          break;
        case 'public':
        default:
          emptyMessage = 'Không có tài liệu công khai phù hợp với bộ lọc tìm kiếm.';
          emptyIcon = Icons.search_off;
          break;
      }

      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(emptyIcon, size: 54, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 6, bottom: 80),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        return DocumentCard(
          document: doc,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: doc)),
            );
          },
          onEdit: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditDocumentScreen(document: doc)),
            );
          },
          onDelete: () => _handleDelete(doc),
          onShare: () {
            showDialog(
              context: context,
              builder: (_) => ShareDocumentDialog(document: doc),
            );
          },
        );
      },
    );
  }
}
