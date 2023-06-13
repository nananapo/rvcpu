# rvcpu

Verilogで記述されたRISC-V(RV32IM)のCPUです。  
「RISC-VとChiselで学ぶ　はじめてのCPU自作」という本を参考に実装しはじめました  
TangNano9Kで動くことを確認しています。

## 第二部 簡単なCPUの実装
https://github.com/nananapo/rvcpu/tree/8424b1996c31f129cd42e1bad60f8112c8c1eaa4 

追加実装
* lb, lh, lbu, lhu命令
* sb, sh命令
* メモリ操作でuart_tx

TangNano9Kで動作確認済み

## 第三部 パイプラインの実装

https://github.com/nananapo/rvcpu/pull/18/commits/16bf103d1a4932d5d3c33b1546c6bdf7b2b5114c らへんまで

CSR命令とメモリ命令を並列に動かす5段パイプライン  
* IF -> ID -> EXE -> MEM(or CSR) -> WB

追加実装
* Zifencei拡張
    - [x] fence.i
* RV32M拡張
    - [x] div
    - [x] divu
    - [x] mul
    - [x] mulh
    - [x] mulhsu
    - [x] mulhu
    - [x] rem
    - [x] remu
* CSR
    - [x] mret命令
    - [x] M-modeでのタイマ割込み

## 2023/05/22? ~ 今

変更点
* IFステージを消して、キューにフェッチした命令を入れていくモジュールを作成した
* 2bit分岐予測器を作成した
* 4byteアラインされていない命令フェッチは行えなくした
* CSRステージをEXEと同時に実行させるようにした
* レジスタ(またはフォワーディングされる)のデータを受け取る処理をIDステージから分離して新しいステージ(DS)を作成した
* kanata log formatに対応(log/convert2kanata.py)し、Konataでパイプラインの状態を見れるようにした
* ログを読みやすくするスクリプトを作成した (log/convert2humanreadable.py)
* CoreMarkを動作させた

簡単な図
```txt
    Memory  UART(TX/RX) MemoryMappedRegister
       |         |                |
       -----MemMapCntr-------------
                 |
        ----MemCmdCntr-------
        |                   |
    InstQueue   DUnalignedAccessController
        |                   |
Core---------------------------------
|       |                   |
|   IF/ID -> DS -> CSR -> MEM -> WB
|               -> EXE ->
|                   |
|           MulNbit/DivNbit
```


### メモリマップ
```
00000000 - 00008000 : RAM
f0000000 - f0000007 : mtime
f0000008 - f000000f : mtimecmp
ff000000 - ff0000ff : UART TX (文字列のキュー)
ff000100            : UART TX (キューの末尾のindex(送信するときはこれを進める(mod 256する)))
ff000104            : UART TX (キューの先頭のindex(読み込み可 / 書き込み不可))
ff000200 - ff0005ff : UART RX (文字列のバッファ)
ff000600            : UART RX (バッファの末尾のindex % 1024)
ff000604            : UART RX (バッファを何周したか)
```

### サンプルプログラム

|  ファイル名  |  概要  |
| ---- | ---- |
|  [test/c/uart_rx.c](https://github.com/nananapo/rvcpu/blob/main/test/c/uart_rx.c)  |  UART_RXで受信した文字に基づいてLEDの点灯を変えます  |
|  [test/c/uart_tx.c](https://github.com/nananapo/rvcpu/blob/main/test/c/uart_tx.c)  |  UART_TXで「Hello World!」を送信します  |

## デバッグログについて

$display、$writeで出力しているデバッグ情報は、機械で分析しやすくすることを目的として下記のフォーマットで出力しています。  
数字は必ず2進数で出力しているため、そのまま人が読むのは難しいです。人にとって読みやすい形にログを変換するには、log/convert2humanreadable.pyを使用します。

### フォーマット

ログが始まることを示す
```
START_DEBUG_LOG
```

クロックが始まることを表す
```txt
clock,何クロック目か(10進数表現 {0,1,2,3,4,5,6,7,8,9})
```

数字
```txt
data,データ名,何進数で表示するのがよいか(b, d, h),データ(2進数表現 {0,1,x,z})
```

テキスト
```txt
info,情報名,テキスト
```

### kanata log formatへの変換
![image](https://github.com/nananapo/rvcpu/assets/26675945/e1ced527-0668-405a-a5f0-2200868b8baa)
[Kanata Log Format](https://github.com/shioyadan/Konata/blob/master/docs/kanata-log-format.md)は、パイプラインの状態を表すことができるログのフォーマットです。[shioyadan/Konata](https://github.com/shioyadan/Konata)で表示することができます。

デバッグログをkanataに変換するためには、log/convert2kanata.pyを使用します。