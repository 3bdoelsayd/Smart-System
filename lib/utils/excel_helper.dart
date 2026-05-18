import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'dart:io' as io;

class ExcelHelper {
  static String _safeValue(dynamic cell) {
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
      if (v is BoolCellValue) return v.value.toString();
      return v.toString().trim();
    } catch (e) {
      return "";
    }
  }

  static Future<List<List<String>>> pickAndParseExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null) {
      Uint8List? bytes;
      if (kIsWeb) {
        bytes = result.files.single.bytes;
      } else {
        if (result.files.single.bytes != null) {
          bytes = result.files.single.bytes;
        } else if (result.files.single.path != null) {
          bytes = await io.File(result.files.single.path!).readAsBytes();
        }
      }

      if (bytes != null) {
        var excel = Excel.decodeBytes(bytes);
        List<List<String>> allRows = [];

        for (var table in excel.tables.keys) {
          var rows = excel.tables[table]!.rows;
          // Skip header row (index 0)
          for (int i = 1; i < rows.length; i++) {
            var row = rows[i];
            List<String> rowData = row.map((cell) => _safeValue(cell)).toList();
            if (rowData.any((element) => element.isNotEmpty)) {
              allRows.add(rowData);
            }
          }
        }
        return allRows;
      }
    }
    return [];
  }

  static Future<void> exportAttendance(List<Map<String, dynamic>> data, String fileName) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    sheetObject.appendRow([
      TextCellValue('Student Name'),
      TextCellValue('Student ID'),
      TextCellValue('Time'),
    ]);

    for (var item in data) {
      sheetObject.appendRow([
        TextCellValue(item['studentName']?.toString() ?? ''),
        TextCellValue(item['studentId']?.toString() ?? ''),
        TextCellValue(item['time']?.toString() ?? ''),
      ]);
    }
    await _saveAndShareExcel(excel, fileName);
  }

  static Future<void> exportAttendanceToExcel({
    required String subject,
    required String level,
    required String division,
    required List<Map<String, dynamic>> students,
    required bool isArabic,
  }) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    sheetObject.appendRow([
      TextCellValue(isArabic ? 'اسم الطالب' : 'Student Name'),
      TextCellValue(isArabic ? 'الرقم الجامعي' : 'Student ID'),
      TextCellValue(isArabic ? 'الحالة' : 'Status'),
    ]);

    for (var student in students) {
      sheetObject.appendRow([
        TextCellValue(student['name']?.toString() ?? ''),
        TextCellValue(student['id']?.toString() ?? ''),
        TextCellValue(isArabic ? 'حاضر' : 'Present'),
      ]);
    }

    String fileName = "${subject}_Level_${level}_Attendance";
    await _saveAndShareExcel(excel, fileName);
  }

  static Future<void> exportGradesToExcel({
    required String subject,
    required String level,
    required String division,
    required String doctorName,
    required List<Map<String, dynamic>> students,
    required Map<String, double> gradesMap,
    required bool isArabic,
  }) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    sheetObject.appendRow([
      TextCellValue(isArabic ? 'اسم الطالب' : 'Student Name'),
      TextCellValue(isArabic ? 'الرقم الجامعي' : 'Student ID'),
      TextCellValue(isArabic ? 'الدرجة' : 'Grade'),
    ]);

    for (var student in students) {
      String id = student['id']?.toString() ?? '';
      sheetObject.appendRow([
        TextCellValue(student['name']?.toString() ?? ''),
        TextCellValue(id),
        TextCellValue(gradesMap[id]?.toString() ?? '--'),
      ]);
    }

    String fileName = "${subject}_Level_${level}_Grades";
    await _saveAndShareExcel(excel, fileName);
  }

  static Future<void> _saveAndShareExcel(Excel excel, String fileName) async {
    final fileBytes = excel.save();
    if (fileBytes != null) {
      if (kIsWeb) {
        _downloadWebFile(fileBytes, fileName);
      } else {
        final directory = await getTemporaryDirectory();
        final file = io.File('${directory.path}/$fileName.xlsx');
        await file.writeAsBytes(fileBytes);
        await Share.shareXFiles([XFile(file.path)], text: 'Exported Data');
      }
    }
  }

  static void _downloadWebFile(List<int> bytes, String fileName) {
    final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "$fileName.xlsx")
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
