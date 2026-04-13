# Qne

一個基於 Flutter 開發的高效率行動應用程式，專注於 QR Code 整合與現代化使用者體驗。

## 🚀 核心功能

- **QR Code 掃描與工具**：整合 `mobile_scanner` 與 `qr_code_tools`，提供流暢的二維碼解析與生成體驗。
- **網頁聯動**：支援透過 `url_launcher` 快速開啟外部連結。
- **本地儲存與效能**：優化的資料處理流程，確保流暢的操作感。

## 🛠 開發環境與技術棧

- **Framework**: [Flutter](https://flutter.dev/)
- **Version Management**: [FVM](https://fvm.app/) (建議使用 FVM 以確保 SDK 版本一致性)
- **State Management**: Provider / Bloc (根據專案架構調整)
- **Database**: Hive / Shared Preferences
- **Android Configuration**: Kotlin DSL (`build.gradle.kts`)

## 📦 安裝與執行步驟

### 前置作業
確保你的開發環境已安裝 Flutter 並配置好 FVM。

1. **複製專案**
   ```bash
   git clone [https://github.com/wamgbo/Qne.git](https://github.com/wamgbo/Qne.git)
   cd Qne

    安裝套件
    Bash

    fvm flutter pub get

    執行專案
    Bash

    fvm flutter run

🏗 編譯與打包 (Android)

專案已配置 ProGuard/R8 規則以解決 javax.imageio 相關的編譯衝突。
產生 Release APK
Bash

fvm flutter build apk --release

產生 App Bundle (Google Play 上架用)
Bash

fvm flutter build appbundle

⚠️ 開發常見問題 (Troubleshooting)
1. 跨磁碟編譯錯誤 (Different Roots)

若遇到 this and base files have different roots 錯誤，請確保 android/gradle.properties 中已關閉增量編譯：
Properties

kotlin.incremental=false

2. R8 缺失類別警告

若編譯時報錯 Missing class javax.imageio，請確認 android/app/proguard-rules.pro 包含以下規則：
程式碼片段

-dontwarn javax.imageio.**
-keep class javax.imageio.** { *; }

📄 授權條款

本專案採用 MIT 授權條款。

Developed by Wang Chuan-bo


---

### 💡 寫給資深工程師的建議：
1. **LICENSE 檔案**：如果你的 Repo 還沒有授權檔案，建議補上一個 `LICENSE` (例如 MIT)，這對開源專案來說是標準做法。
2. **Screenshots**：建議在 `README` 中加入 1-2 張 App 的截圖，這會讓專案看起來更專業。
3. **FVM 提醒**：因為你的團隊或個人環境習慣使用 `fvm`，在 `README` 中特別標註可以減少其他開發者協作時
