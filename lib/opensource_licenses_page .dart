import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class OpenSourceLicensesPage extends StatelessWidget {
  const OpenSourceLicensesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('オープンソースライセンス'),
      ),
      body: FutureBuilder<LicenseData>(
        future: _loadLicenses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('ライセンス情報が見つかりません'));
          }

          final licenseData = snapshot.data!;
          return ListView.builder(
            itemCount: licenseData.packages.length,
            itemBuilder: (context, index) {
              final package = licenseData.packages[index];
              return ExpansionTile(
                title: Text(package),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      licenseData.licenses[package] ?? '利用可能なライセンス情報はありません',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<LicenseData> _loadLicenses() async {
    final licenseData = LicenseData();
    await for (var license in LicenseRegistry.licenses) {
      for (var package in license.packages) {
        final packageLicense =
            license.paragraphs.map((p) => p.text).join('\n\n');
        if (licenseData.licenses.containsKey(package)) {
          licenseData.licenses[package] =
              '${licenseData.licenses[package]}\n\n$packageLicense';
        } else {
          licenseData.licenses[package] = packageLicense;
          licenseData.packages.add(package);
        }
      }
    }
    return licenseData;
  }
}

class LicenseData {
  final List<String> packages = [];
  final Map<String, String> licenses = {};
}
