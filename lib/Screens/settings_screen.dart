import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DataService _ds = DataService();

  void _showDoctorProfileDialog(BuildContext context, Color primaryColor, bool isDark) {
    final doc = _ds.currentDoctor;
    final phoneController = TextEditingController(text: doc?['phone'] ?? '');
    final personalEmailController = TextEditingController(text: doc?['personalEmail'] ?? '');
    
    PlatformFile? pickedImageFile;
    bool isUploading = false;
    bool isAr = _ds.isArabic;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isAr ? "الملف الشخصي والبيانات" : "Doctor Profile", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                  icon: const Icon(Icons.image_rounded),
                  label: Text(pickedImageFile != null ? (isAr ? "تم اختيار صورة" : "Image Selected") : (isAr ? "اختر صورة شخصية من الملفات" : "Pick Image from Files")),
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                    if (result != null && result.files.single != null) {
                      setDialogState(() {
                        pickedImageFile = result.files.single;
                      });
                    }
                  },
                ),
                if (pickedImageFile != null) ...[
                  const SizedBox(height: 8),
                  Text(pickedImageFile!.name, style: const TextStyle(fontSize: 12, color: Colors.green)),
                ],
                const SizedBox(height: 15),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: isAr ? "رقم الهاتف" : "Phone Number",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: personalEmailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: isAr ? "البريد الإلكتروني الشخصي" : "Personal Email",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isAr ? "إلغاء" : "Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: isUploading ? null : () async {
                setDialogState(() => isUploading = true);
                String? photoUrl = doc?['photoUrl'];
                if (pickedImageFile != null) {
                  photoUrl = await _ds.uploadAvatarFile(pickedImageFile!);
                }

                await _ds.updateDoctorProfile(
                  phone: phoneController.text.trim(),
                  personalEmail: personalEmailController.text.trim(),
                  photoUrl: photoUrl,
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? "تم تحديث البيانات بنجاح" : "Profile updated")));
                }
              },
              child: isUploading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(isAr ? "حفظ" : "Save", style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentProfileDialog(BuildContext context, Color primaryColor, bool isDark) {
    final student = _ds.currentStudent;
    final phoneController = TextEditingController(text: student?['phone'] ?? '');
    final personalEmailController = TextEditingController(text: student?['personalEmail'] ?? '');
    
    PlatformFile? pickedImageFile;
    bool isUploading = false;
    bool isAr = _ds.isArabic;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isAr ? "الملف الشخصي والبيانات" : "Student Profile", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                  icon: const Icon(Icons.image_rounded),
                  label: Text(pickedImageFile != null ? (isAr ? "تم اختيار صورة" : "Image Selected") : (isAr ? "اختر صورة شخصية من الملفات" : "Pick Image from Files")),
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                    if (result != null && result.files.single != null) {
                      setDialogState(() {
                        pickedImageFile = result.files.single;
                      });
                    }
                  },
                ),
                if (pickedImageFile != null) ...[
                  const SizedBox(height: 8),
                  Text(pickedImageFile!.name, style: const TextStyle(fontSize: 12, color: Colors.green)),
                ],
                const SizedBox(height: 15),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: isAr ? "رقم الهاتف" : "Phone Number",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: personalEmailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: isAr ? "البريد الإلكتروني الشخصي" : "Personal Email",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isAr ? "إلغاء" : "Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: isUploading ? null : () async {
                setDialogState(() => isUploading = true);
                String? photoUrl = student?['photoUrl'];
                if (pickedImageFile != null) {
                  photoUrl = await _ds.uploadAvatarFile(pickedImageFile!);
                }

                await _ds.updateStudentProfile(
                  phone: phoneController.text.trim(),
                  personalEmail: personalEmailController.text.trim(),
                  photoUrl: photoUrl,
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? "تم تحديث البيانات بنجاح" : "Profile updated")));
                }
              },
              child: isUploading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(isAr ? "حفظ" : "Save", style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, Color primaryColor, bool isDark) {
    final TextEditingController passController = TextEditingController();
    bool isAr = _ds.isArabic;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isAr ? "تغيير كلمة المرور" : "Change Password", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
          content: TextField(
            controller: passController,
            obscureText: true,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: isAr ? "كلمة المرور الجديدة" : "New Password",
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: isDark ? Colors.black26 : Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isAr ? "إلغاء" : "Cancel", style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (passController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isAr ? "يجب أن تكون 6 أحرف على الأقل" : "Must be at least 6 characters"))
                  );
                  return;
                }
                
                try {
                  bool success = await _ds.updatePassword(passController.text);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? (isAr ? "تم التحديث بنجاح" : "Updated successfully") : (isAr ? "فشل التحديث" : "Update failed")),
                        backgroundColor: success ? Colors.green : Colors.red,
                      )
                    );
                  }
                } catch (e) {
                  if (mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isAr ? "تحديث" : "Update"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ds,
      builder: (context, _) {
        bool isAr = _ds.isArabic;
        bool isDark = _ds.isDarkMode;
        Color primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);
        
        // التحقق مما إذا كان المستخدم أدمن
        bool isAdmin = _ds.currentAdmin != null;

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
            appBar: AppBar(
              title: Text(_ds.translate('settings')),
              backgroundColor: isDark ? const Color(0xFF1A1A1A) : primaryColor,
              foregroundColor: Colors.white,
              centerTitle: true,
            ),
            body: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_ds.currentStudent != null || _ds.currentDoctor != null || _ds.currentAdmin != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDark ? 50 : 10), blurRadius: 10)],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: primaryColor.withAlpha(30),
                              backgroundImage: _ds.getAvatarImageProvider(_ds.currentStudent?['photoUrl'] ?? _ds.currentDoctor?['photoUrl'] ?? _ds.currentAdmin?['photoUrl']),
                              child: (_ds.currentStudent?['photoUrl'] ?? _ds.currentDoctor?['photoUrl'] ?? _ds.currentAdmin?['photoUrl'] ?? '').toString().isEmpty 
                                ? Icon(Icons.person, size: 30, color: primaryColor) 
                                : null,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _ds.currentStudent?['name'] ?? _ds.currentDoctor?['name'] ?? _ds.currentAdmin?['name'] ?? 'مستخدم',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _ds.currentStudent != null ? ('ID: ${_ds.currentStudent?['id']}') : (_ds.currentDoctor != null ? (_ds.currentDoctor?['email'] ?? '') : 'Admin'),
                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    _buildSectionTitle(isAr ? 'اللغة' : 'Language', isDark),
                    _buildSettingCard(
                      child: ListTile(
                        title: Text(isAr ? 'اللغة العربية' : 'Arabic Language', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                        leading: Icon(Icons.language_rounded, color: primaryColor),
                        trailing: Switch(
                          activeColor: primaryColor,
                          value: isAr,
                          onChanged: (val) => _ds.toggleLanguage(val),
                        ),
                      ),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildSectionTitle(isAr ? 'المظهر' : 'Appearance', isDark),
                    _buildSettingCard(
                      child: ListTile(
                        title: Text(_ds.translate('dark_mode'), style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                        leading: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: primaryColor),
                        trailing: Switch(
                          activeColor: primaryColor,
                          value: isDark,
                          onChanged: (val) async {
                            await _ds.toggleDarkMode(val);
                            if (mounted) {
                              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                            }
                          },
                        ),
                      ),
                      isDark: isDark,
                    ),

                    if (_ds.currentStudent != null || _ds.currentDoctor != null) ...[
                      const SizedBox(height: 10),
                      _buildSectionTitle(isAr ? 'الملف الشخصي والبيانات' : 'Profile & Info', isDark),
                      _buildSettingCard(
                        child: ListTile(
                          title: Text(isAr ? "تعديل البيانات الشخصية والصورة" : "Edit Profile Info", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                          leading: Icon(Icons.person_outline_rounded, color: primaryColor),
                          trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: primaryColor),
                          onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                        ),
                        isDark: isDark,
                      ),
                    ],
                    
                    const SizedBox(height: 10),
                    _buildSectionTitle(isAr ? 'الأمان' : 'Security', isDark),
                    _buildSettingCard(
                      child: ListTile(
                        title: Text(isAr ? "تغيير كلمة المرور" : "Change Password", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                        leading: Icon(Icons.lock_reset_rounded, color: primaryColor),
                        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: primaryColor),
                        onTap: () => _showChangePasswordDialog(context, primaryColor, isDark),
                      ),
                      isDark: isDark,
                    ),

                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _ds.clearSession();
                        if (mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/start', (route) => false);
                        }
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(_ds.translate('logout')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withAlpha(26),
                        foregroundColor: Colors.red,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          isAr ? "المطور الرئيسي" : "Lead Developer",
                          style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey.shade500, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Abdo Elsherbiny",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.grey.shade600, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey.shade700)),
    );
  }

  Widget _buildSettingCard({required Widget child, required bool isDark}) {
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: isDark ? BorderSide(color: Colors.white.withAlpha(13)) : BorderSide.none),
      child: child,
    );
  }
}
