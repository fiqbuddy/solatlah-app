import 'package:flutter/material.dart';
import 'knowledge_detail_page.dart';

class KnowledgeResultPage extends StatelessWidget {
  final String query;
  final List<Map<String, dynamic>> results;
  final bool isCategory;
  final bool isAiResult;

  const KnowledgeResultPage({
    super.key,
    required this.query,
    required this.results,
    this.isCategory = false,
    this.isAiResult = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isCategory ? query : 'Hasil Carian',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              isCategory
                  ? '${results.length} rekod dijumpai'
                  : '"$query" — ${results.length} hasil',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ),
      ),
      body: results.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Tiada rekod dijumpai',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sila rujuk ulama atau mufti tempatan\nuntuk mendapatkan maklumat lanjut.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Color(0xFF2E7D32), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Hubungi JAKIM: 03-8886 4000\natau e-Fatwa: www.e-fatwa.gov.my',
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2E7D32),
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final item = results[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => KnowledgeDetailPage(item: item),
                    ),
                  ),
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
                        // Category badge
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
                            if (item['subcategory'] != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                '› ${item['subcategory']}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Title
                        Text(
                          item['title'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Question preview
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

                        // Source
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
                        // Add below source row in result card:
                        if (isAiResult)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome,
                                    size: 12, color: Colors.blue),
                                SizedBox(width: 4),
                                Text('Dijana AI dari sumber terverifikasi',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.blue)),
                              ],
                            ),
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
