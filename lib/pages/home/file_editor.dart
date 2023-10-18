import 'dart:io';
import 'dart:ui';
import 'package:customer_contract_manager/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

class FileEditor extends StatefulWidget {
  final FileSystemEntity file;
  final bool isTemplate;

  const FileEditor(this.file, this.isTemplate, {super.key});

  @override
  State<FileEditor> createState() => _FileEditorState();
}

class _FileEditorState extends State<FileEditor> {
  late PdfDocument _document;
  final _form = FormGroup({});
  final _formFields = List<ReactiveTextField>.empty(growable: true);
  final String signatureFieldName = 'signature_es_:signatureblock';
  final String rowEndSign = '<::>';
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _openFile();
  }

  void _openFile() async {
    final file = File(widget.file.path);
    final bytes = file.readAsBytesSync();
    final document = PdfDocument(
      inputBytes: bytes,
    );

    _document = document;
    _buildReactiveFormFromPdf(document);
  }

  _buildReactiveFormFromPdf(PdfDocument document) {
    Map<String, FormControl<String>> controls = {};
    for (var i = 0; i < document.form.fields.count; i++) {
      controls.putIfAbsent(
        document.form.fields[i].name!,
        () => FormControl<String>(
            value: (document.form.fields[i] as PdfTextBoxField).text, validators: [Validators.required]),
      );

      _formFields.add(ReactiveTextField(
        decoration: InputDecoration(
          labelText: document.form.fields[i].name!,
        ),
        formControlName: document.form.fields[i].name!,
      ));
    }

    controls.putIfAbsent('comment', () => FormControl<String>(value: ''));
    _formFields.add(ReactiveTextField(
      maxLines: 3,
      decoration: const InputDecoration(labelText: 'Comment'),
      formControlName: 'comment',
    ));

    _form.addAll(controls);
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveForm(
      formGroup: _form,
      child: Column(
        children: <Widget>[
          Column(children: <Widget>[
            ..._formFields,
            SizedBox(height: 10.h),
            if (widget.isTemplate)
              SfSignaturePad(
                key: _signaturePadKey,
                minimumStrokeWidth: 1,
                maximumStrokeWidth: 3,
                strokeColor: Colors.blue,
                backgroundColor: Colors.grey[200],
              ),
          ]),
          SizedBox(height: 20.h),
          ElevatedButton(
            onPressed: () async {
              _form.markAllAsTouched();

              if (!_form.valid) {
                return;
              }

              if (widget.isTemplate) {
                await _addSignatureToForm();
              }

              _drawCommentsGrid();

              _saveDocument(widget.isTemplate ? await _getNewTemplatePath() : widget.file.path);

              // ignore: use_build_context_synchronously
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  _addSignatureToForm() async {
    var extractor = PdfTextExtractor(_document);
    var findResult = extractor.findText([signatureFieldName]);
    if (findResult.isEmpty) {
      return;
    }

    var image = await _signaturePadKey.currentState!.toImage();
    final bytes = await image.toByteData(format: ImageByteFormat.png);

    for (int i = 0; i < findResult.length; i++) {
      MatchedItem item = findResult[i];
      PdfPage page = _document.pages[item.pageIndex];
      page.graphics
          .drawImage(PdfBitmap(bytes!.buffer.asUint8List()), Rect.fromLTWH(item.bounds.left, item.bounds.top, 165, 55));
    }
  }

  _saveDocument(String path) {
    for (var i = 0; i < _document.form.fields.count; i++) {
      (_document.form.fields[i] as PdfTextBoxField).text = _form.control(_document.form.fields[i].name!).value;
    }

    final bytes = _document.saveSync();
    final file = File(path);
    file.writeAsBytesSync(bytes);
    _document.dispose();
  }

  _getNewTemplatePath() async {
    var fileNamePrefix = _form.control('failo_pavadinimas').value;
    var fileName = widget.file.path.split('/').last;
    var newName = '${fileNamePrefix}_$fileName';
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/${Constants.customerContractsFolderName}/$newName';
  }

  _drawCommentsGrid() {
    var value = _form.control('comment').value;
    if (value.isEmpty) {
      return;
    }

    var columns = value.split('||');

    final grid = PdfGrid();
    grid.columns.add(count: columns.length);
    var row = grid.rows.add();

    var longestValueIndex = 0;
    for (var i = 0; i < columns.length; i++) {
      row.cells[i].value = columns[i];
      row.cells[i].style.backgroundBrush = PdfBrushes.white;

      if (columns[i].length > columns[longestValueIndex].length) {
        longestValueIndex = i;
      }
    }

    row.cells[longestValueIndex].value += '${row.cells[longestValueIndex].value} $rowEndSign';
    //<:-:>

    grid.style.cellPadding = PdfPaddings(left: 5, top: 5);

    var extractor = PdfTextExtractor(_document);
    var findResult = extractor.findText([rowEndSign]);
    if (findResult.isEmpty) {
      return;
    }

    MatchedItem item = findResult.last;
    PdfPage page = _document.pages[item.pageIndex];

    try {
      grid.draw(page: page, bounds: Rect.fromLTWH(36, item.bounds.bottom + 4, page.getClientSize().width - 36, 0));
    } catch (e) {
      grid.draw(page: _document.pages.add(), bounds: Rect.fromLTWH(0, 0, page.getClientSize().width - 36, 0));
    }
  }
}
