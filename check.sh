#!/bin/bash
# YubiKey PIV チュートリアル: 接続確認・環境チェック

echo "=== YubiKey 接続確認 ==="

# pcscd 起動確認
echo ""
echo "[1] pcscd (PC/SC デーモン) の状態:"
if systemctl is-active --quiet pcscd; then
  echo "  ✅ pcscd 起動中"
else
  echo "  ❌ pcscd が停止しています → sudo systemctl start pcscd を実行してください"
  exit 1
fi

# ykman インストール確認
echo ""
echo "[2] ykman のバージョン:"
if command -v ykman &> /dev/null; then
  ykman --version
  echo "  ✅ ykman インストール済み"
else
  echo "  ❌ ykman が見つかりません → bash install.sh を実行してください"
  exit 1
fi

# pkcs11-tool インストール確認
echo ""
echo "[3] pkcs11-tool のバージョン:"
if command -v pkcs11-tool &> /dev/null; then
  pkcs11-tool --version 2>&1 | head -1
  echo "  ✅ pkcs11-tool インストール済み"
else
  echo "  ❌ pkcs11-tool が見つかりません → bash install.sh を実行してください"
  exit 1
fi

# YubiKey 検出確認
echo ""
echo "[4] YubiKey の検出:"
if ykman list 2>/dev/null | grep -q "YubiKey"; then
  ykman list
  echo "  ✅ YubiKey を検出しました"
else
  echo "  ❌ YubiKey が見つかりません → USB に差し込んでください"
  exit 1
fi

# PIV スロット 9d の状態確認
echo ""
echo "[5] PIV スロット 9d (Key Management) の状態:"
ykman piv info 2>/dev/null | grep -A2 "Key Management" || echo "  (情報なし)"

# libykcs11.so の場所確認
echo ""
echo "[6] ykcs11 ライブラリのパス:"
YKCS11_PATH=$(find /usr/lib -name "libykcs11.so" 2>/dev/null | head -1)
if [ -n "$YKCS11_PATH" ]; then
  echo "  ✅ $YKCS11_PATH"
else
  echo "  ❌ libykcs11.so が見つかりません → bash install.sh を実行してください"
fi

echo ""
echo "=== チェック完了 ==="
echo "次のステップ: bash setup-piv.sh"
