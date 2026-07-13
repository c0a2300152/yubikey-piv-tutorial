#!/bin/bash
# YubiKey PIV チュートリアル: 依存パッケージインストール
set -e

echo "=== YubiKey PIV 環境セットアップ ==="

echo ""
echo "[1/4] pcscd (PC/SC デーモン) をインストール中..."
sudo apt-get install -y pcscd

echo ""
echo "[2/4] yubikey-manager (ykman) をインストール中..."
sudo apt-get install -y yubikey-manager

echo ""
echo "[3/4] opensc (pkcs11-tool) をインストール中..."
sudo apt-get install -y opensc

echo ""
echo "[4/4] ykcs11 (YubiKey PKCS#11 ライブラリ) をインストール中..."
sudo apt-get install -y ykcs11

echo ""
echo "[pcscd] サービスを起動中..."
sudo systemctl enable pcscd
sudo systemctl start pcscd

echo ""
echo "=== インストール完了 ==="
echo "次のステップ: YubiKey を USB に差し込んで bash check.sh を実行"
