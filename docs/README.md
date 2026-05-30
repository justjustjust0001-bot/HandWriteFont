# FontMaker 公式サイト（GitHub Pages）

事業用ホームページと特商法ページです。App Store Connect の **サポート URL** および **プライバシーポリシー URL** にも使えます。

## 公開手順

1. GitHub に `HandWriteFont` リポジトリを push する
2. GitHub → **Settings** → **Pages**
3. **Source** を `Deploy from a branch` に設定
4. **Branch** を `main`、**Folder** を `/docs` に設定（GitHub Pages は `/` か `/docs` のみ選択可能）
5. 数分後、次の URL で公開されます:

   **https://justjustjust0001-bot.github.io/HandWriteFont/**

## 各ページ

| ページ | URL |
|---|---|
| ホーム | `/index.html` |
| 特定商取引法に基づく表記 | `/legal/tokushoho.html` |
| 利用規約 | `/legal/terms.html` |
| プライバシーポリシー | `/legal/privacy.html` |

## App Store Connect での設定例

| 項目 | URL |
|---|---|
| サポート URL | `https://justjustjust0001-bot.github.io/HandWriteFont/` |
| プライバシーポリシー URL | `https://justjustjust0001-bot.github.io/HandWriteFont/legal/privacy.html` |
| マーケティング URL（任意） | `https://justjustjust0001-bot.github.io/HandWriteFont/` |

## ローカル確認

```bash
cd docs
python3 -m http.server 8080
```

ブラウザで http://localhost:8080 を開いてください。

## 注意

- GitHub ユーザー名やリポジトリ名を変えた場合は、`LegalDocuments.swift` の `websiteBaseURL` も更新してください。
- 特商法表記の「所在地」「電話番号」は現在「請求により開示」形式です。必要に応じて `legal/tokushoho.html` を編集してください。
