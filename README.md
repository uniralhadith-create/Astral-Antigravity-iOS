# Astral — Free iOS Mobile IDE for Google Antigravity

تطبيق **Astral** هو بيئة تطوير محمولة مجانية 100% ومخصّصة حصرياً لـ **Google Antigravity** على iPhone، بتصميم **Liquid Glass (iOS 26/27+)**، ودعم **Dynamic Island (Live Activities)**، والعمل في الخلفية، وجسر ربط محلي مفتوح المصدر (`astral-connector`).

## 1. تحويل المشروع إلى ملف IPA جاهز للتوقيع والتثبيت

### الطريقة الأسرع (تلقائياً عبر GitHub Actions بدون Mac)
1. ارفع محتويات مجلد `Astral` إلى مستودع GitHub خاص أو عام.
2. افتح تبويب **Actions** ثم شغّل Workflow باسم **Build Astral Unsigned IPA**.
3. بعد اكتمال البناء، حمّل ملف `Astral-Unsigned.ipa` من قسم **Artifacts**.
4. وقّع الملف وثبّته على جهازك عبر **ESign / Feather / AltStore / SideStore / TrollStore**.

### الطريقة المحلية (عبر Mac وXcode)
```bash
brew install xcodegen
xcodegen generate
open Astral.xcodeproj
```
اختر فريق التوقيع الخاص بك (Signing & Capabilities) لكل من `Astral` و`AstralWidgetExtension` ثم اضغط **Run** أو **Product → Archive**.

## 2. تشغيل جسر الربط المحلي (`astral-connector`) مجاناً 100%
على جهازك (Mac / Windows / Linux) داخل مجلد مشروعك:
```bash
cd astral-connector
npm install
npm start
```
سيظهر رمز **QR** ورابط **Magic Link** (`astral://pair?...`) في الطرفية. افتح تطبيق **Astral** على الآيفون واضغط على أيقونة **QR** في الأعلى للاقتران الفوري.

> **ملاحظة للعمل خارج الشبكة المحلية:** يمكنك استخدام **Tailscale** أو **Cloudflare Tunnel** المجاني واستبدال عنوان `ws://` بعنوان النفق للتحكم بجهازك من أي مكان في العالم.
