// کاریا دسک — ارتباط برنامه با سرور خودمان (ورود، بنر تبلیغ).
//
// همه‌ی چیزهایی که به سرور کاریا مربوط است اینجا جمع شده تا با هر نسخه‌ی تازه‌ی
// RustDesk، فقط همین پوشه دوباره کپی شود. هیچ‌جای دیگر کد بالادست، شبکه نمی‌زند.
//
// سرور: https://desk.kariyahesab.com  (همان پنل پایش، مسیرهای /api/app/*)

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class KariyaApi {
  static const String base = 'https://desk.kariyahesab.com';
  static const Duration _timeout = Duration(seconds: 12);

  /// توکن ورود؛ در فایل کنار تنظیمات برنامه نگه داشته می‌شود.
  static String? token;
  static String userName = '';
  static String userPhone = '';

  /// وضعیت ورود — رابط کاربری با گوش‌دادن به این، خودش را تازه می‌کند.
  static final ValueNotifier<bool> loggedIn = ValueNotifier<bool>(false);

  static Future<File> _tokenFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}${Platform.pathSeparator}kariya_session.json');
  }

  static Future<void> load() async {
    try {
      final f = await _tokenFile();
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        token = data['token'] as String?;
        userName = (data['name'] ?? '') as String;
        userPhone = (data['phone'] ?? '') as String;
      }
    } catch (_) {}
    if (token != null && token!.isNotEmpty) {
      loggedIn.value = true;
      // اعتبار توکن را در پس‌زمینه بررسی می‌کنیم؛ اگر باطل بود، کاربر دوباره وارد شود.
      ping().then((ok) {
        if (!ok) logout();
      });
    }
  }

  static Future<void> _save() async {
    try {
      final f = await _tokenFile();
      await f.writeAsString(jsonEncode({
        'token': token,
        'name': userName,
        'phone': userPhone,
      }));
    } catch (_) {}
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=utf-8',
        if (token != null) 'X-KD-Token': token!,
      };

  /// ورود با شماره موبایل و رمز. پیام خطا برمی‌گرداند، یا null یعنی موفق.
  static Future<String?> login(String phone, String password, String device) async {
    try {
      final res = await http
          .post(Uri.parse('$base/api/app/login'),
              headers: {'Content-Type': 'application/json; charset=utf-8'},
              body: jsonEncode({
                'phone': phone,
                'password': password,
                'device': device,
              }))
          .timeout(_timeout);
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['token'] != null) {
        token = body['token'] as String;
        userName = (body['name'] ?? '') as String;
        userPhone = (body['phone'] ?? '') as String;
        await _save();
        loggedIn.value = true;
        return null;
      }
      return (body['error'] ?? 'ورود ناموفق بود') as String;
    } on SocketException {
      return 'اتصال به سرور کاریا برقرار نشد. اینترنت را بررسی کنید.';
    } catch (_) {
      return 'خطای غیرمنتظره در ورود';
    }
  }

  static Future<bool> ping() async {
    if (token == null) return false;
    try {
      final res = await http
          .post(Uri.parse('$base/api/app/ping'),
              headers: _headers, body: jsonEncode({'token': token}))
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {
      // قطعی شبکه نباید کاربر را بیرون بیندازد.
      return true;
    }
  }

  static Future<void> logout() async {
    token = null;
    userName = '';
    userPhone = '';
    loggedIn.value = false;
    try {
      final f = await _tokenFile();
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// بنر فعال: {id, title, image, link} یا null اگر تبلیغی تعریف نشده باشد.
  /// بنر بدون ورود هم می‌آید — مشتریِ بی‌حساب هم باید تبلیغ را ببیند.
  static Future<Map<String, dynamic>?> fetchAd() async {
    try {
      final res = await http
          .get(Uri.parse('$base/api/app/ad'), headers: _headers)
          .timeout(_timeout);
      if (res.statusCode != 200) return null;
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final ad = body['ad'];
      if (ad == null) return null;
      final map = Map<String, dynamic>.from(ad as Map);
      final image = (map['image'] ?? '') as String;
      if (image.startsWith('/')) map['image'] = '$base$image';
      return map;
    } catch (_) {
      return null;
    }
  }

  // ---- ورود با حساب کاریا (جریان کد دستگاه) ----
  //
  // برنامه‌ی دسکتاپ ورود با بله و تلگرام و گوگل را خودش ندارد؛ همه‌ی این‌ها
  // روی سایت کاریا هست. پس کد کوتاهی می‌گیریم، کاربر در مرورگر تأیید می‌کند،
  // و ما با نظرسنجی متوجه می‌شویم.

  /// شروع: {user_code, verify_url_full, device_code, interval}
  static Future<Map<String, dynamic>?> deviceStart(String device) async {
    try {
      final res = await http
          .post(Uri.parse('$base/api/app/device/start'),
              headers: {'Content-Type': 'application/json; charset=utf-8'},
              body: jsonEncode({'device': device}))
          .timeout(_timeout);
      if (res.statusCode != 200) return null;
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// وضعیت: pending | authorized | expired | unknown
  static Future<String> devicePoll(String deviceCode) async {
    try {
      final res = await http
          .post(Uri.parse('$base/api/app/device/poll'),
              headers: {'Content-Type': 'application/json; charset=utf-8'},
              body: jsonEncode({'device_code': deviceCode}))
          .timeout(_timeout);
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final status = (body['status'] ?? 'pending') as String;
      if (status == 'authorized') {
        token = body['token'] as String?;
        userName = (body['name'] ?? '') as String;
        userPhone = (body['phone'] ?? '') as String;
        await _save();
        loggedIn.value = true;
      }
      return status;
    } catch (_) {
      return 'pending';
    }
  }

  /// ثبت‌نام سریع برای کسی که حساب کاریا ندارد. null یعنی موفق.
  ///
  /// ⚠️ عمداً بدون تأیید پیامکی: ورود در این برنامه اختیاری است و این حساب
  /// فقط می‌گوید کدام کسب‌وکار دارد استفاده می‌کند، نه اینکه به چیزی دسترسی
  /// بدهد. اگر روزی دسترسی‌ای به آن وصل شد، همان روز تأیید شماره لازم می‌شود.
  static Future<String?> register(
      String name, String business, String phone, String device) async {
    try {
      final res = await http
          .post(Uri.parse('$base/api/app/register'),
              headers: {'Content-Type': 'application/json; charset=utf-8'},
              body: jsonEncode({
                'name': name,
                'business': business,
                'phone': phone,
                'device': device,
              }))
          .timeout(_timeout);
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['token'] != null) {
        token = body['token'] as String;
        userName = (body['name'] ?? '') as String;
        userPhone = (body['phone'] ?? '') as String;
        await _save();
        loggedIn.value = true;
        return null;
      }
      return (body['error'] ?? 'ثبت‌نام انجام نشد') as String;
    } on SocketException {
      return 'اتصال به سرور کاریا برقرار نشد.';
    } catch (_) {
      return 'خطای غیرمنتظره';
    }
  }

  /// فهرست «دیگر محصولات کاریا» — از سرور، تا افزودن محصول بیلد نخواهد.
  static Future<List<Map<String, dynamic>>> fetchProducts() async {
    try {
      final res = await http
          .get(Uri.parse('$base/api/app/products'))
          .timeout(_timeout);
      if (res.statusCode != 200) return [];
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return ((body['products'] ?? []) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> productClick(int id) async {
    try {
      await http
          .post(Uri.parse('$base/api/app/product/click'),
              headers: {'Content-Type': 'application/json; charset=utf-8'},
              body: jsonEncode({'id': id}))
          .timeout(_timeout);
    } catch (_) {}
  }

  static Future<void> clickAd(int id) async {
    try {
      await http
          .post(Uri.parse('$base/api/app/click'),
              headers: _headers, body: jsonEncode({'token': token, 'ad_id': id}))
          .timeout(_timeout);
    } catch (_) {}
  }
}
