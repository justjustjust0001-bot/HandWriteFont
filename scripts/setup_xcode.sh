#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS="$ROOT/.tools"
XCODEGEN="$TOOLS/xcodegen/bin/xcodegen"
XCODEGEN_VERSION="2.45.4"
XCODEGEN_URL="https://github.com/yonaskolb/XcodeGen/releases/download/${XCODEGEN_VERSION}/xcodegen.zip"

cd "$ROOT"

if [ ! -x "$XCODEGEN" ]; then
  echo "→ XcodeGen をダウンロードしています..."
  mkdir -p "$TOOLS"
  curl -sL "$XCODEGEN_URL" -o "$TOOLS/xcodegen.zip"
  unzip -qo "$TOOLS/xcodegen.zip" -d "$TOOLS"
  rm "$TOOLS/xcodegen.zip"
fi

echo "→ Xcode プロジェクトを生成しています..."
"$XCODEGEN" generate --spec project.yml

echo ""
echo "✅ 完了: $ROOT/FontMaker.xcodeproj"
echo ""
echo "次のステップ:"
echo "  1. open FontMaker.xcodeproj"
echo "  2. Signing & Capabilities で Team を選択"
echo "  3. ⌘R でビルド・実行"
echo ""
echo "kanji_packs.json / kanji_readings.json は Copy Bundle Resources に自動登録済みです。"
