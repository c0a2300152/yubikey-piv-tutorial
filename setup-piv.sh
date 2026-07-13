#!/bin/bash
# YubiKey PIV チュートリアル: スロット 9d に RSA-2048 鍵を生成
# ※ YubiKey を USB に差し込んでから実行してください
# ※ デフォルト管理者キー・PIN を使用します（変更しません）

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PUBKEY_PATH="$SCRIPT_DIR/pubkey.pem"

echo "=== PIV スロット 9d セットアップ ==="
echo ""

# YubiKey 確認
if ! ykman list 2>/dev/null | grep -q "YubiKey"; then
  echo "❌ YubiKey が検出されません。USB に差し込んでから再実行してください。"
  exit 1
fi

echo "✅ YubiKey を検出しました:"
ykman list
echo ""

# 既存鍵の確認
echo "[確認] スロット 9d の現在の状態:"
ykman piv info 2>/dev/null | grep -A3 "Key Management" || true
echo ""

read -p "スロット 9d に RSA-2048 鍵を生成します。既存の鍵は上書きされます。続けますか？ (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "キャンセルしました。"
  exit 0
fi

echo ""
echo "[1/3] RSA-2048 鍵をスロット 9d に生成中..."
echo "  (管理者キーのパスワードを求められた場合は Enter を押してください)"
ykman piv keys generate \
  --algorithm RSA2048 \
  --management-key 010203040506070801020304050607080102030405060708 \
  9d \
  "$PUBKEY_PATH"

echo "  ✅ 公開鍵を $PUBKEY_PATH に保存しました"
echo ""

echo "[2/3] 自己署名証明書を生成中（公開鍵を YubiKey 内で確認するため）..."
ykman piv certificates generate \
  --subject "CN=YubiKey-Tutorial" \
  --management-key 010203040506070801020304050607080102030405060708 \
  9d \
  "$PUBKEY_PATH"
echo "  ✅ 自己署名証明書を生成しました"
echo ""

echo "[3/3] PIV 状態の確認:"
ykman piv info

echo ""
echo "=== セットアップ完了 ==="
echo "公開鍵: $PUBKEY_PATH"
echo "次のステップ: node demo.js"
echo ""
echo "この公開鍵は dev プロジェクト（本番用）でもそのまま使えます。"
