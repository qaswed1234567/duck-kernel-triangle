# -*- coding: utf-8 -*-
"""把 duck_kernel 加密成 duck_kernel.enc (16字节nonce + XOR流密文)。
密钥与 MainActivity.java 的 BIN_KEY_ENC / BIN_XOR 一一对应, 勿改。"""
import sys, os

# 16 字节文件加密密钥 (与 Java 端 binKey() 还原后一致)
KEY = bytes([
    0x3D, 0x7A, 0xC2, 0x51, 0x9E, 0x6B, 0xF4, 0x08,
    0xB7, 0x2C, 0x85, 0xE3, 0x4A, 0xD1, 0x96, 0x5F,
])

def encrypt(src, dst):
    nonce = os.urandom(16)
    with open(src, 'rb') as f:
        data = f.read()
    enc = bytearray(len(data))
    for i in range(len(data)):
        enc[i] = data[i] ^ KEY[i & 15] ^ nonce[i & 15]
    with open(dst, 'wb') as f:
        f.write(nonce)
        f.write(bytes(enc))
    print("[+] %s -> %s" % (os.path.basename(src), os.path.basename(dst)))
    print("    原文 %d 字节, 密文 %d 字节 (含16字节nonce)" % (len(data), 16 + len(data)))

if __name__ == '__main__':
    base = os.path.dirname(os.path.abspath(__file__))
    src = sys.argv[1] if len(sys.argv) > 1 else os.path.join(base, 'app', 'src', 'main', 'assets', 'duck_kernel')
    dst = sys.argv[2] if len(sys.argv) > 2 else os.path.join(base, 'app', 'src', 'main', 'assets', 'duck_kernel.enc')
    encrypt(src, dst)
