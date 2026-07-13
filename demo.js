/**
 * YubiKey PIV デモ
 *
 * 流れ:
 *   1. pubkey.pem (YubiKey の公開鍵) を読み込む
 *   2. Node.js crypto で RSA-OAEP 暗号化
 *   3. pkcs11-tool 経由で YubiKey が RSA-OAEP 復号（YubiKey 内で処理）
 *   4. 復号結果が元のメッセージと一致するか検証
 *
 * 実行: node demo.js
 * 必要: YubiKey を USB に差し込んだ状態で実行
 */

import { readFileSync, writeFileSync, unlinkSync, existsSync } from 'fs';
import { publicEncrypt, constants } from 'crypto';
import { execFileSync } from 'child_process';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

const PUBKEY_PATH  = join(__dirname, 'pubkey.pem');
const ENC_TMP      = join(__dirname, 'encrypted.tmp.bin');
const DEC_TMP      = join(__dirname, 'decrypted.tmp.bin');
const MESSAGE      = 'Hello, YubiKey!';
const PIN          = '123456'; // デフォルト PIN

// --- YubiKey PKCS#11 ライブラリのパス検索 ---
function findYkcs11() {
  const candidates = [
    '/usr/lib/x86_64-linux-gnu/libykcs11.so',
    '/usr/lib/aarch64-linux-gnu/libykcs11.so',
    '/usr/lib/libykcs11.so',
  ];
  for (const p of candidates) {
    if (existsSync(p)) return p;
  }
  throw new Error(
    'libykcs11.so が見つかりません。bash install.sh を実行してください。'
  );
}

// --- メイン処理 ---
async function main() {
  console.log('=== YubiKey PIV デモ ===\n');

  // pubkey.pem 確認
  if (!existsSync(PUBKEY_PATH)) {
    console.error('❌ pubkey.pem が見つかりません。先に bash setup-piv.sh を実行してください。');
    process.exit(1);
  }

  // [Step 1] 公開鍵を読み込む
  console.log('[Step 1] 公開鍵を読み込み中...');
  const publicKey = readFileSync(PUBKEY_PATH, 'utf8');
  console.log('  ✅ pubkey.pem を読み込みました\n');

  // [Step 2] RSA-OAEP 暗号化
  console.log('[Step 2] RSA-OAEP 暗号化中...');
  console.log(`  元メッセージ: "${MESSAGE}"`);
  const encrypted = publicEncrypt(
    { key: publicKey, padding: constants.RSA_PKCS1_OAEP_PADDING, oaepHash: 'sha256' },
    Buffer.from(MESSAGE, 'utf8')
  );
  writeFileSync(ENC_TMP, encrypted);
  console.log(`  暗号化完了 (${encrypted.length} bytes) → encrypted.tmp.bin\n`);

  // [Step 3] YubiKey で復号（pkcs11-tool 経由）
  console.log('[Step 3] YubiKey で RSA-OAEP 復号中...');
  console.log('  (YubiKey 内部で秘密鍵処理。鍵は外に出ません)\n');

  const ykcs11 = findYkcs11();
  console.log(`  使用ライブラリ: ${ykcs11}`);

  try {
    execFileSync('pkcs11-tool', [
      '--module',    ykcs11,
      '--decrypt',
      '--mechanism', 'RSA-PKCS-OAEP',
      '--hash-algorithm', 'SHA256',
      '--mgf',       'MGF1-SHA256',
      '--slot',      '0',
      '--login',
      '--pin',       PIN,
      '--input-file',  ENC_TMP,
      '--output-file', DEC_TMP,
    ], { stdio: ['ignore', 'pipe', 'pipe'] });
  } catch (err) {
    const stderr = err.stderr?.toString() || '';
    console.error('❌ YubiKey 復号エラー:');
    console.error(stderr);
    process.exit(1);
  }

  // [Step 4] 検証
  console.log('\n[Step 4] 検証中...');
  const decrypted = readFileSync(DEC_TMP, 'utf8').trim();
  console.log(`  復号結果: "${decrypted}"`);

  if (decrypted === MESSAGE) {
    console.log('\n✅ 成功: YubiKey による RSA-OAEP 復号が正常に動作しています！');
    console.log(`  暗号文: ${ENC_TMP}`);
    console.log(`  復号文: ${DEC_TMP}`);
    console.log('\nこの公開鍵 (pubkey.pem) は dev プロジェクトの本番 YubiKey 連携にそのまま使えます。');
  } else {
    console.error('\n❌ 失敗: 復号結果が元のメッセージと一致しません。');
    process.exit(1);
  }
}

function cleanup() {
  for (const f of [ENC_TMP, DEC_TMP]) {
    if (existsSync(f)) unlinkSync(f);
  }
}

main().catch(err => {
  console.error('エラー:', err.message);
  process.exit(1);
});
