import 'dart:io';
import 'package:customer_contract_manager/constants.dart';
import 'package:customer_contract_manager/pages/home/file_editor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var files = List<FileSystemEntity>.empty();
  var templates = List<FileSystemEntity>.empty();
  late String directory;

  @override
  void initState() {
    super.initState();
    _listOfFiles();
    _listTemplatesFiles();
  }

  void _listOfFiles() async {
    directory = await createFolderInAppDocDir(Constants.customerContractsFolderName);
    setState(() {
      files = Directory(directory).listSync();
    });
  }

  void _listTemplatesFiles() async {
    directory = await createFolderInAppDocDir(Constants.templateFolderName);
    setState(() {
      templates = Directory(directory).listSync();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 2),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _chooseTemplate(),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (BuildContext context, int index) {
                    return _fileCardItem(files[index]);
                  }),
            )
          ],
        ),
      ),
    );
  }

  _chooseTemplate() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext builder) => Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * .9,
            maxHeight: MediaQuery.of(context).size.height * .9,
          ),
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: <Widget>[
              ElevatedButton(
                onPressed: () => _uploadTemplate(),
                child: const Text('Upload new template'),
              ),
              SizedBox(height: 10.h),
              Expanded(
                child: ListView.builder(
                    itemCount: templates.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _fileCardItem(templates[index], isTemplate: true);
                    }),
              ),
            ],
          )),
    );
  }

  Widget _fileCardItem(FileSystemEntity file, {bool isTemplate = false}) {
    return Card(
      child: ListTile(
          title: Text(file.path.split('/').last),
          trailing: IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (BuildContext builder) => Container(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * .9,
                    maxHeight: MediaQuery.of(context).size.height * .9,
                  ),
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: SfPdfViewer.file(File(file.path)),
                ),
              );
            },
            icon: const Icon(Icons.visibility),
          ),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (BuildContext builder) => Container(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * .9,
                  maxHeight: MediaQuery.of(context).size.height * .9,
                ),
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: FileEditor(file, isTemplate),
              ),
            ).whenComplete(() {
              _listOfFiles();
            });
          }),
    );
  }

  _uploadTemplate() async {
    var status = await Permission.storage.status;
    if (status.isDenied) {
      await Permission.storage.request();
    }

    var result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) {
      return;
    }

    var templateDir = await createFolderInAppDocDir(Constants.templateFolderName);
    var file = File(result.files.single.path!);
    await file.copy('$templateDir/${result.files.single.name}');
    showToast('Template uploaded successfully!', backgroundColor: Colors.green);
    _listTemplatesFiles();
  }

  static Future<String> createFolderInAppDocDir(String folderName) async {
    final dir = await getApplicationDocumentsDirectory();

    final appDocDirFolder = Directory('${dir.path}/$folderName/');

    if (await appDocDirFolder.exists()) {
      return appDocDirFolder.path;
    } else {
      final appDocDirNewFolder = await appDocDirFolder.create(recursive: true);
      return appDocDirNewFolder.path;
    }
  }
}
