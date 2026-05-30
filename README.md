# FontMaker

手書きで文字を描き、フォント用グリフとして保存・エクスポートする iOS アプリ（SwiftUI）です。

## 機能

- **全文字一覧 UI** — A–Z / a–z / 数字 / ひらがな / カタカナ / 記号 / 漢字（7セクション）をグリッド表示、進捗バッジ付き
- **漢字検索** — 文字の直接入力、または読み（ひらがな・カタカナ）で候補表示。該当なしの場合はメッセージ表示
- **キャンバス描画** — 指・Apple Pencil で滑らかに描画、**線の太さ調節**（1–20pt）、**全文字種に補助線**（英字・かな・漢字・数字・記号）
- **再編集** — 保存済みストロークを JSON から復元して編集・再保存
- **プロジェクト管理** — 複数フォントを同時進行、名前付きで切り替え
- **試し打ち** — 保存済み文字でプレビュー入力
- **漢字パック（サブスク）** — StoreKit 2 で常用漢字 2,136 字を解放（月額 ¥550 / 年額 ¥5,000）
- **フォント出力** — ビットマップ（sbix）または **ベクター（TrueType 輪郭）** の `.ttf` を生成

## セットアップ（Mac + Xcode）

### 自動（推奨）

ターミナルで次を実行するだけです。**JSON の Copy Bundle Resources 登録も自動**です。

```bash
cd ~/Projects/HandWriteFont
./scripts/setup_xcode.sh
open FontMaker.xcodeproj
```

あとは Xcode で **Signing → Team** を選んで ⌘R で実行。

ソースを追加したあとも、同じスクリプトを再実行すれば Xcode プロジェクトが更新されます。

### App Store Connect（漢字パック）

Product ID を登録:

- `com.fontmaker.kanji.monthly`（¥550/月）
- `com.fontmaker.kanji.yearly`（¥5,000/年）

## 開発時の漢字解放

StoreKit 未設定の DEBUG ビルドでは、メニュー → **漢字パックを購入** → **開発用：漢字を解放** トグルでテストできます。

## プロジェクト構成

```
HandWriteFont/
├── Models/
│   ├── CharacterCatalog.swift    # 全文字定義
│   ├── CharacterSection.swift
│   ├── KanjiPack.swift
│   └── ...
├── Services/
│   ├── GlyphStorageService.swift # PNG + ストローク永続化
│   ├── SubscriptionService.swift # StoreKit 2
│   └── FontExportService.swift
├── Utilities/
│   ├── SbixFontBuilder.swift     # ビットマップ TTF 生成
│   └── VectorFontBuilder.swift   # ベクター TTF 生成
├── Views/
│   ├── CharacterListView.swift   # 文字一覧
│   ├── CharacterSearchView.swift # 漢字検索
│   ├── CharacterCanvasView.swift # 描画画面
│   ├── KanjiPackStoreView.swift  # 課金画面
│   └── FontExportView.swift      # フォント出力
└── Resources/
    ├── kanji_packs.json          # 常用漢字（学年別）
    └── kanji_readings.json       # 常用漢字の読みデータ
```

## 文字セット

| セクション | 文字数 | 要サブスク |
|---|---:|---|
| 大文字 A–Z | 26 | いいえ |
| 小文字 a–z | 26 | いいえ |
| 数字 0–9 | 10 | いいえ |
| ひらがな | 83 | いいえ |
| カタカナ | 83 | いいえ |
| 記号 | 約50 | いいえ |
| 漢字（小学1年〜中学以降） | 2,136 | **はい** |

## データ保存場所

`Application Support/FontMaker/{プロジェクトID}/` に PNG + JSON（ストローク）+ index.json を保存します。プロジェクト一覧は `projects.json` で管理します。

## フォント出力について

| 方式 | 説明 |
|---|---|
| **ベクター（輪郭）** | 保存ストロークを TrueType 輪郭（glyf）に変換。拡大しても劣化しにくい |
| **ビットマップ（sbix）** | PNG を sbix に埋め込み。iOS/macOS 向け |

ベクター出力には保存済みの **ストローク JSON** が必要です（PNG のみの古いデータはベクター出力できません）。
