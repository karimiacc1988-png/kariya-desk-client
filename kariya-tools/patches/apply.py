#!/usr/bin/env python3
"""
اعمال تغییرات «کاریا دسک» روی سورس اصلی RustDesk.

فلسفه: فورک دستی نگه نمی‌داریم. سورس بالادست را روی یک تگ مشخص می‌گیریم و این
اسکریپت تغییرات ما را رویش می‌زند. با هر نسخه‌ی تازه‌ی RustDesk فقط همین اسکریپت
به‌روز می‌شود.

    python3 patches/apply.py <مسیر-سورس-rustdesk>

همه‌ی تغییرها ایدمپوتنت‌اند: اجرای دوباره چیزی را خراب نمی‌کند.
"""

import os
import shutil
import sys

try:  # کنسول ویندوز پیش‌فرض cp1252 است و متن فارسی را نمی‌پذیرد
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

# ---------------------------------------------------------------- تنظیمات برند
APP_NAME = "KariyaDesk"
ID_SERVER = "desk.kariyahesab.com"
PUB_KEY = "yQh7HGyWBw2sb6SvcKWdXDFgec+a+2oEDLg4QUWh9ic="

NL = chr(10)


def edit(path, replacements, required=True):
    """
    جایگزینی رشته‌ای. هر مورد سه‌تایی است: (رشته‌ی قدیم، رشته‌ی تازه، نشانه).
    «نشانه» رشته‌ای یکتا از تغییر ماست؛ اگر در فایل باشد یعنی قبلاً اعمال شده.
    بدون این نشانه، تشخیصِ «قبلاً اعمال شده» اشتباه می‌شود و تغییر بی‌صدا رد می‌شود.
    """
    if not os.path.isfile(path):
        if required:
            raise SystemExit("فایل پیدا نشد: %s" % path)
        print("  - رد شد (نبود): %s" % path)
        return
    with open(path, encoding="utf-8") as fh:
        src = fh.read()
    original = src
    for old, new, marker in replacements:
        if marker and marker in src:
            continue  # از قبل اعمال شده
        if old not in src:
            if required:
                raise SystemExit("رشته پیدا نشد در %s:%s%s" % (path, NL, old[:160]))
            print("  - رشته نبود، رد شد: %s" % path)
            continue
        src = src.replace(old, new, 1)
    if src != original:
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(src)
        print("  ✓ %s" % os.path.relpath(path))
    else:
        print("  = از قبل اعمال شده: %s" % os.path.relpath(path))


def add_imports(path, imports):
    """ایمپورت‌های دارت باید بالای فایل و قبل از هر تعریفی باشند."""
    with open(path, encoding="utf-8") as fh:
        src = fh.read()
    needed = [i for i in imports if i not in src]
    if not needed:
        print("  = ایمپورت‌ها از قبل هست: %s" % os.path.relpath(path))
        return
    lines = src.split(NL)
    # ⚠️ ایمپورت شرطیِ دارت دو خطی است:
    #     import 'a.dart'
    #         if (dart.library.html) 'b.dart';
    # پس باید بعد از خطی درج کنیم که دستور ایمپورت را با ';' تمام کرده،
    # نه صرفاً بعد از آخرین خطی که با import شروع می‌شود.
    in_import = False
    last = -1
    for i, ln in enumerate(lines):
        if ln.startswith("import ") or ln.startswith("export "):
            in_import = True
        if in_import and ln.rstrip().endswith(";"):
            last = i
            in_import = False
    if last < 0:
        raise SystemExit("هیچ ایمپورتی در %s پیدا نشد" % path)
    lines[last + 1:last + 1] = ["// --- کاریا دسک ---"] + needed
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(NL.join(lines))
    print("  ✓ ایمپورت اضافه شد: %s" % os.path.relpath(path))


def main(target):
    if not os.path.isdir(os.path.join(target, "flutter")):
        raise SystemExit("این مسیر سورس RustDesk نیست: %s" % target)

    # ۱) فایل‌های خودمان
    dst = os.path.join(target, "flutter", "lib", "kariya")
    os.makedirs(dst, exist_ok=True)
    for name in sorted(os.listdir(os.path.join(ROOT, "kariya"))):
        if name.endswith(".dart"):
            shutil.copy2(os.path.join(ROOT, "kariya", name), os.path.join(dst, name))
    print("  ✓ فایل‌های کاریا در flutter/lib/kariya کپی شد")

    # ۲) سرور و کلید پیش‌فرض — کاربر هیچ تنظیمی نباید بکند
    edit(os.path.join(target, "libs", "hbb_common", "src", "config.rs"), [
        ('pub const RENDEZVOUS_SERVERS: &[&str] = &["rs-ny.rustdesk.com"];',
         'pub const RENDEZVOUS_SERVERS: &[&str] = &["%s"];' % ID_SERVER,
         ID_SERVER),
        ('pub const RS_PUB_KEY: &str = "OeVuKk5nlHiXp+APNn0Y3pC1Iwpwn44JGqrQCsWqmBw=";',
         'pub const RS_PUB_KEY: &str = "%s";' % PUB_KEY, PUB_KEY),
    ])

    # ۳) نام پنجره‌ی ویندوز
    edit(os.path.join(target, "flutter", "windows", "runner", "main.cpp"), [
        ('std::wstring app_name = L"RustDesk";',
         'std::wstring app_name = L"%s";' % APP_NAME, 'L"%s"' % APP_NAME),
    ])

    # ۴) صفحه‌ی اصلی: گیت ورود + بنر تبلیغ
    home = os.path.join(target, "flutter", "lib", "desktop", "pages",
                        "desktop_home_page.dart")
    add_imports(home, [
        "import 'package:flutter_hbb/kariya/kariya_api.dart';",
        "import 'package:flutter_hbb/kariya/login_gate.dart';",
        "import 'package:flutter_hbb/kariya/ad_banner.dart';",
    ])
    gate_old = (
        "  Widget build(BuildContext context) {" + NL +
        "    super.build(context);" + NL +
        "    final isIncomingOnly = bind.isIncomingOnly();" + NL)
    gate_new = (
        "  Widget build(BuildContext context) {" + NL +
        "    super.build(context);" + NL +
        "    // --- کاریا: تا وارد نشده، شناسه و رمز اتصال نشان داده نمی‌شود ---" + NL +
        "    return ValueListenableBuilder<bool>(" + NL +
        "      valueListenable: KariyaApi.loggedIn," + NL +
        "      builder: (context, isLoggedIn, _) => isLoggedIn" + NL +
        "          ? _kariyaHome(context)" + NL +
        "          : KariyaLoginGate(onSuccess: () => setState(() {}))," + NL +
        "    );" + NL +
        "  }" + NL + NL +
        "  Widget _kariyaHome(BuildContext context) {" + NL +
        "    final isIncomingOnly = bind.isIncomingOnly();" + NL)
    banner_old = "      if (!isOutgoingOnly) buildPasswordBoard(context),"
    banner_new = (banner_old + NL + "      const KariyaAdBanner(),")
    edit(home, [(gate_old, gate_new, "_kariyaHome"),
                (banner_old, banner_new, "KariyaAdBanner()")])

    # ۵) خواندن نشست ذخیره‌شده هنگام بالا آمدن برنامه
    main_dart = os.path.join(target, "flutter", "lib", "main.dart")
    add_imports(main_dart, ["import 'package:flutter_hbb/kariya/kariya_api.dart';"])
    edit(main_dart, [
        ("Future<void> main(List<String> args) async {",
         "Future<void> main(List<String> args) async {" + NL +
         "  // نشست ذخیره‌شده‌ی کاریا را می‌خوانیم تا هر بار لاگین لازم نباشد." + NL +
         "  KariyaApi.load();", "KariyaApi.load();"),
    ])

    print(NL + "تمام شد؛ سورس آماده‌ی ساخت است.")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    main(os.path.abspath(sys.argv[1]))
