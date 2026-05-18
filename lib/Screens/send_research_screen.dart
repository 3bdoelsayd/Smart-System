import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/data_service.dart';

class SendResearchScreen extends StatefulWidget {
  const SendResearchScreen({super.key});

  @override
  State<SendResearchScreen> createState() => _SendResearchScreenState();
}

class _SendResearchScreenState extends State<SendResearchScreen> {
  final DataService _dataService = DataService();
  String? _selectedSubject;
  String? _selectedFileName;
  PlatformFile? _pickedFile;
  bool _isLoading = false;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        setState(() {
          _pickedFile = file;
          _selectedFileName = file.name;
        });
      }
    } catch (e) {
      debugPrint("File picker error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ في اختيار الملف')));
      }
    }
  }

  Future<void> _submit() async {
    final isAr = _dataService.isArabic;
    if (_selectedSubject == null || _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? 'يرجى اختيار المادة والملف' : 'Please select subject and file'),
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _dataService.uploadResearchToRemote(
        subject: _selectedSubject!,
        file: _pickedFile!,
        title: '',
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? 'تم إرسال البحث بنجاح' : 'Research sent successfully'),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context);
    } catch (e) {
       debugPrint('Upload failed: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? 'فشل الإرسال' : 'Upload failed'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _dataService.isArabic;
    final isDark = _dataService.isDarkMode;

    final Color primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);
    final Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final Color surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color labelColor = isDark ? Colors.white70 : Colors.black87;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(isAr ? 'إرسال للمراجعة' : 'Submit Research'),
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(isAr ? 'اختيار المادة العلمية' : 'Select Subject', labelColor),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 50 : 10), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: DropdownButtonFormField<String>(
                  dropdownColor: surfaceColor,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.book_rounded, color: primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  hint: Text(
                    isAr ? 'اختر المادة' : 'Choose subject', 
                    style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)
                  ),
                  items: _dataService.allSubjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setState(() => _selectedSubject = val),
                ),
              ),
              const SizedBox(height: 35),
              _sectionHeader(isAr ? 'رفع ملف البحث' : 'Pick File', labelColor),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    border: Border.all(
                      color: _pickedFile != null ? Colors.green.withAlpha(100) : primaryColor.withAlpha(50), 
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 40 : 10), blurRadius: 15, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: (_pickedFile != null ? Colors.green : primaryColor).withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _pickedFile != null ? Icons.check_circle_rounded : Icons.cloud_upload_rounded, 
                          size: 70, 
                          color: _pickedFile != null ? Colors.green : primaryColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _selectedFileName ?? (isAr ? 'اضغط لاختيار ملف (PDF / DOCX)' : 'Tap to pick (PDF / DOCX)'),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 15,
                          fontWeight: _pickedFile != null ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_pickedFile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            "${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB",
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 65,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    elevation: 10,
                    shadowColor: primaryColor.withAlpha(100),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isAr ? 'إرسال للمراجعة الآن' : 'Submit Now', 
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.send_rounded),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: const Color(0xFF673AB7), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 17)),
      ],
    );
  }
}
