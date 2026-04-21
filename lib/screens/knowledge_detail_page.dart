import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/knowledge_service.dart';

class KnowledgeDetailPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const KnowledgeDetailPage({super.key, required this.item});

  @override
  State<KnowledgeDetailPage> createState() => _KnowledgeDetailPageState();
}

class _KnowledgeDetailPageState extends State<KnowledgeDetailPage> {
  final knowledgeService = KnowledgeService();
  bool _isBookmarked = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkBookmark();
  }

  Future<void> _checkBookmark() async {
    if (widget.item['id'] == null) {
      setState(() => _isLoading = false);
      return;
    }
    final bookmarked = await knowledgeService.isBookmarked(widget.item['id']);
    if (mounted)
      setState(() {
        _isBookmarked = bookmarked;
        _isLoading = false;
      });
  }

  Future<void> _toggleBookmark() async {
    if (widget.item['id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Simpan carian dahulu untuk menanda buku.'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      return;
    }
    await knowledgeService.toggleBookmark(widget.item['id']);
    setState(() => _isBookmarked = !_isBookmarked);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_isBookmarked ? 'Ditanda buku!' : 'Tanda buku dibuang.'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.item['category'] ?? 'Rujukan',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(
                _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: Colors.white,
              ),
              onPressed: _toggleBookmark,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category badges
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.item['category'] ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                if (widget.item['subcategory'] != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.item['subcategory'],
                      style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              widget.item['title'] ?? '',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            // Question card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.help_outline, color: Colors.white70, size: 16),
                      SizedBox(width: 6),
                      Text('Soalan',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.item['question'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Answer card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.menu_book, color: Color(0xFF2E7D32), size: 16),
                      SizedBox(width: 6),
                      Text('Jawapan',
                          style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  MarkdownBody(
                    data: widget.item['answer'] ?? '',
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 14,
                        height: 1.8,
                        color: Color(0xFF2D2D2D),
                      ),
                      strong: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                      listBullet: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mazhab badge
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFB300)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school, color: Color(0xFFFFB300), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Mazhab: ${widget.item['mazhab'] ?? 'Syafi\'i'}',
                    style: const TextStyle(
                      color: Color(0xFF795500),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Source card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified,
                      color: Color(0xFF2E7D32), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sumber Rujukan',
                            style: TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          widget.item['source'] ?? '',
                          style: const TextStyle(
                            color: Color(0xFF1B5E20),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.item['source_url'] != null)
                    GestureDetector(
                      onTap: () async {
                        String urlString = '';
                        final source =
                            (widget.item['source'] ?? '').toLowerCase();
                        if (source.contains('jakim') ||
                            source.contains('e-fatwa')) {
                          urlString = 'https://efatwa.muftiwp.gov.my';
                        } else if (source.contains('mufti wilayah') ||
                            source.contains('muftiwp')) {
                          urlString = 'https://muftiwp.gov.my';
                        } else if (source.contains('islam.gov')) {
                          urlString = 'https://www.islam.gov.my';
                        } else {
                          urlString = 'https://efatwa.muftiwp.gov.my';
                        }
                        try {
                          final url = Uri.parse(urlString);
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        } catch (e) {
                          debugPrint('URL launch error: $e');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Lawati',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Maklumat ini adalah rujukan umum. Untuk isu khusus, sila berunding dengan ulama atau mufti yang berkelayakan.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
