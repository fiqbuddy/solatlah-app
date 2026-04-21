import 'package:flutter/material.dart';
import '../services/knowledge_service.dart';
import 'knowledge_detail_page.dart';

class KnowledgeBookmarksPage extends StatefulWidget {
  const KnowledgeBookmarksPage({super.key});

  @override
  State<KnowledgeBookmarksPage> createState() => _KnowledgeBookmarksPageState();
}

class _KnowledgeBookmarksPageState extends State<KnowledgeBookmarksPage> {
  final knowledgeService = KnowledgeService();
  List<Map<String, dynamic>> bookmarks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final data = await knowledgeService.getBookmarks();
    if (mounted)
      setState(() {
        bookmarks = data;
        isLoading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Tanda Buku',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : bookmarks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bookmark_border,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Tiada tanda buku lagi',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tekan ikon tanda buku pada mana-mana\nrujukan untuk menyimpannya di sini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, height: 1.5),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final item = bookmarks[index]['knowledge_base']
                        as Map<String, dynamic>;
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => KnowledgeDetailPage(item: item),
                        ),
                      ).then((_) => _loadBookmarks()),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.07),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    item['category'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF2E7D32),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.bookmark,
                                    color: Color(0xFF2E7D32), size: 18),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['question'] ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.verified,
                                    size: 14, color: Color(0xFF2E7D32)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    item['source'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF2E7D32),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.arrow_forward_ios,
                                    size: 12, color: Colors.grey),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
