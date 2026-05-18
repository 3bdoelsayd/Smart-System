import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import '../services/data_service.dart';

class BulkUploadResultsScreen extends StatefulWidget {
  const BulkUploadResultsScreen({super.key});

  @override
  State<BulkUploadResultsScreen> createState() => _BulkUploadResultsScreenState();
}

class _BulkUploadResultsScreenState extends State<BulkUploadResultsScreen> {
  final DataService _ds = DataService();
  bool _isProcessing = false;
  String _statusMessage = "";
  List<Map<String, dynamic>> _parsedData = [];

  String _safeValue(dynamic cell) {
    if (cell == null) return "";
    try {
      final v = cell.value;
      if (v == null) return "";
      
      if (v is TextCellValue) return v.value.toString().trim();
      if (v is IntCellValue) return v.value.toString();
      if (v is DoubleCellValue) {
        double d = v.value.toDouble();
        return d == d.toInt() ? d.toInt().toString() : d.toString();
      }
      return v.toString().trim();
    } catch (e) {
      return "";
    }
  }

  Future<void> _pickAndParseExcel() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = "جاري فتح الملف...";
      _parsedData = [];
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() { _statusMessage = ""; _isProcessing = false; });
        return;
      }

      Uint8List? bytes;
      if (kIsWeb) {
        bytes = result.files.first.bytes;
      } else {
        if (result.files.first.bytes != null) {
          bytes = result.files.first.bytes;
        } else if (result.files.first.path != null) {
          bytes = await io.File(result.files.first.path!).readAsBytes();
        }
      }

      if (bytes == null || bytes.isEmpty) throw "فشل قراءة بيانات الملف.";

      Excel? excel;
      try {
        excel = Excel.decodeBytes(bytes);
      } catch (e) {
        throw "الملف يحتوي على تنسيقات معقدة تمنع القراءة. يرجى إعادة حفظه كـ (Excel Workbook) بسيط.";
      }

      if (excel == null || excel.tables.isEmpty) throw "الملف فارغ.";

      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table];
        if (sheet == null) continue;

        for (var row in sheet.rows) {
          try {
            if (row.length < 2) continue;

            String sId = _safeValue(row[0]);
            String subject = _safeValue(row[1]);

            if (sId.isEmpty || sId.toLowerCase() == "id" || subject.toLowerCase() == "subject") continue;

            String cwStr = row.length > 2 ? _safeValue(row[2]) : "0";
            String finStr = row.length > 3 ? _safeValue(row[3]) : "0";

            _parsedData.add({
              'studentId': sId,
              'subject': subject,
              'coursework': double.tryParse(cwStr) ?? 0.0,
              'final': double.tryParse(finStr) ?? 0.0,
            });
          } catch (e) { continue; }
        }
        if (_parsedData.isNotEmpty) break;
      }

      setState(() {
        if (_parsedData.isEmpty) {
          _statusMessage = "لم يتم العثور على بيانات صالحة. تأكد أن الملف يشبه الصورة التي أرسلتها.";
        } else {
          _statusMessage = "نجاح! تم العثور على ${_parsedData.length} سجل.";
        }
      });

    } catch (e) {
      setState(() => _statusMessage = "⚠️ خطأ: $e");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _uploadData() async {
    if (_parsedData.isEmpty) return;
    setState(() { _isProcessing = true; _statusMessage = "جاري الرفع..."; });
    try {
      await _ds.bulkUploadExamResults(_parsedData);
      setState(() { _statusMessage = "✅ تم الرفع بنجاح!"; _parsedData = []; });
    } catch (e) {
      setState(() => _statusMessage = "❌ فشل: $e");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAr = _ds.isArabic;
    Color color = _ds.isDarkMode ? const Color(0xFF03DAC6) : const Color(0xFF4CAF50);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: const Text('رفع النتائج')),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              if (_statusMessage.isNotEmpty) _buildStatusBox(color),
              const Spacer(),
              if (_parsedData.isEmpty)
                _buildButton(color, "اختر ملف الـ Excel", _pickAndParseExcel)
              else
                Column(children: [
                  _buildButton(Colors.blue, "تأكيد الرفع لـ Firebase", _uploadData),
                  TextButton(onPressed: () => setState(() { _parsedData = []; _statusMessage = ""; }), child: const Text("إلغاء")),
                ]),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBox(Color color) {
    bool isError = _statusMessage.contains("⚠️") || _statusMessage.contains("❌");
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: isError ? Colors.red.withAlpha(20) : color.withAlpha(20), borderRadius: BorderRadius.circular(15), border: Border.all(color: isError ? Colors.red.withAlpha(50) : color.withAlpha(50))),
      child: Text(_statusMessage, textAlign: TextAlign.center, style: TextStyle(color: isError ? Colors.red : (_ds.isDarkMode ? Colors.white : Colors.black87), fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildButton(Color bg, String label, VoidCallback action) {
    return SizedBox(width: double.infinity, child: ElevatedButton(
      onPressed: _isProcessing ? null : action,
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), backgroundColor: bg, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      child: _isProcessing ? const CircularProgressIndicator(color: Colors.white) : Text(label),
    ));
  }
}
