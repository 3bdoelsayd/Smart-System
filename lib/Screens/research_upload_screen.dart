import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/data_service.dart';

class ResearchUploadScreen extends StatefulWidget {
  const ResearchUploadScreen({super.key});

  @override
  State<ResearchUploadScreen> createState() => _ResearchUploadScreenState();
}

class _ResearchUploadScreenState extends State<ResearchUploadScreen> {
  String? _selectedSubject;
  String? _selectedFileName;
  PlatformFile? _pickedFile;
  final DataService _ds = DataService();
  bool _isUploading = false;

  Future<void> _pickFile() async {
    try {
      // تم تغيير طريقة اختيار الملف لتكون أكثر شمولاً
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // السماح باختيار أي نوع في البداية لحل مشكلة الحظر
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        final ext = file.extension?.toLowerCase();
        
        // التحقق من الامتداد يدوياً
        if (ext == 'pdf' || ext == 'docx' || ext == 'doc') {
          setState(() {
            _pickedFile = file;
            _selectedFileName = file.name;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_ds.isArabic ? 'يرجى اختيار ملف PDF أو Word فقط' : 'Please select PDF or Word files only')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_ds.isArabic ? 'حدث خطأ أثناء اختيار الملف: $e' : 'Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    bool isAr = _ds.isArabic;
    if (_selectedSubject == null || _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? 'يرجى اختيار المادة واختيار ملف' : 'Please select subject and file'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      await _ds.uploadResearchToRemote(
        subject: _selectedSubject!,
        file: _pickedFile!,
        title: '',
      );
      
      if (mounted) {
        setState(() => _isUploading = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
            content: Text(isAr ? 'تم إرسال الملف بنجاح' : 'File sent successfully'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isAr ? 'حسناً' : 'OK'))
            ],
          ),
        ).then((_) {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? 'فشل الإرسال: $e' : 'Upload failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ds,
      builder: (context, _) {
        bool isAr = _ds.isArabic;
        bool isDark = _ds.isDarkMode;
        
        final Color primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);
        final Color bgColor = isDark ? const Color(0xFF121212) : Colors.white;
        final Color surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final Color textColor = isDark ? Colors.white : Colors.black87;
        
        final subjects = _ds.studentSubjects;

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: bgColor,
            appBar: AppBar(
              elevation: 0,
              centerTitle: true,
              title: Text(_ds.translate('upload_research'), style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: isDark ? const Color(0xFF1A1A1A) : primaryColor,
              foregroundColor: Colors.white,
            ),
            body: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _ds.translate('select_subject'), 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    dropdownColor: surfaceColor,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade50,
                    ),
                    hint: Text(
                      _ds.translate('select_subject'),
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                    ),
                    items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => _selectedSubject = val),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    _ds.translate('pick_file'), 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickFile,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withAlpha(5) : primaryColor.withAlpha(13),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: primaryColor.withAlpha(isDark ? 100 : 51), 
                          width: 2
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _pickedFile != null ? Icons.insert_drive_file : Icons.cloud_upload_outlined,
                            size: 50, 
                            color: primaryColor
                          ),
                          const SizedBox(height: 15),
                          Text(
                            _selectedFileName ?? _ds.translate('pick_file'),
                            style: TextStyle(
                              color: _selectedFileName != null ? primaryColor : (isDark ? Colors.white38 : Colors.grey), 
                              fontWeight: _selectedFileName != null ? FontWeight.bold : FontWeight.normal
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  _isUploading 
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor, 
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))
                          ),
                          child: Text(
                            isAr ? 'إرسال البحث' : 'Send Research',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
