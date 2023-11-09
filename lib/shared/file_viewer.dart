import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:royal_marble/shared/loading.dart';

class FileViewer extends StatefulWidget {
  const FileViewer({Key? key, this.file}) : super(key: key);
  final Future<File>? file;

  @override
  State<FileViewer> createState() => _FileViewerState();
}

class _FileViewerState extends State<FileViewer> {
  final _openResult = 'Unknown';

  Future<String> openFile() async {
    var file = await widget.file;
    var path = file!.path;

    final result = await OpenFilex.open(path);

    return 'type=${result.type} message=${result.message}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Excel File'),
        backgroundColor: const Color.fromARGB(255, 191, 180, 66),
      ),
      body: _buildFileViewerBody(),
    );
  }

  Widget _buildFileViewerBody() {
    return FutureBuilder(
        future: openFile(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return SingleChildScrollView(
              child: Center(child: Text(snapshot.data!)),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            return const Center(
              child: Loading(),
            );
          }
        });
  }
}
