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
  bool isSearchOpen = false;
  String searchText = '';

  @override
  void initState() {
    super.initState();
    _getAccessToExternalFolders();
    _listOfFiles();
    _listTemplatesFiles();
  }

  Future<void> _getAccessToExternalFolders() async {
    var status = await Permission.storage.status;
    if (status.isDenied) {
      if (Platform.isAndroid) {
        await Permission.manageExternalStorage.request();
      } else {
        await Permission.storage.request();
      }
    }
  }

  void _listOfFiles() async {
    directory = await createFolderInAppDocDir(Constants.customerContractsFolderName);
    setState(() {
      files = Directory(directory).listSync();
    });
  }

  Future<void> _listTemplatesFiles() async {
    directory = await createFolderInAppDocDir(Constants.templateFolderName);
    setState(() {
      templates = Directory(directory).listSync();
    });
  }

  @override
  Widget build(BuildContext context) {
    var filteredFiles = _filterFiles();
    return Scaffold(
      appBar: AppBar(elevation: 2),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: isSearchOpen
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * .8,
                      minWidth: MediaQuery.of(context).size.width * .5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextFormField(
                      initialValue: searchText,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        suffixIcon: searchText.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  setState(() {
                                    searchText = '';
                                    isSearchOpen = false;
                                  });
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchText = value;
                        });
                      },
                      onEditingComplete: () {
                        setState(() {
                          isSearchOpen = false;
                        });
                      },
                    ),
                  )
                : FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        isSearchOpen = true;
                      });
                    },
                    child: const Icon(Icons.search),
                  ),
          ),
          SizedBox(height: 10.h),
          FloatingActionButton(
            onPressed: () => _chooseTemplate(),
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                  itemCount: filteredFiles.length,
                  itemBuilder: (BuildContext context, int index) {
                    return _fileCardItem(filteredFiles[index]);
                  }),
            ),
          ],
        ),
      ),
    );
  }

  _filterFiles() {
    if (searchText.isEmpty || searchText.length < 3) {
      return files;
    }

    return files.where((element) => element.path.contains(searchText)).toList();
  }

  _chooseTemplate() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext builder) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => Container(
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
                onPressed: () async => await _uploadTemplate(setState),
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
          ),
        ),
      ),
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

  _uploadTemplate(StateSetter setState) async {
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
    await _listTemplatesFiles();
    setState(() {});
  }

  static Future<String> createFolderInAppDocDir(String folderName) async {
    final dir = Platform.isIOS ? await getApplicationDocumentsDirectory() : (await getExternalStorageDirectories())![0];

    final appDocDirFolder = Directory('${dir.path}/$folderName/');

    if (await appDocDirFolder.exists()) {
      return appDocDirFolder.path;
    } else {
      final appDocDirNewFolder = await appDocDirFolder.create(recursive: true);
      return appDocDirNewFolder.path;
    }
  }
}
