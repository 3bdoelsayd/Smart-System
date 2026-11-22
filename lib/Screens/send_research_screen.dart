import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/data_service.dart';

class SendResearchScreen extends StatefulWidget {
  const SendResearchScreen({super.key});

  @override
  State<SendResearchScreen> createState() => _SendResearchScreenState();
}

class _SendResearchScreenState extends State<SendResearchScreen> {
  final DataService _ds = DataService();

  // Step 1: Subject selection
  String? _selectedSubject;

  // Step 2: Recipient selection (doctor or TA)
  String? _selectedRecipientType; // 'doctor' or 'ta'
  String? _selectedRecipientId;
  String? _selectedRecipientName;

  // Step 3: Topic selection
  String? _selectedTopicId;
  String? _selectedTopicTitle;
  List<Map<String, dynamic>> _availableTopics = [];

  // Step 4: File upload
  PlatformFile? _pickedFile;
  String? _selectedFileName;
  bool _isLoading = false;

  int _currentStep = 0; // 0: subject, 1: recipient, 2: topic, 3: file

  @override
  void dispose() {
    super.dispose();
  }

  void _loadTopics() {
    if (_selectedSubject == null || _selectedRecipientType == null) {
      setState(() => _availableTopics = []);
      return;
    }

    _ds.getResearchTopics(subject: _selectedSubject, onlyActive: true).listen((topics) {
      if (mounted) {
        // Filter by recipient
        final filtered = topics.where((t) {
          final isExpired = t['isExpired'] ?? false;
          if (isExpired) return false;

          // Match doctor or TA
          if (_selectedRecipientType == 'doctor') {
            return t['doctorId'] == _selectedRecipientId;
          } else {
            return t['taId'] == _selectedRecipientId;
          }
        }).toList();

        setState(() => _availableTopics = filtered);
      }
    });
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFile = result.files.single;
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_ds.isArabic ? 'خطأ في اختيار الملف' : 'Error picking file')),
        );
      }
    }
  }

  Future<void> _submit() async {
    final isAr = _ds.isArabic;

    if (_selectedSubject == null || _pickedFile == null || _selectedTopicId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? 'يرجى إكمال جميع الخطوات' : 'Please complete all steps')),
      );
      return;
    }

    // Validate deadline
    final isAccepting = await _ds.isTopicAcceptingSubmissions(_selectedTopicId!);
    if (!isAccepting) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'عذراً، انتهى موعد إرسال الأبحاث' : 'Deadline has passed'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _ds.uploadResearchToRemote(
        subject: _selectedSubject!,
        file: _pickedFile!,
        title: _selectedTopicTitle ?? '',
        recipientType: _selectedRecipientType ?? 'doctor',
        researchTopicId: _selectedTopicId, // ✅ Pass topic ID
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تم إرسال البحث بنجاح ✓' : 'Research sent successfully ✓'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'فشل الإرسال' : 'Upload failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ds,
      builder: (context, _) {
        final isAr = _ds.isArabic;
        final isDark = _ds.isDarkMode;
        final primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
            appBar: AppBar(
              title: Text(isAr ? 'إرسال بحث جديد' : 'Submit Research',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              backgroundColor: isDark ? const Color(0xFF1A1A1A) : primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            body: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildStepIndicator(primaryColor, isDark, isAr),
                        const SizedBox(height: 30),
                        if (_currentStep == 0) _buildSubjectSelection(primaryColor, isDark, isAr),
                        if (_currentStep == 1) _buildRecipientSelection(primaryColor, isDark, isAr),
                        if (_currentStep == 2) _buildTopicSelection(primaryColor, isDark, isAr),
                        if (_currentStep == 3) _buildFileUpload(primaryColor, isDark, isAr),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildStepIndicator(Color color, bool isDark, bool isAr) {
    final steps = [
      {'icon': Icons.book, 'label': isAr ? 'المادة' : 'Subject'},
      {'icon': Icons.person, 'label': isAr ? 'المستلم' : 'Recipient'},
      {'icon': Icons.topic, 'label': isAr ? 'العنوان' : 'Topic'},
      {'icon': Icons.upload_file, 'label': isAr ? 'الملف' : 'File'},
    ];

    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;

        return Expanded(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isCompleted || isActive ? color : Colors.grey.withAlpha(77),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? Icons.check : steps[index]['icon'] as IconData,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                steps[index]['label'] as String,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? color : Colors.grey,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSubjectSelection(Color color, bool isDark, bool isAr) {
    final subjects = _ds.studentSubjects.where((s) => s.isNotEmpty).toList();

    if (subjects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            isAr ? 'لا توجد مواد مسجلة' : 'No subjects registered',
            style: GoogleFonts.cairo(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'اختر المادة الدراسية' : 'Select Subject',
          style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final subject = subjects[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: isDark ? 0 : 2,
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: isDark ? BorderSide(color: Colors.white.withAlpha(13)) : BorderSide.none,
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: color.withAlpha(26),
                  child: Icon(Icons.book, color: color),
                ),
                title: Text(
                  subject,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                trailing: Icon(Icons.arrow_forward_ios, color: color, size: 18),
                onTap: () {
                  setState(() {
                    _selectedSubject = subject;
                    _currentStep = 1;
                  });
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecipientSelection(Color color, bool isDark, bool isAr) {
    final studentLevel = _ds.currentStudent?['level'] ?? 'level_1';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _currentStep = 0),
            ),
            Expanded(
              child: Text(
                isAr ? 'اختر المستلم' : 'Select Recipient',
                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.book, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                '${isAr ? "المادة المختارة:" : "Selected Subject:"} ${_selectedSubject ?? ""}',
                style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FutureBuilder<List<dynamic>>(
          future: Future.wait([
            _ds.getInstituteCoursesColl(studentLevel).get(),
            _ds.getInstituteCoursesColl('level_1').get(),
            _ds.getInstituteCoursesColl('level_2').get(),
            _ds.getInstituteCoursesColl('level_3').get(),
            _ds.getInstituteCoursesColl('level_4').get(),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allCourseDocs = (snapshot.data as List?)?.expand((qs) => (qs as QuerySnapshot).docs).toList() ?? [];

            final matchingCourses = allCourseDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final courseName = (data['name'] ?? '').toString().trim().toLowerCase();
              final selSubject = (_selectedSubject ?? '').trim().toLowerCase();
              return courseName == selSubject;
            }).toList();

            Set<String> doctorIds = {};
            Set<String> taIds = {};

            for (var cDoc in matchingCourses) {
              final cData = cDoc.data() as Map<String, dynamic>;
              if (cData['doctor_id'] != null && cData['doctor_id'].toString().isNotEmpty) {
                doctorIds.add(cData['doctor_id'].toString());
              }
              if (cData['ta_id'] != null && cData['ta_id'].toString().isNotEmpty) {
                taIds.add(cData['ta_id'].toString());
              }
              if (cData['ta_ids'] is List) {
                for (var id in cData['ta_ids']) {
                  if (id != null && id.toString().isNotEmpty) taIds.add(id.toString());
                }
              }
            }

            return StreamBuilder<QuerySnapshot>(
              stream: _ds.instituteDoctorsColl.snapshots(),
              builder: (context, docSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: _ds.instituteTasColl.snapshots(),
                  builder: (context, taSnap) {
                    final allDoctors = docSnap.data?.docs ?? [];
                    final allTas = taSnap.data?.docs ?? [];

                    final recipientDoctors = allDoctors.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final docUid = data['uid'] ?? doc.id;
                      final docId = data['id']?.toString() ?? '';
                      final subjects = List<String>.from(data['subjects'] ?? []);
                      
                      bool isAssignedInCourse = doctorIds.contains(docUid) || doctorIds.contains(docId) || doctorIds.contains(doc.id);
                      bool teachesSubject = subjects.any((s) => s.trim().toLowerCase() == _selectedSubject?.trim().toLowerCase());

                      return isAssignedInCourse || (doctorIds.isEmpty && teachesSubject);
                    }).toList();

                    final recipientTas = allTas.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final taUid = data['uid'] ?? doc.id;
                      final taId = data['id']?.toString() ?? '';
                      final subjects = List<String>.from(data['subjects'] ?? []);
                      
                      bool isAssignedInCourse = taIds.contains(taUid) || taIds.contains(taId) || taIds.contains(doc.id);
                      bool teachesSubject = subjects.any((s) => s.trim().toLowerCase() == _selectedSubject?.trim().toLowerCase());

                      return isAssignedInCourse || (taIds.isEmpty && teachesSubject);
                    }).toList();

                    // Sort alphabetically
                    recipientDoctors.sort((a, b) => ((a.data() as Map<String, dynamic>)['name'] ?? '').toString().compareTo(((b.data() as Map<String, dynamic>)['name'] ?? '').toString()));
                    recipientTas.sort((a, b) => ((a.data() as Map<String, dynamic>)['name'] ?? '').toString().compareTo(((b.data() as Map<String, dynamic>)['name'] ?? '').toString()));

                    if (recipientDoctors.isEmpty && recipientTas.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off_rounded, size: 60, color: Colors.grey.withAlpha(128)),
                              const SizedBox(height: 15),
                              Text(
                                isAr ? 'لم يتم تحديد دكتور أو معيد لهذه المادة بعد' : 'No doctor or TA assigned to this subject yet',
                                style: GoogleFonts.cairo(color: Colors.grey, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (recipientDoctors.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10, top: 5),
                            child: Text(
                              isAr ? 'أعضاء هيئة التدريس (الدكتور):' : 'Doctors:',
                              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                            ),
                          ),
                          ...recipientDoctors.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final docName = data['name'] ?? 'دكتور المادة';
                            final docUid = data['uid'] ?? doc.id;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: isDark ? 0 : 2,
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: isDark ? BorderSide(color: Colors.white.withAlpha(13)) : BorderSide.none,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.blue.withAlpha(30),
                                  child: const Icon(Icons.school_rounded, color: Colors.blue, size: 26),
                                ),
                                title: Text(
                                  '${isAr ? "دكتور:" : "Doctor:"} $docName',
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                subtitle: Text(
                                  isAr ? 'أستاذ المادة المسئول' : 'Course Professor',
                                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                                ),
                                trailing: Icon(Icons.arrow_forward_ios_rounded, color: color, size: 18),
                                onTap: () {
                                  setState(() {
                                    _selectedRecipientType = 'doctor';
                                    _selectedRecipientId = docUid;
                                    _selectedRecipientName = docName;
                                    _currentStep = 2;
                                    _loadTopics();
                                  });
                                },
                              ),
                            );
                          }),
                        ],

                        const SizedBox(height: 10),

                        if (recipientTas.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10, top: 5),
                            child: Text(
                              isAr ? 'الهيئة المعاونة (المعيد):' : 'Teaching Assistants (TAs):',
                              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal),
                            ),
                          ),
                          ...recipientTas.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final taName = data['name'] ?? 'معيد المادة';
                            final taUid = data['uid'] ?? doc.id;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: isDark ? 0 : 2,
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: isDark ? BorderSide(color: Colors.white.withAlpha(13)) : BorderSide.none,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.teal.withAlpha(30),
                                  child: const Icon(Icons.badge_rounded, color: Colors.teal, size: 26),
                                ),
                                title: Text(
                                  '${isAr ? "معيد:" : "TA:"} $taName',
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                subtitle: Text(
                                  isAr ? 'معيد المادة المسئول' : 'Teaching Assistant',
                                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                                ),
                                trailing: Icon(Icons.arrow_forward_ios_rounded, color: Colors.teal, size: 18),
                                onTap: () {
                                  setState(() {
                                    _selectedRecipientType = 'ta';
                                    _selectedRecipientId = taUid;
                                    _selectedRecipientName = taName;
                                    _currentStep = 2;
                                    _loadTopics();
                                  });
                                },
                              ),
                            );
                          }),
                        ],
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildTopicSelection(Color color, bool isDark, bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _currentStep = 1),
            ),
            Expanded(
              child: Text(
                isAr ? 'اختر عنوان البحث' : 'Select Topic',
                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${isAr ? "المستلم" : "Recipient"}: $_selectedRecipientName',
                  style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_availableTopics.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.topic_outlined, size: 60, color: Colors.grey.withAlpha(128)),
                  const SizedBox(height: 15),
                  Text(
                    isAr ? 'لا توجد عناوين متاحة حالياً' : 'No topics available',
                    style: GoogleFonts.cairo(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _availableTopics.length,
            itemBuilder: (context, index) {
              final topic = _availableTopics[index];
              final title = topic['title'] ?? '';
              final topicId = topic['id'] ?? '';
              final deadline = topic['deadline'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(topic['deadline'])
                  : null;
              final remainingDays = topic['remainingDays'];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: isDark ? 0 : 2,
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: isDark ? BorderSide(color: Colors.white.withAlpha(13)) : BorderSide.none,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: color.withAlpha(26),
                    child: Icon(Icons.assignment, color: color),
                  ),
                  title: Text(
                    title,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (deadline != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${isAr ? "آخر موعد" : "Deadline"}: ${deadline.year}/${deadline.month}/${deadline.day}',
                          style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                      if (remainingDays != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: remainingDays <= 3 ? Colors.red : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isAr ? 'متبقي $remainingDays يوم' : '$remainingDays days left',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: remainingDays <= 3 ? Colors.red : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, color: color, size: 18),
                  onTap: () {
                    setState(() {
                      _selectedTopicId = topicId;
                      _selectedTopicTitle = title;
                      _currentStep = 3;
                    });
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildFileUpload(Color color, bool isDark, bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _currentStep = 2),
            ),
            Expanded(
              child: Text(
                isAr ? 'رفع الملف' : 'Upload File',
                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withAlpha(51)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isAr ? 'ملخص الإرسال' : 'Summary',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _summaryRow(Icons.book, isAr ? 'المادة' : 'Subject', _selectedSubject ?? '', isAr),
              _summaryRow(Icons.person, isAr ? 'المستلم' : 'To', _selectedRecipientName ?? '', isAr),
              _summaryRow(Icons.topic, isAr ? 'العنوان' : 'Topic', _selectedTopicTitle ?? '', isAr),
            ],
          ),
        ),
        const SizedBox(height: 25),
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color, width: 2, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Icon(
                  _pickedFile == null ? Icons.cloud_upload : Icons.check_circle,
                  size: 60,
                  color: _pickedFile == null ? color : Colors.green,
                ),
                const SizedBox(height: 15),
                Text(
                  _pickedFile == null
                      ? (isAr ? 'اضغط لاختيار ملف' : 'Tap to select file')
                      : _selectedFileName ?? '',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _pickedFile == null ? color : Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'PDF, DOCX, DOC',
                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _pickedFile == null ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              disabledBackgroundColor: Colors.grey,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 3,
            ),
            child: Text(
              isAr ? 'إرسال البحث' : 'Submit Research',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(IconData icon, String label, String value, bool isAr) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
