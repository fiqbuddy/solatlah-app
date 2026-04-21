import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class KnowledgeService {
  final client = Supabase.instance.client;
  String get currentEmail => client.auth.currentUser!.email!;

  Future<Map<String, dynamic>> searchWithAI(String query) async {
    final cached = await _checkCache(query);
    if (cached != null) return {'source': 'cache', 'data': cached};

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY']!;

      final response = await http.post(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': '''Anda pakar fiqh Islam Mazhab Syafi'i Malaysia.

Jawab soalan berikut dalam Bahasa Melayu berdasarkan sumber JAKIM, e-Fatwa, atau Mufti Wilayah Persekutuan.
Anda MESTI menjawab HANYA berdasarkan maklumat dari sumber-sumber yang dibenarkan sahaja:
- e-fatwa.gov.my (JAKIM)
- muftiwp.gov.my (Mufti Wilayah Persekutuan)
- islamicfinder.org
- myislam.com.my

Soalan: $query

Tulis jawapan TEPAT dalam format berikut tanpa ubah suai:
TAJUK: tulis tajuk ringkas di sini
KATEGORI: tulis satu kategori (Solat/Puasa/Zakat/Bersuci/Akidah/Muamalat/Adab)
SUMBER: tulis nama sumber rujukan di sini
JAWAPAN: tulis jawapan penuh di sini hingga selesai'''
                }
              ]
            }
          ],
          'tools': [
            {'google_search': {}}
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 3000,
          },
        }),
      );

      debugPrint('Gemini status: ${response.statusCode}');

      if (response.statusCode == 429) {
        return {'source': 'rate_limited', 'data': null};
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          return {'source': 'not_found', 'data': null};
        }

        final parts = candidates[0]['content']['parts'] as List?;
        if (parts == null || parts.isEmpty) {
          return {'source': 'not_found', 'data': null};
        }

        String fullText = '';
        for (final part in parts) {
          if (part['text'] != null) fullText += part['text'];
        }

        debugPrint('Gemini text: $fullText');

        // Parse plain text format
        final tajuk = _extractField(fullText, 'TAJUK');
        final kategori = _extractField(fullText, 'KATEGORI');
        final sumber = _extractField(fullText, 'SUMBER');
        final jawapan = _extractField(fullText, 'JAWAPAN');

        debugPrint('Tajuk: $tajuk');
        debugPrint('Jawapan length: ${jawapan.length}');

        if (jawapan.isNotEmpty && tajuk.isNotEmpty) {
          final result = {
            'found': true,
            'title': tajuk,
            'question': query,
            'answer': jawapan,
            'source':
                sumber.isNotEmpty ? sumber : 'e-Fatwa JAKIM / Mufti Wilayah',
            'source_url': 'https://www.e-fatwa.gov.my',
            'category': kategori.isNotEmpty ? kategori : 'Umum',
            'subcategory': '',
            'mazhab': 'Syafi\'i',
          };
          await _saveToCache(result, query);
          return {'source': 'ai', 'data': result};
        }

        return {'source': 'not_found', 'data': null};
      }

      debugPrint('Gemini error: ${response.body}');
      return {'source': 'error', 'data': null};
    } catch (e) {
      debugPrint('AI search error: $e');
      return {'source': 'error', 'data': null};
    }
  }

  String _extractField(String text, String field) {
    // Find the field marker
    final startMarker = '$field:';
    final startIndex = text.indexOf(startMarker);
    if (startIndex == -1) return '';

    // Get everything after the marker
    final afterMarker = text.substring(startIndex + startMarker.length).trim();

    // Find the next field marker (any ALL CAPS word followed by colon)
    final nextFieldMatch = RegExp(r'\n[A-Z]+:').firstMatch(afterMarker);
    if (nextFieldMatch != null) {
      return afterMarker.substring(0, nextFieldMatch.start).trim();
    }

    return afterMarker.trim();
  }

  Future<Map<String, dynamic>?> _checkCache(String query) async {
    final results = await client
        .from('knowledge_base')
        .select()
        .or('title.ilike.%$query%,question.ilike.%$query%')
        .limit(1)
        .maybeSingle();
    return results;
  }

  Future<void> _saveToCache(Map<String, dynamic> data, String query) async {
    try {
      await client.from('knowledge_base').insert({
        'title': data['title'],
        'question': data['question'],
        'answer': data['answer'],
        'source': data['source'],
        'source_url': data['source_url'],
        'category': data['category'] ?? 'Umum',
        'subcategory': data['subcategory'],
        'mazhab': 'Shafi\'i',
        'verified_at': DateTime.now().toIso8601String().split('T')[0],
      });
    } catch (e) {
      debugPrint('Cache save error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    return await client
        .from('knowledge_categories')
        .select()
        .order('order', ascending: true);
  }

  Future<List<Map<String, dynamic>>> search(String query) async {
    if (query.trim().isEmpty) return [];

    // Save search history
    await client.from('knowledge_search_history').insert({
      'email': currentEmail,
      'query': query.trim(),
    });

    // Search using ILIKE for simple matching
    final results = await client
        .from('knowledge_base')
        .select()
        .or('title.ilike.%$query%,question.ilike.%$query%,answer.ilike.%$query%,category.ilike.%$query%,subcategory.ilike.%$query%')
        .order('category');

    return List<Map<String, dynamic>>.from(results);
  }

  Future<List<Map<String, dynamic>>> getByCategory(String category) async {
    return await client
        .from('knowledge_base')
        .select()
        .eq('category', category)
        .order('subcategory');
  }

  Future<void> saveHistory(String query) async {
    try {
      await client.from('knowledge_search_history').insert({
        'email': currentEmail,
        'query': query.trim(),
      });
    } catch (e) {
      debugPrint('History save error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSearchHistory() async {
    return await client
        .from('knowledge_search_history')
        .select()
        .eq('email', currentEmail)
        .order('searched_at', ascending: false)
        .limit(4);
  }

  Future<void> clearHistory() async {
    await client
        .from('knowledge_search_history')
        .delete()
        .eq('email', currentEmail);
  }

  Future<bool> isBookmarked(int knowledgeId) async {
    final data = await client
        .from('knowledge_bookmarks')
        .select()
        .eq('email', currentEmail)
        .eq('knowledge_id', knowledgeId)
        .maybeSingle();
    return data != null;
  }

  Future<void> toggleBookmark(int knowledgeId) async {
    final bookmarked = await isBookmarked(knowledgeId);
    if (bookmarked) {
      await client
          .from('knowledge_bookmarks')
          .delete()
          .eq('email', currentEmail)
          .eq('knowledge_id', knowledgeId);
    } else {
      await client.from('knowledge_bookmarks').insert({
        'email': currentEmail,
        'knowledge_id': knowledgeId,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getBookmarks() async {
    final data = await client
        .from('knowledge_bookmarks')
        .select('*, knowledge_base(*)')
        .eq('email', currentEmail)
        .order('bookmarked_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
}
