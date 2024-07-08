import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'brave_search_service.dart';

class ImageDetailPage extends StatefulWidget {
  final ImageResult imageResult;

  const ImageDetailPage({Key? key, required this.imageResult})
      : super(key: key);

  @override
  _ImageDetailPageState createState() => _ImageDetailPageState();
}

class _ImageDetailPageState extends State<ImageDetailPage> {
  Widget? child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('画像詳細'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () => _launchURL(widget.imageResult.sourceUrl),
          ),
        ],
      ),
      body: Center(
        child: _validateAndLoadImage(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _downloadImage(context),
        child: const Icon(Icons.download),
      ),
    );
  }

  Widget _validateAndLoadImage() {
    final imageUrl = widget.imageResult.fullSizeUrl;
    if (_isValidUrl(imageUrl)) {
      return Image.network(
        imageUrl,
        loadingBuilder: (BuildContext context, Widget loadingChild,
            ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) return loadingChild;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return Center(
            child: TextButton(
              child: const Text('再読み込み'),
              onPressed: () {
                setState(() {
                  child = Image.network(imageUrl);
                });
              },
            ),
          );
        },
      );
    } else {
      return Text('無効な画像 URL: $imageUrl');
    }
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  void _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      print('Could not launch $url');
    }
  }

  void _downloadImage(BuildContext context) async {
    print('Downloading image: ${widget.imageResult.fullSizeUrl}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('画像のダウンロードを開始しました')),
    );
  }
}
