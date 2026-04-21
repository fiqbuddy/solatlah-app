import 'package:flutter/material.dart';
import '../services/knowledge_service.dart';
import 'knowledge_result_page.dart';
import 'knowledge_bookmarks_page.dart';

class KnowledgePage extends StatefulWidget {
  const KnowledgePage({super.key});

  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<KnowledgePage> {
  final knowledgeService = KnowledgeService();
  final searchController = TextEditingController();
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> searchHistory = [];
  bool isLoading = true;
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cats = await knowledgeService.getCategories();
    final history = await knowledgeService.getSearchHistory();
    if (mounted)
      setState(() {
        categories = cats;
        searchHistory = history;
        isLoading = false;
      });
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => isSearching = true);

    // Save history
    await knowledgeService.saveHistory(query);

    // Check local DB first
    final localResults = await knowledgeService.search(query);

    if (localResults.isNotEmpty) {
      setState(() => isSearching = false);
      if (!mounted) return;
      searchController.clear();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => KnowledgeResultPage(
            query: query,
            results: localResults,
          ),
        ),
      ).then((_) => _loadData());
      return;
    }

    // Not in DB — use Gemini AI
    final aiResult = await knowledgeService.searchWithAI(query);
    setState(() => isSearching = false);

    if (!mounted) return;
    searchController.clear();

    if (aiResult['source'] == 'not_found' || aiResult['data'] == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => KnowledgeResultPage(
            query: query,
            results: [],
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KnowledgeResultPage(
          query: query,
          results: [aiResult['data']],
          isAiResult: true,
        ),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF4),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 20,
                right: 20,
                bottom: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rujukan Ilmu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Rujukan Ilmu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const KnowledgeBookmarksPage()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.bookmark_border,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text('Tanda Buku',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Cari hukum & ilmu Islam Mazhab Syafi\'i',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: searchController,
                      onSubmitted: _search,
                      decoration: InputDecoration(
                        hintText: 'Cari... cth: hukum solat jumaat',
                        hintStyle:
                            const TextStyle(color: Colors.grey, fontSize: 14),
                        prefixIcon:
                            const Icon(Icons.search, color: Color(0xFF2E7D32)),
                        suffixIcon: isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.arrow_forward,
                                    color: Color(0xFF2E7D32)),
                                onPressed: () => _search(searchController.text),
                              ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF2E7D32).withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified, color: Color(0xFF2E7D32), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Semua maklumat bersumber dari e-Fatwa JAKIM & Mufti Wilayah Persekutuan (Mazhab Syafi\'i)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2E7D32),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (searchHistory.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Carian Terkini',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20))),
                    GestureDetector(
                      onTap: () async {
                        await knowledgeService.clearHistory();
                        _loadData();
                      },
                      child: const Text('Padam',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: searchHistory.map((h) {
                    return GestureDetector(
                      onTap: () {
                        searchController.text = h['query'];
                        _search(h['query']);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.history,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(h['query'],
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: const Text('Kategori',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20))),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: isLoading
                ? const SliverToBoxAdapter(
                    child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF2E7D32))))
                : SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final cat = categories[index];
                        return GestureDetector(
                          onTap: () async {
                            setState(() => isSearching = true);
                            final results = await knowledgeService
                                .getByCategory(cat['name']);
                            setState(() => isSearching = false);
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => KnowledgeResultPage(
                                  query: cat['name'],
                                  results: results,
                                  isCategory: true,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(cat['icon'] ?? '📖',
                                    style: const TextStyle(fontSize: 28)),
                                const SizedBox(height: 8),
                                Text(
                                  cat['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  cat['description'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: categories.length,
                    ),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}
