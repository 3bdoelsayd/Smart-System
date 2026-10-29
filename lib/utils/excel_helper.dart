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
    String? lectureNumber,
    required List<Map<String, dynamic>> students,
    Set<String>? presentIds,
    Set<String>? presentStudentIds,
    Map<String, String>? attendanceTimes,
    String filterType = 'all', // 'all', 'present', 'absent'
    required bool isArabic,
  }) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    sheetObject.appendRow([
      TextCellValue(isArabic ? 'اسم الطالب' : 'Student Name'),
      TextCellValue(isArabic ? 'الرقم الجامعي' : 'Student ID'),
      TextCellValue(isArabic ? 'الشعبة' : 'Division'),
      TextCellValue(isArabic ? 'حالة الحضور' : 'Attendance Status'),
      TextCellValue(isArabic ? 'وقت تسجيل الحضور' : 'Attendance Time'),
    ]);

    Set<String> activePresentIds = presentStudentIds ?? presentIds ?? {};

    for (var student in students) {
      String studentId = student['id']?.toString().trim() ?? '';
      String studentName = student['name']?.toString() ?? '';
      String studentDiv = student['division']?.toString() ?? division;

      bool isPresent = activePresentIds.contains(studentId) || activePresentIds.contains(studentId.toLowerCase());

      if (filterType == 'present' && !isPresent) continue;
      if (filterType == 'absent' && isPresent) continue;

      String status = isPresent
          ? (isArabic ? 'حاضر' : 'Present')
          : (isArabic ? 'غائب' : 'Absent');
      String timeText = isPresent ? (attendanceTimes?[studentId] ?? (isArabic ? 'تم التسجيل' : 'Recorded')) : '--';

      sheetObject.appendRow([
        TextCellValue(studentName),
        TextCellValue(studentId),
        TextCellValue(studentDiv),
        TextCellValue(status),
        TextCellValue(timeText),
      ]);
    }

    String sanitizedSubject = subject.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    String suffix = filterType == 'present'
        ? (isArabic ? "_الحاضرين" : "_Present")
        : filterType == 'absent'
            ? (isArabic ? "_الغائبين" : "_Absent")
            : (isArabic ? "_الجميع" : "_All");

    String fileName;
    if (lectureNumber != null && lectureNumber.toString().trim().isNotEmpty) {
      String lec = lectureNumber.toString().trim();
      fileName = isArabic ? "كشف_حضور_${sanitizedSubject}_محاضرة_$lec$suffix" : "Attendance_${sanitizedSubject}_Lecture_$lec$suffix";
    } else {
      fileName = isArabic ? "كشف_حضور_${sanitizedSubject}_فرقة_$level$suffix" : "Attendance_${sanitizedSubject}_Level_$level$suffix";
    }

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

  static Future<void> downloadStudentTemplate(bool isArabic) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];
    sheet.appendRow([
      TextCellValue(isArabic ? 'الكود (رقم)' : 'ID (Number)'),
      TextCellValue(isArabic ? 'الاسم الرباعي' : 'Full Name'),
      TextCellValue(isArabic ? 'الفرقة (1 أو 2 أو 3 أو 4)' : 'Level (1, 2, 3, or 4)'),
      TextCellValue(isArabic ? 'الشعبة' : 'Division'),
      TextCellValue(isArabic ? 'كلمة المرور (اختياري)' : 'Password (Optional)'),
    ]);
    sheet.appendRow([
      TextCellValue('2024001'),
      TextCellValue('احمد محمد علي حسن'),
      TextCellValue('1'),
      TextCellValue('نظم معلومات الاعمال'),
      TextCellValue('123456'),
    ]);
    await _saveAndShareExcel(excel, "Students_Template");
  }

  static Future<void> downloadDoctorTemplate(bool isArabic) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];
    sheet.appendRow([
      TextCellValue(isArabic ? 'الكود' : 'ID'),
      TextCellValue(isArabic ? 'اسم الدكتور' : 'Doctor Name'),
      TextCellValue(isArabic ? 'كلمة المرور' : 'Password'),
      TextCellValue(isArabic ? 'الفرق (مثال: الفرقة الأولى, الفرقة الثانية)' : 'Levels (e.g. Level 1, Level 2)'),
    ]);
    sheet.appendRow([
      TextCellValue('101'),
      TextCellValue('د. محمود ابراهيم'),
      TextCellValue('doc123'),
      TextCellValue('الفرقة الأولى'),
      TextCellValue('الفرقة الثانية'),
    ]);
    await _saveAndShareExcel(excel, "Doctors_Template");
  }

  static Future<void> _saveAndShareExcel(Excel excel, String fileName) async {
    final fileBytes = excel.save();
    if (fileBytes != null) {
      if (kIsWeb) {
        _downloadWebFile(fileBytes, fileName);
      } else {
        try {
          String? outputFile = await FilePicker.platform.saveFile(
            dialogTitle: 'حفظ ملف الإكسيل',
            fileName: '$fileName.xlsx',
            allowedExtensions: ['xlsx'],
            type: FileType.custom,
          );
          if (outputFile != null) {
            String finalPath = outputFile.endsWith('.xlsx') ? outputFile : '$outputFile.xlsx';
            final file = io.File(finalPath);
            await file.writeAsBytes(fileBytes);
          }
        } catch (e) {
          final directory = await getApplicationDocumentsDirectory();
          final file = io.File('${directory.path}/$fileName.xlsx');
          await file.writeAsBytes(fileBytes);
        }
      }
    }
  }

  static void _downloadWebFile(List<int> bytes, String fileName) {
    final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "$fileName.xlsx")
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
