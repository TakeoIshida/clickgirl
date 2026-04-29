# GitHub Actions デプロイ手順

## 概要

Intel Mac（macOS Sequoia 15.x）では Xcode 26 が動かないため、GitHub Actions のクラウド Mac でビルド・アップロードを行う。

---

## デプロイコマンド

```bash
deploy-clickgirl
# または
gh workflow run deploy.yml --repo TakeoIshida/clickgirl
```

エイリアス登録:
```bash
echo 'alias deploy-clickgirl="gh workflow run deploy.yml --repo TakeoIshida/clickgirl"' >> ~/.zshrc && source ~/.zshrc
```

---

## ファイル構成

| ファイル | 役割 |
|--------|------|
| `.github/workflows/deploy.yml` | GitHub Actions ワークフロー |
| `ClickGirl/ExportOptions.plist` | アーカイブエクスポート設定 |

---

## GitHub Secrets 一覧

| Secret名 | 内容 | 更新頻度 |
|---------|------|--------|
| `BUILD_CERTIFICATE_BASE64` | Apple Distribution 証明書（P12）をbase64化 | 証明書更新時（約1年） |
| `P12_PASSWORD` | P12のパスワード | 証明書更新時 |
| `KEYCHAIN_PASSWORD` | 任意の文字列（例: `github-actions`） | 変更不要 |
| `BUILD_PROVISION_PROFILE_BASE64` | App Store用プロビジョニングプロファイルをbase64化 | アプリごと / 期限切れ時 |
| `PROVISIONING_PROFILE_NAME` | プロファイルの名前（例: `ClickGirl AppStore`） | アプリごと |
| `ASC_KEY_ID` | App Store Connect API Key ID | 変更不要 |
| `ASC_ISSUER_ID` | App Store Connect Issuer ID | 変更不要 |
| `ASC_API_KEY_BASE64` | .p8ファイルをbase64化 | 変更不要 |

### base64変換コマンド

```bash
# 証明書
base64 -i ~/Desktop/証明書.p12 | pbcopy

# プロビジョニングプロファイル
base64 -i ~/Downloads/ClickGirl_AppStore.mobileprovision | pbcopy

# API Key
base64 -i ~/Downloads/AuthKey_XXXXXXXX.p8 | pbcopy
```

---

## ワークフローの仕組み

1. **Xcode 26 を選択** — runner に Xcode 26 があれば自動選択
2. **証明書インポート** — P12をキーチェーンに追加
3. **プロビジョニングプロファイル設置** — `~/Library/MobileDevice/Provisioning Profiles/` にコピー
4. **CocoaPods インストール** — `pod install`
5. **ビルド** — 自動署名 + ASC API Key で `-allowProvisioningUpdates`
6. **エクスポート** — ExportOptions.plist で手動署名に切り替え
7. **アップロード** — `xcrun altool` で App Store Connect に送信

### ポイント
- ビルド時は**自動署名**（Pods ターゲットにプロファイルが適用されるエラーを回避）
- エクスポート時は**手動署名**（ExportOptions.plist で Bundle ID とプロファイルを明示指定）

---

## 新規アプリへの流用

1. `.github/workflows/deploy.yml` をコピーしてそのまま使える
2. `ExportOptions.plist` の以下を変更:
   - `teamID`: チームID
   - `provisioningProfiles` の Bundle ID とプロファイル名
3. GitHub Secrets で以下だけ新規登録:
   - `BUILD_PROVISION_PROFILE_BASE64`（新アプリ用プロファイル）
   - `PROVISIONING_PROFILE_NAME`（新アプリ用プロファイル名）
4. 残りの Secret（証明書・API Key）は使い回しOK

---

## ビルド番号の更新

アップロード済みより大きい番号が必要。`project.pbxproj` の `CURRENT_PROJECT_VERSION` を変更してから push する。

```bash
# 確認
grep "CURRENT_PROJECT_VERSION" ClickGirl/ClickGirl.xcodeproj/project.pbxproj

# git push後にデプロイ
deploy-clickgirl
```

---

## トラブルシューティング

| エラー | 原因 | 対処 |
|------|------|------|
| Pods does not support provisioning profiles | 手動署名がPodsに適用された | ビルド時は自動署名を使う（現状の設定でOK） |
| The bundle version must be higher | ビルド番号重複 | `CURRENT_PROJECT_VERSION` を増やして push |
| No profiles for '...' were found | プロファイル未設定 | ExportOptions.plist のBundle IDとプロファイル名を確認 |
| Cloud signing permission error | API Keyの権限不足 | App Store Connect でキーのロールを確認 |
