import 'package:flutter/material.dart';
//import 'package:url_launcher/url_launcher.dart';
import 'brave_search_service.dart';
import 'image_detail_page.dart';
//import 'package:autocomplete_textfield/autocomplete_textfield.dart';

// ホーム画面ウィジェットを定義する
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

// ホーム画面の状態を管理する
class _HomePageState extends State<HomePage> {
  // 検索テキストフィールドのコントローラ
  final TextEditingController _searchController = TextEditingController();
  // 画像検索サービス
  final BraveSearchService _searchService = BraveSearchService();
  // 画像検索結果のリスト
  List<ImageResult> _imageResults = [];
  // ローディング中かどうかのフラグ
  bool _isLoading = false;
  // セーフサーチモードかどうかのフラグ
  bool _safeSearch = true;
  // 選択されているフィルター
  String _selectedFilter = 'すべて';
  // 画像のオフセット
  int _offset = 0;
  // グリッドの列数
  int _crossAxisCount = 2;

  // ウィジェットを構築する
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('画像検索'),
      ),
      drawer: _buildDrawer(), // サイドメニューを構築する
      body: Column(
        children: [
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                // 最大スクロール時に追加の画像を読み込む
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
                  crossAxisCount: _crossAxisCount, // 動的な列数
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: _imageResults.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _openImageDetail(_imageResults[index]),
                    // 画像をタップしたら詳細ページを開く
                    child: Image.network(
                      _imageResults[index].thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // エラー時にエラーメッセージを表示
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
          if (_isLoading)
            const CircularProgressIndicator(), // ローディング中ならインジケーターを表示
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSearchField, // 検索フィールドを表示する
        child: const Icon(Icons.search),
      ),
    );
  }

  // サイドメニューを構築する
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
              onChanged: (newValue) {
                // フィルターを変更したら検索結果を更新する
                setState(() {
                  _selectedFilter = newValue ?? 'すべて';
                });
              },
              items: <String>['すべて', '写真', 'イラスト', 'GIF']
                  .map<DropdownMenuItem<String>>((value) {
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
            onChanged: (value) {
              // セーフサーチモードを変更したら検索結果を更新する
              setState(() {
                _safeSearch = value;
              });
            },
          ),
          ListTile(
            title: const Text('グリッドの列数'),
            trailing: DropdownButton<int>(
              value: _crossAxisCount,
              onChanged: (newValue) {
                // グリッドの列数を変更したらレイアウトを更新する
                setState(() {
                  _crossAxisCount = newValue ?? 2;
                });
              },
              items: List.generate(10, (index) => index + 1)
                  .map<DropdownMenuItem<int>>((value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
            ),
          ),
          ListTile(
            title: Text('オープンソースライセンス'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LicensePage()),
              );
            },
          )
        ],
      ),
    );
  }

  // 検索フィールドを表示するダイアログを表示する
  void _showSearchField() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('画像を検索'),
          content: TextField(
            controller: _searchController,
            decoration: const InputDecoration(hintText: "検索キーワードを入力"),
            onSubmitted: (_) {
              _searchImages();
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('検索'),
              onPressed: () {
                Navigator.pop(context);
                _searchImages();
              },
            ),
          ],
        );
      },
    );
  }

  // 画像を検索する
  Future<void> _searchImages() async {
    setState(() {
      _isLoading = true;
      _offset = 0;
      _imageResults.clear();
    });

    try {
      final results = await _searchService.searchImages(
        _searchController.text,
        _selectedFilter,
        _safeSearch,
        _offset,
      );
      setState(() {
        _imageResults = results;
        _isLoading = false;
        _offset += results.length;
        print("searchimage's offset is $_offset");
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('画像の検索中にエラーが発生しました: $e')),
      );
    }
  }

  // 追加の画像を読み込む
  Future<void> _loadMoreImages() async {
    if (_isLoading) return; // ローディング中ならリターンする

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _searchService.searchImages(
        _searchController.text,
        _selectedFilter,
        _safeSearch,
        _offset,
      );

      setState(() {
        if (results.isNotEmpty) {
          _imageResults.addAll(results);
          _offset += results.length;
          print("currnt offset is $_offset");
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading more images: $e');
    }
  }

  // void _startNewSearch() {
  //   setState(() {
  //     _imageResults.clear();
  //     _offset = 0;
  //   });
  //   _loadMoreImages();
  // }

  // 画像詳細ページを開く
  void _openImageDetail(ImageResult imageResult) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageDetailPage(imageResult: imageResult),
      ),
    );
  }
}
