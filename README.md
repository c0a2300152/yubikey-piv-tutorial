# YubiKey PIV チュートリアル

YubiKey の PIV 機能を使って RSA-OAEP 暗号化・復号を体験するデモ。

---

## 実行手順

### Step 0: YubiKey を WSL に接続する（毎回）

WSL2 は USB デバイスを自動認識しないため、**Windows 側の操作が必要**。

#### usbipd-win のインストール（初回のみ・未インストールの場合）

```powershell
winget install usbipd
```

インストール後は PowerShell を再起動する。

**PowerShell（管理者）で実行：**

```powershell
# YubiKey の BUSID を確認（VID 1050 が Yubico）
usbipd list

# 初回のみ：共有を有効化（例: BUSID が 3-3 の場合）
usbipd bind --busid 3-3

# WSL に接続（WSL 再起動のたびに毎回実行）
usbipd attach --wsl --busid 3-3
```

> ⚠️ `usbipd` は **Windows コマンド**。WSL のターミナルでは実行しないこと。  
> `Already attached to a client` と表示された場合は接続済みなので次へ進む。

---

### Step 1: インストール（初回のみ）

WSL のターミナルで：

```bash
bash install.sh
```

インストールされるもの：`pcscd` / `yubikey-manager` / `opensc` / `ykcs11`

---

### Step 2: pcscd を起動して接続確認

```bash
sudo systemctl start pcscd
bash check.sh
```

`✅ YubiKey を検出しました` が表示されれば OK。

---

### Step 3: PIV スロットに RSA 鍵[公開鍵と秘密鍵のペア]を生成（初回のみ）

```bash
bash setup-piv.sh
```

- YubiKey のスロット 9d（Key Management）に RSA-2048 鍵を生成
- 公開鍵を `pubkey.pem` として保存
- **この鍵は dev プロジェクトの本番用としてそのまま使える**

---

### Step 4: デモ実行

```bash
sudo $(which node) demo.js
```

> ⚠️ `sudo node demo.js` ではなく `sudo $(which node) demo.js` を使うこと。  
> `node` が nvm でインストールされている場合、sudo の PATH に含まれないため。

**動作:**
1. `pubkey.pem` を読み込む
2. `"Hello, YubiKey!"` を RSA-OAEP で暗号化 → `encrypted.tmp.bin`
3. YubiKey 内部で秘密鍵を使って復号（鍵はデバイス外に出ない）→ `decrypted.tmp.bin`
4. 復号結果を検証 → `✅ 成功` と表示

---

### トラブルシューティング

| エラー | 原因 | 対処 |
|---|---|---|
| `EACCES: permission denied` (encrypted.tmp.bin) | 以前 sudo で作成したファイルが残っている | `sudo rm encrypted.tmp.bin decrypted.tmp.bin` |
| `CKR_DEVICE_ERROR` | pcscd が停止しているか YubiKey が未接続 | `sudo systemctl start pcscd` の後 check.sh で確認 |
| `sudo: node: command not found` | sudo の PATH に node がない（nvm 環境） | `sudo $(which node) demo.js` を使う |
| `usbipd: command not found`（WSL 内） | usbipd は Windows コマンド | PowerShell（管理者）で実行する |

---


## 注意事項

- PIN を変更した場合は `demo.js` 内の `PIN` 変数を更新すること
- スロット 9d にすでに鍵がある場合は `setup-piv.sh` を実行すると上書きされる
- YubiKey を抜くと復号できなくなる（仕様どおり）
