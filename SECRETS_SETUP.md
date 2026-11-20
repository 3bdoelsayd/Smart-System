# 🔐 Setup Instructions - Secrets Configuration

## ⚠️ IMPORTANT - Required Before Running

This project uses **environment-based secrets** to protect Firebase and Supabase API keys.

You **must** create `lib/config/secrets.dart` before running the app.

---

## 📋 Quick Setup (5 minutes)

### Step 1: Copy Template

```bash
# في مجلد المشروع:
cp lib/config/secrets_template.dart lib/config/secrets.dart
```

### Step 2: Get Your Firebase Keys

1. افتح [Firebase Console](https://console.firebase.google.com/project/university-smart-system/settings/general)
2. اختر "Project Settings"
3. انزل لـ "Your apps"
4. انسخ الـ API Keys لكل منصة:
   - **Web**: `webApiKey`
   - **Android**: `android > current_key`
   - **iOS**: `ios > GOOGLE_APP_ID` (أو من GoogleService-Info.plist)
   - **Windows**: عادة نفس الـ Web key

### Step 3: Get Your Supabase Keys

1. افتح [Supabase Dashboard](https://supabase.com/dashboard/project/YOUR_PROJECT/settings/api)
2. انسخ:
   - **URL**: `https://your-project.supabase.co`
   - **Anon Key**: (المفتاح الطويل تحت "Project API keys")

### Step 4: Fill `secrets.dart`

افتح `lib/config/secrets.dart` وحط القيم الحقيقية:

```dart
class Secrets {
  static const String firebaseWebApiKey = 'AIzaSyCpQ...'; // ✅ حطيت المفتاح الحقيقي
  static const String supabaseUrl = 'https://abc123.supabase.co'; // ✅
  static const String supabaseAnonKey = 'eyJhbGciOiJIUz...'; // ✅
  // ... باقي الحقول
}
```

---

## 🚀 Run the App

بعد ما تخلص Setup:

```bash
flutter pub get
flutter run
```

---

## ❌ Troubleshooting

### ❌ Error: "Cannot find secrets.dart"

**الحل:**
```bash
# تأكد أن الملف موجود:
ls lib/config/secrets.dart

# لو مش موجود، ارجع لـ Step 1
```

### ❌ Error: "Invalid API Key"

**الحل:** تأكد أنك نسخت المفاتيح الصحيحة من Firebase Console

### ❌ Error: "Supabase initialization failed"

**الحل:** تأكد من الـ Supabase URL والـ Anon Key

---

## 🔒 Security Notes

✅ **DO:**
- Keep `secrets.dart` local only (already in `.gitignore`)
- Use different keys for dev/staging/production
- Rotate keys if accidentally committed

❌ **DON'T:**
- Never commit `secrets.dart` to Git
- Never share your keys publicly
- Never hardcode keys in code

---

## 📱 Alternative: Environment Variables (Advanced)

للـ CI/CD، يمكنك استخدام `--dart-define`:

```bash
flutter run --dart-define=FIREBASE_WEB_API_KEY=your_key
flutter build apk --dart-define=SUPABASE_URL=your_url
```

---

**Questions?** Check the [Security Fix PR](link) or ask the team.
