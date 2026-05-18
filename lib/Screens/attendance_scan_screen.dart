import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/data_service.dart';

class AttendanceScanScreen extends StatefulWidget {
  const AttendanceScanScreen({super.key});

  @override
  State<AttendanceScanScreen> createState() => _AttendanceScanScreenState();
}

class _AttendanceScanScreenState extends State<AttendanceScanScreen> {
  final DataService _ds = DataService();
  late MobileScannerController _scannerController;
  bool _isProcessing = false;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
    _initLocationTracking();
  }

  Future<void> _initLocationTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_ds.isArabic ? "يرجى تفعيل الـ GPS (الموقع) في هاتفك" : "Please enable GPS"),
            backgroundColor: Colors.orange,
          ),
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        _positionStream = Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: kIsWeb ? LocationAccuracy.low : LocationAccuracy.medium,
            distanceFilter: 5,
          ),
        ).listen((Position position) {
          if (mounted) setState(() => _currentPosition = position);
        });
      }
    } catch (e) {
      debugPrint("Location tracking error: $e");
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? qrData = barcodes.first.rawValue;
      
      if (qrData != null && qrData.contains('|')) {
        setState(() => _isProcessing = true);
        _scannerController.stop(); 

        try {
          List<String> parts = qrData.split('|');
          
          if (parts.length >= 7) {
            String subject = parts[0];
            String level = parts[1];
            String division = parts[2];
            int lecture = int.tryParse(parts[3]) ?? 1;
            String hallLocStr = parts[4];
            int qrTimestamp = int.tryParse(parts[5]) ?? 0;
            int validityMins = int.tryParse(parts[6]) ?? 2; 

            // 1. فحص الوقت
            int now = DateTime.now().millisecondsSinceEpoch;
            if (now - qrTimestamp > (validityMins * 60000)) {
              throw _ds.isArabic ? "انتهت صلاحية الرمز. اطلب من الدكتور رمزاً جديداً." : "QR expired.";
            }

            // 2. الحصول على الموقع
            Position? pos;
            try {
              pos = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high,
                timeLimit: const Duration(seconds: 10),
              );
            } catch (e) {
              pos = _currentPosition;
            }

            if (pos == null) {
              throw _ds.isArabic ? "فشل تحديد موقعك الحالي. تأكد من تشغيل الـ GPS." : "Could not determine location.";
            }

            // 3. حماية Fake GPS (مهمة جداً للتحقق من الغش)
            if (!kIsWeb) {
              if (pos.isMocked) {
                throw _ds.isArabic 
                  ? "لا يمكن تسجيل الحضور: مصدر الموقع غير موثوق (Fake GPS detected)." 
                  : "Attendance cannot be recorded because the location source is not trusted.";
              }
            }
            
            // 4. فحص المسافة (30 متر لضمان التواجد داخل القاعة)
            if (hallLocStr != "0,0") {
              List<String> latLng = hallLocStr.split(',');
              if (latLng.length == 2) {
                double hallLat = double.tryParse(latLng[0]) ?? 0.0;
                double hallLng = double.tryParse(latLng[1]) ?? 0.0;
                double distance = Geolocator.distanceBetween(pos.latitude, pos.longitude, hallLat, hallLng);

                if (distance > 30) {
                  throw _ds.isArabic 
                    ? "أنت خارج نطاق القاعة. المسافة المحسوبة: ${distance.toInt()} متر." 
                    : "Too far from hall (${distance.toInt()}m).";
                }
              }
            }

            // 5. تسجيل الحضور
            await _ds.recordAttendanceCloud(
              subject: subject,
              level: level,
              lectureNumber: lecture,
              division: division,
              studentLocation: "${pos.latitude},${pos.longitude}",
            );

            if (mounted) {
              setState(() => _isProcessing = false); 
              _showSuccess(subject, lecture);
            }
          } else {
            throw _ds.isArabic ? "رمز QR غير صالح." : "Invalid QR.";
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 7),
            ));
          }
          setState(() => _isProcessing = false); 
          _scannerController.start(); 
        }
      }
    }
  }

  void _showSuccess(String subject, int lecture) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _ds.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Text(
          _ds.isArabic
            ? "تم تسجيل حضورك بنجاح\nالمادة: $subject\nالمحاضرة: $lecture"
            : "Attendance Recorded\nSubject: $subject\nLecture: $lecture",
          textAlign: TextAlign.center,
          style: TextStyle(color: _ds.isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _ds.isDarkMode ? const Color(0xFF03DAC6) : const Color(0xFF673AB7),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text(_ds.translate('ok')),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = _ds.isDarkMode;
    Color primaryColor = isDark ? const Color(0xFF03DAC6) : const Color(0xFF673AB7);
    return Scaffold(
      appBar: AppBar(
        title: Text(_ds.translate('attendance')),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _scannerController, onDetect: _onDetect),
          Center(
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: primaryColor, width: 2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: _isProcessing ? const Center(child: CircularProgressIndicator(color: Colors.white)) : null,
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 15),
                    Text("جاري التحقق من الموقع...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
