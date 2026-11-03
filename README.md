<div align="center">

  <img src="assets/logo.png" alt="MX Prep Logo" width="120" style="border-radius: 24px; box-shadow: 0 8px 24px rgba(37, 99, 235, 0.2);" />

  # MX Prep (এমএক্স প্রেপ)
  ### Intelligent Offline-First Study Engine for HSC & SSC Candidates

  [![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
  [![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)](https://developer.android.com)
  [![Brand](https://img.shields.io/badge/Series-MX%20Series%20by%20MApp%20X-2563EB)](https://motionmindx.com)
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

  <p align="center">
    <b>A product of MApp X (MX Series) • Under the parent brand Motion Mind X</b><br>
    এইচএসসি এবং এসএসসি পরীক্ষার্থীদের সিলেবাস নিখুঁতভাবে শেষ করতে এবং পড়াশোনায় ডিসিপ্লিন ধরে রাখতে তৈরি একটি ওপেন সোর্স প্রজেক্ট।
  </p>

  <p align="center">
    <a href="https://github.com/MApp-X/MX-Prep/releases">Download Latest APK</a> •
    <a href="https://motionmindx.com">Brand Portfolio</a> •
    <a href="https://ceo.motionmindx.com">Founder Profile</a>
  </p>

</div>

---

## 📌 Overview (সংক্ষিপ্ত পরিচিতি)

**MX Prep** হলো বাংলাদেশি HSC ও SSC স্টুডেন্টদের জন্য তৈরি একটি ওপেন-সোর্স, ইন্টেলিজেন্ট এবং অফলাইন-ফার্স্ট স্টাডি ট্র্যাকার। এটি সাধারণ কোনো টু-ডু লিস্ট অ্যাপ নয়—প্রতিটি পাঠ্যবইয়ের অধ্যায়ভিত্তিক পৃষ্ঠা সংখ্যা, কমপ্লিশন পারসেন্টেজ, ডেইলি রিডিং স্পিড এবং ব্যাকলগ অ্যানালিটিক্স নিখুঁতভাবে ট্র্যাক করে রিয়েল-টাইম রুটিন মেনটেইন করার জন্য এটি ডিজাইন করা হয়েছে।

---

## ✨ Key Features (মূল বৈশিষ্ট্যসমূহ)

* 📖 **Textbook & Chapter Intelligence:** সম্পূর্ণ এইচএসসি ও এসএসসি সিলেবাস অনুযায়ী প্রতিটি বই ও চ্যাপ্টারের পেইজ-লেভেল প্রগ্রেস ট্র্যাকিং।
* 🔥 **Real-Time Streak & Activity Audit:** প্রতিদিনের পড়ার হিসাব রেখে লাইভ ডে-স্ট্রিক কাউন্ট এবং কনসিস্টেন্সি অডিট।
* ⚠️ **Smart Backlog (Danger Zone):** যেসব বইয়ের পড়াশোনা পিছিয়ে আছে (প্রগ্রেস ৩০% এর নিচে), সেগুলোকে আলাদা ওয়ার্নিং জোন হিসেবে ফোকাস করা যাতে কোনো সাবজেক্ট বাদ না পড়ে।
* ⏰ **Dynamic Study Routine Alerts:** সকালে পড়া শুরুর রিমাইন্ডার, দুপুরে ডেইলি টার্গেটের হাফ-টাইম চেক এবং রাতে ঘুমানোর আগে স্টাডি অডিট অ্যালার্ম।
* 🤖 **AI-Powered Assessment (Groq Engine):** চ্যাপ্টার সিলেক্ট করে স্বয়ংক্রিয়ভাবে প্র্যাকটিস এমসিকিউ (MCQ) জেনারেট করার জন্য ইন্টিগ্রেটেড এআই সুবিধা।
* ⚡ **Offline-First & Privacy First:** ইন্টারনেট ছাড়াও সম্পূর্ণ ডাটা ডিভাইস মেমোরিতে নিরাপদে সংরক্ষিত থাকে, নো ক্লাউড ডিপেন্ডেন্সি।

---

## 🛠 Tech Stack & Architecture

* **Core Framework:** [Flutter](https://flutter.dev) (Dart)
* **Local Persistence:** SharedPreferences (Fast, Lightweight Key-Value Storage)
* **Background Notification Engine:** `flutter_local_notifications` & Android Exact Alarm Manager
* **Timezone Sync:** `timezone` package (Synced to `Asia/Dhaka`)
* **Design System:** Clean Slate UI with Dynamic Visual Progress Bars & Minimalist Color Accents
* **AI Integration:** Groq API Client for instant automated exam quiz generation

---

## 📱 Getting Started & Building APK (প্রজেক্ট রান ও বিল্ড গাইড)

প্রজেক্টটি ক্লোন করে লোকাল কম্পিউটারে রান বা রিলিজ বিল্ড দেওয়ার নিয়ম:

### ১. Clone the Repository

```bash
git clone https://github.com/MApp-X/MX-Prep.git
cd MX-Prep
```

### ২. Install Dependencies

```bash
flutter pub get
```

### ৩. Generate App Icons

```bash
dart run flutter_launcher_icons
```

### ৪. Build Production Release APK

```bash
flutter build apk --release --split-per-abi
```

> বিল্ড সফল হলে `build/app/outputs/flutter-apk/` ডিরেক্টরিতে APK ফাইল পেয়ে যাবে। সরাসরি ফোনে ইনস্টল করতে `app-arm64-v8a-release.apk` ফাইলটি ব্যবহার করো।
---

## 🤝 Contributing (অবদান রাখুন)

যেহেতু এটি একটি ওপেন সোর্স প্রজেক্ট, তাই যেকোনো বাগ ফিক্স, নতুন ফিচারের আইডিয়া বা পিআর (Pull Request) স্বাগত:

1. রিপোজিটরিটি Fork করুন।
2. নতুন ফিচারের জন্য Branch তৈরি করুন (`git checkout -b feature/AmazingFeature`).
3. পরিবর্তন Commit করুন (`git commit -m 'Add some AmazingFeature'`).
4. ব্রাঞ্চে Push করুন (`git push origin feature/AmazingFeature`).
5. একটি Pull Request ওপেন করুন।

---

## 📄 License (লাইসেন্স)

এই প্রজেক্টটি **MIT License**-এর অধীনে ওপেন সোর্স করা হয়েছে। বিস্তারিত জানতে [LICENSE](https://www.google.com/search?q=LICENSE) ফাইলটি দেখুন।

---

## 👨‍💻 Founder & Creator (নির্মাতা পরিচিতি)

---

## 🏢 Brand Ecosystem (ব্র্যান্ড পরিচিতি)

**MX Prep** হলো **MApp X**-এর **MX Series**-এর একটি অফিশিয়াল ওপেন সোর্স প্রোডাক্ট, যা পরিচালিত হচ্ছে টেক-ব্র্যান্ড **Motion Mind X**-এর তত্ত্বাবধানে।

* 🌐 **Brand Website:** [motionmindx.com](https://motionmindx.com)
* 💼 **Sub-Brand:** MApp X (MX Series Applications)
* 📦 **GitHub Repository:** [github.com/MApp-X/MX-Prep](https://github.com/MApp-X/MX-Prep)

---