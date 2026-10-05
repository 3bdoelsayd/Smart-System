import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final DataService _ds = DataService();
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  PlatformFile? _pickedFile;
  Uint8List? _previewBytes;
  String? _currentPhotoUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final isStudent = _ds.currentStudent != null;
    final userData = isStudent ? _ds.currentStudent : _ds.currentDoctor;

    _phoneController = TextEditingController(text: userData?['phone'] ?? '');
    _emailController = TextEditingController(text: userData?['personalEmail'] ?? userData?['email'] ?? '');
    _currentPhotoUrl = userData?['photoUrl'];
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.single != null) {
        setState(() {
          _pickedFile = result.files.single;
          _previewBytes = result.files.single.bytes;
        });
      }
    } catch (e) {
      debugPrint("Pick image error: $e");
    }
  }

  void _saveProfile() async {
    setState(() => _isSaving = true);
    bool isAr = _ds.isArabic;

    try {
      String? photoUrl = _currentPhotoUrl;
      if (_pickedFile != null) {
        photoUrl = await _ds.uploadAvatarFile(_pickedFile!);
      }

      if (_ds.currentStudent != null) {
        await _ds.updateStudentProfile(
          phone: _phoneController.text.trim(),
          personalEmail: _emailController.text.trim(),
          photoUrl: photoUrl,
        );
      } else if (_ds.currentDoctor != null) {
        await _ds.updateDoctorProfile(
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          photoUrl: photoUrl,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? '✅ تم تحديث الملف الشخصي بنجاح' : 'Profile updated successfully', style: GoogleFonts.cairo()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? '❌ فشل التحديث: $e' : 'Update failed: $e', style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAr = _ds.isArabic;
    bool isDark = _ds.isDarkMode;
    Color primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);
    Color surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final isStudent = _ds.currentStudent != null;
    final userData = isStudent ? _ds.currentStudent : _ds.currentDoctor;
    final name = userData?['name'] ?? 'مستخدم';
    final roleTitle = isStudent ? (isAr ? 'طالب جامعي' : 'Student') : (isAr ? 'عضو هيئة تدريس' : 'Doctor');

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FE),
        appBar: AppBar(
          title: Text(isAr ? 'تعديل الملف الشخصي' : 'Edit Profile', style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : primaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // --- معاينة الصورة الشخصية الحية (Live Preview) ---
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _previewBytes != null
                            ? MemoryImage(_previewBytes!)
                            : _ds.getAvatarImageProvider(_currentPhotoUrl),
                        child: (_previewBytes == null && (_currentPhotoUrl ?? '').isEmpty)
                            ? Icon(Icons.person, size: 60, color: primaryColor)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: primaryColor,
                        radius: 18,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Text(
                name,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
              Text(
                roleTitle,
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey),
              ),
              const SizedBox(height: 30),

              // --- كارت إدخال البيانات ---
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 50 : 10), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'معلومات التواصل والاتصال' : 'Contact Information',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: isAr ? "رقم الهاتف (للواتساب والتواصل)" : "Phone Number",
                        labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                        prefixIcon: Icon(Icons.phone_rounded, color: primaryColor),
                        filled: true,
                        fillColor: isDark ? Colors.black26 : Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: isAr ? "البريد الإلكتروني الشخصي" : "Personal Email",
                        labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                        prefixIcon: Icon(Icons.email_rounded, color: primaryColor),
                        filled: true,
                        fillColor: isDark ? Colors.black26 : Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // --- زر الحفظ ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving ? const SizedBox() : const Icon(Icons.save_rounded, color: Colors.white),
                  label: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isAr ? 'حفظ التعديلات' : 'Save Changes', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
