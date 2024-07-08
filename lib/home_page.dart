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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
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
                        _imageResults.removeAt(index);
                        setState(() {});
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
        ],
      ),
    );
  }

  void _showSearchField() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('画像を検索'),
          content: TextField(
            controller: _searchController,
            decoration: const InputDecoration(hintText: "検索キーワードを入力"),
            onSubmitted: (_) => _searchImages(),
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

  Future<void> _loadMoreImages() async {
    if (!_isLoading) {
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
          _imageResults.addAll(results);
          _isLoading = false;
          _offset += results.length;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    }
  }

  void _openImageDetail(ImageResult imageResult) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageDetailPage(imageResult: imageResult),
      ),
    );
  }
}
