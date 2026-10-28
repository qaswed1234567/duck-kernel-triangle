# -*- coding: utf-8 -*-
"""验证: 用 Java 端同样的密钥解密 duck_kernel.enc, 应与原始 ELF 完全一致。"""
import os

base = os.path.dirname(os.path.abspath(__file__))
KEY = bytes([
    0x3D, 0x7A, 0xC2, 0x51, 0x9E, 0x6B, 0xF4, 0x08,
    0xB7, 0x2C, 0x85, 0xE3, 0x4A, 0xD1, 0x96, 0x5F,
])

enc_path = os.path.join(base, '..', '..', 'app', 'src', 'main', 'assets', 'duck_kernel.enc')
with open(enc_path, 'rb') as f:
    blob = f.read()

nonce = blob[:16]
cipher = blob[16:]
plain = bytearray(len(cipher))
for i in range(len(cipher)):
    plain[i] = cipher[i] ^ KEY[i & 15] ^ nonce[i & 15]

# 校验 ELF 魔数
magic = bytes(plain[:4])
print("解密后 ELF 魔数:", magic)
assert magic == b'\x7fELF', "不是有效 ELF!"

# 与原编译产物比对
orig = os.path.join('D:\\duck_build', 'jni', 'libs', 'arm64-v8a', 'duck_kernel')
with open(orig, 'rb') as f:
    orig_data = f.read()
print("原始大小:", len(orig_data), " 解密大小:", len(plain))
assert bytes(plain) == orig_data, "解密结果与原始不一致!"
print("PASS: 解密结果与原始 duck_kernel 完全一致")
