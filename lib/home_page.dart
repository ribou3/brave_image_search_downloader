import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'brave_search_service.dart';
import 'image_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final BraveSearchService _searchService = BraveSearchService();
  List<ImageResult> _imageResults = [];
  bool _isLoading = false;
  bool _safeSearch = true;
  String _selectedFilter = 'すべて';
  int _offset = 0;
  int _crossAxisCount = 2; // 新しい変数: グリッドの列数

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('画像検索'),
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (!_isLoading &&
                    scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent) {
                  _loadMoreImages();
                  return true;
                }
                return false;
              },
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _crossAxisCount, // 更新: 動的な列数
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: _imageResults.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _openImageDetail(_imageResults[index]),
                    child: Image.network(
                      _imageResults[index].thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading image: $error');
                        WidgetsBinding.instance!.addPostFrameCallback((_) {
                          setState(() {
                            _imageResults.removeAt(index);
                          });
                        });
                        return const SizedBox();
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          if (_isLoading) const CircularProgressIndicator(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSearchField,
        child: const Icon(Icons.search),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text('メニュー',
                style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            title: const Text('検索フィルター'),
            trailing: DropdownButton<String>(
              value: _selectedFilter,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedFilter = newValue;
                  });
                }
              },
              items: <String>['すべて', '写真', 'イラスト', 'GIF']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          SwitchListTile(
            title: const Text('セーフサーチ'),
            value: _safeSearch,
            onChanged: (bool value) {
              setState(() {
                _safeSearch = value;
              });
            },
          ),
          ListTile(
            title: const Text('グリッドの列数'),
            trailing: DropdownButton<int>(
              value: _crossAxisCount,
              onChanged: (int? newValue) {
                if (newValue != null) {
                  setState(() {
                    _crossAxisCount = newValue;
                  });
                }
              },
              items: List.generate(10, (index) => index + 1)
                  .map<DropdownMenuItem<int>>((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchField() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('画像を検索'), // ダイアログのタイトル
          content: TextField(
            controller: _searchController, // 検索テキストフィールドのコントローラ
            decoration:
                const InputDecoration(hintText: "検索キーワードを入力"), // ヒントテキスト
            onSubmitted: (_) => _searchImages(), // 検索キーワードを送信したときの処理
          ),
          actions: [
            TextButton(
              child: const Text('キャンセル'), // キャンセルボタン
              onPressed: () => Navigator.pop(context), // ダイアログを閉じる処理
            ),
            TextButton(
              child: const Text('検索'), // 検索ボタン
              onPressed: () {
                Navigator.pop(context);
                _searchImages(); // 検索を実行する処理
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _searchImages() async {
    setState(() {
      _isLoading = true; // ローディング中に設定
      _offset = 0; // オフセットをリセット
      _imageResults.clear(); // 検索結果をクリア
    });

    try {
      final results = await _searchService.searchImages(
        // 画像を検索する処理
        _searchController.text, // 検索キーワード
        _selectedFilter, // フィルター
        _safeSearch, // セーフサーチ
        _offset, // オフセット
      );
      setState(() {
        _imageResults = results; // 検索結果を設定
        _isLoading = false; // ローディング中を解除
        _offset += results.length; // オフセットを更新
      });
    } catch (e) {
      setState(() {
        _isLoading = false; // ローディング中を解除
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('画像の検索中にエラーが発生しました: $e')), // エラーメッセージの表示
      );
    }
  }

  Future<void> _loadMoreImages() async {
    if (!_isLoading) {
      setState(() {
        _isLoading = true; // ローディング中に設定
      });

      try {
        final results = await _searchService.searchImages(
          // 画像を追加で読み込む処理
          _searchController.text, // 検索キーワード
          _selectedFilter, // フィルター
          _safeSearch, // セーフサーチ
          _offset, // オフセット
        );
        setState(() {
          _imageResults.addAll(results); // 追加の検索結果をリストに追加
          _isLoading = false; // ローディング中を解除
          _offset += results.length; // オフセットを更新
        });
      } catch (e) {
        setState(() {
          _isLoading = false; // ローディング中を解除
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')), // エラーメッセージの表示
        );
      }
    }
  }

  void _openImageDetail(ImageResult imageResult) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ImageDetailPage(imageResult: imageResult), // 画像詳細ページを開く処理
      ),
    );
  }
}
