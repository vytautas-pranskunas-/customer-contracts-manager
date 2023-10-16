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
  late FormGroup _form;
  final String signatureFieldName = 'signature_es_:signatureblock';
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
    _form = FormGroup({});

    Map<String, FormControl<String>> controls = {};
    for (var i = 0; i < document.form.fields.count; i++) {
      controls.putIfAbsent(
        document.form.fields[i].name!,
        () => FormControl<String>(
            value: (document.form.fields[i] as PdfTextBoxField).text, validators: [Validators.required]),
      );
    }
    _form.addAll(controls);
  }

  _getReactiveTextFieldFromForm() sync* {
    for (var i = 0; i < _document.form.fields.count; i++) {
      yield ReactiveTextField(
        decoration: InputDecoration(
          labelText: _document.form.fields[i].name!,
        ),
        formControlName: _document.form.fields[i].name!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveForm(
      formGroup: _form,
      child: Column(
        children: <Widget>[
          ..._getReactiveTextFieldFromForm(),
          if (widget.isTemplate) SizedBox(height: 10.h),
          if (widget.isTemplate)
            SfSignaturePad(
              key: _signaturePadKey,
              minimumStrokeWidth: 1,
              maximumStrokeWidth: 3,
              strokeColor: Colors.blue,
              backgroundColor: Colors.grey[200],
            ),
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
    PdfTextExtractor extractor = PdfTextExtractor(_document);
    List<MatchedItem> findResult = extractor.findText([signatureFieldName]);
    if (findResult.isEmpty) {
      return;
    }

    var image = await _signaturePadKey.currentState!.toImage();
    final bytes = await image.toByteData(format: ImageByteFormat.png);

    for (int i = 0; i < findResult.length; i++) {
      MatchedItem item = findResult[i];
      //Get page.
      PdfPage page = _document.pages[item.pageIndex];
      //Set transparency to the page graphics.
      /*  page.graphics.save();
      page.graphics.setTransparency(0.5); */
      //Draw rectangle to highlight the text.
      page.graphics
          .drawImage(PdfBitmap(bytes!.buffer.asUint8List()), Rect.fromLTWH(item.bounds.left, item.bounds.top, 165, 55));
      /*  page.graphics.drawRectangle(bounds: item.bounds, brush: PdfBrushes.yellow);
      page.graphics.restore(); */
    }
    /* for (var i = 0; i < _document.form.fields.count; i++) {
      var image = await _signaturePadKey.currentState!.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ImageByteFormat.png);
      (_document.form.fields[i] as PdfSignatureField)
          .appearance
          .normal
          .graphics!
          .drawImage(PdfBitmap(bytes!.buffer.asUint8List()), const Rect.fromLTWH(0, 0, 250, 200));
    } */
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
    var firstName = _form.control('firstName').value;
    var lastName = _form.control('lastName').value;
    var fileName = widget.file.path.split('/').last;
    var newName = '$firstName-${lastName}_$fileName';
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/${Constants.customerContractsFolderName}/$newName';
  }
}
