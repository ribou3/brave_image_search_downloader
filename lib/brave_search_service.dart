import 'dart:convert';
import 'package:http/http.dart' as http;

class BraveSearchService {
  static const String _baseUrl =
      'https://api.search.brave.com/res/v1/images/search';
  static const String _apiKey = 'BSAxnrwwLO9M4_MO87vf5IYBKBw8di_';

  Future<List<ImageResult>> searchImages(
    String query,
    String filter,
    bool safeSearch,
    int offset,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl?q=$query&offset=$offset&safe=${safeSearch ? 'strict' : 'off'}'),
        headers: {'X-Subscription-Token': _apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data == null) {
          throw Exception('API response is null');
        }
        final results = data['results'] as List?;
        if (results == null) {
          throw Exception('No results found in API response');
        }
        return results
            .map((result) => ImageResult.fromJson(result))
            .where((result) => result != null)
            .cast<ImageResult>()
            .toList();
      } else {
        throw Exception('Failed to load images: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in searchImages: $e');
      rethrow;
    }
  }
}

class ImageResult {
  final String thumbnailUrl;
  final String imageUrl;
  final String sourceUrl;
  final String fullSizeUrl;

  ImageResult({
    required this.thumbnailUrl,
    required this.imageUrl,
    required this.sourceUrl,
    required this.fullSizeUrl,
  });

  static ImageResult? fromJson(Map<String, dynamic> json) {
    try {
      return ImageResult(
        thumbnailUrl: json['thumbnail']?['src'] as String? ?? '',
        imageUrl: json['image']?['src'] as String? ?? '',
        sourceUrl: json['url'] as String? ?? '',
        fullSizeUrl: json['image']?['src'] as String? ?? '',
      );
    } catch (e) {
      print('Error parsing ImageResult: $e');
      return null;
    }
  }
}
