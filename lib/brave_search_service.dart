import 'dart:convert';
import 'package:http/http.dart' as http;

// BraveSearchService クラスは、Brave API を使って画像検索を行うサービスです。
class BraveSearchService {
  // API の基本 URL
  static const String _baseUrl =
      'https://api.search.brave.com/res/v1/images/search';
  // API キー
  static const String _apiKey = 'BSAxnrwwLO9M4_MO87vf5IYBKBw8di_';

  // 画像を検索するメソッド
  Future<List<ImageResult>> searchImages(
    String query, // 検索クエリ
    String filter, // 検索フィルター
    bool safeSearch, // セーフサーチの有効/無効
    int offset, // 検索結果のオフセット
  ) async {
    try {
      // API リクエストの送信
      final response = await http.get(
        Uri.parse(
            '$_baseUrl?q=$query&offset=$offset&safe=${safeSearch ? 'strict' : 'off'}'),
        headers: {'X-Subscription-Token': _apiKey},
      );

      // レスポンスが正常かどうかの確認
      if (response.statusCode == 200) {
        final data = json.decode(response.body); // レスポンスボディのデコード
        if (data == null) {
          throw Exception('API response is null');
        }
        final results = data['results'] as List?; // 結果リストの取得
        if (results == null) {
          throw Exception('No results found in API response');
        }
        return results
            .map((result) =>
                ImageResult.fromJson(result)) // JSON を ImageResult に変換
            .where((result) => result != null) // null でない結果のみをフィルタリング
            .cast<ImageResult>() // ImageResult 型にキャスト
            .toList(); // リストに変換
      } else {
        throw Exception('Failed to load images: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in searchImages: $e');
      rethrow;
    }
  }
}

// ImageResult クラスは、画像検索結果の各画像の情報を格納します。
class ImageResult {
  final String thumbnailUrl; // サムネイル URL
  final String imageUrl; // 画像 URL
  final String sourceUrl; // ソース URL
  final String fullSizeUrl; // フルサイズ画像 URL

  ImageResult({
    required this.thumbnailUrl,
    required this.imageUrl,
    required this.sourceUrl,
    required this.fullSizeUrl,
  });

  // JSON から ImageResult オブジェクトを生成するファクトリメソッド
  static ImageResult? fromJson(Map<String, dynamic> json) {
    try {
      return ImageResult(
        thumbnailUrl: json['thumbnail']?['src'] as String? ?? '', // サムネイル URL
        imageUrl: json['image']?['src'] as String? ?? '', // 画像 URL
        sourceUrl: json['url'] as String? ?? '', // ソース URL
        fullSizeUrl: json['image']?['src'] as String? ?? '', // フルサイズ画像 URL
      );
    } catch (e) {
      print('Error parsing ImageResult: $e');
      return null;
    }
  }
}
