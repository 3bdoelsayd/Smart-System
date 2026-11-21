/// Research Topic Model with Deadline Support
/// الدكتور يحدد العناوين والطلاب يشوفوها عند الإرسال
class ResearchTopic {
  String id;
  String title; // العنوان
  String subject; // المادة
  String doctorId; // معرف الدكتور
  String collegeId; // معرف الكلية
  DateTime? deadline; // آخر موعد للإرسال
  int? maxDays; // عدد الأيام (بديل للـ deadline)
  bool isActive; // فعال/غير فعال
  DateTime createdAt;

  ResearchTopic({
    required this.id,
    required this.title,
    required this.subject,
    required this.doctorId,
    required this.collegeId,
    this.deadline,
    this.maxDays,
    this.isActive = true,
    required this.createdAt,
  });

  /// Check if topic is still accepting submissions
  bool get isAcceptingSubmissions {
    if (!isActive) return false;
    if (deadline == null) return true;
    return DateTime.now().isBefore(deadline!);
  }

  /// Get remaining days until deadline
  int? get remainingDays {
    if (deadline == null) return null;
    final diff = deadline!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subject': subject,
      'doctorId': doctorId,
      'collegeId': collegeId,
      'deadline': deadline?.millisecondsSinceEpoch,
      'maxDays': maxDays,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Create from Firestore document
  factory ResearchTopic.fromFirestore(String docId, Map<String, dynamic> data) {
    return ResearchTopic(
      id: docId,
      title: data['title'] ?? '',
      subject: data['subject'] ?? '',
      doctorId: data['doctorId'] ?? '',
      collegeId: data['collegeId'] ?? '',
      deadline: data['deadline'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['deadline'])
          : null,
      maxDays: data['maxDays'],
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
          : DateTime.now(),
    );
  }
}
