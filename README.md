# rvcpu

「RISC-VとChiselで学ぶ　はじめてのCPU自作」本を参考にVerilogでRISC-Vを実装したもの  

### 第二部 簡単なCPUの実装
https://github.com/nananapo/rvcpu/tree/8424b1996c31f129cd42e1bad60f8112c8c1eaa4  

追加実装
* lb, lh, lbu, lhu命令
* sb, sh命令
* メモリ操作でuart_tx

TangNano9Kで動作確認済み

### 第三部 パイプラインの実装

CSR命令とメモリ命令を並列に動かす5段パイプライン  
* IF -> ID -> EXE -> MEM(or CSR) -> WB

追加実装
* Zifencei fence.i命令

TangNano9Kで動作確認済み

#### メモリマップ
```
00000000 - 00004000 : RAM
ff000000 - ff0000ff : UART TX (文字列のキュー)
ff000100            : UART TX (キューの末尾のindex(送信するときはこれを進める(mod 256する)))
ff000104            : UART TX (キューの先頭のindex(読み込み可 / 書き込み不可))
ff000200 - ff0005ff : UART RX (文字列のバッファ)
ff000600            : UART RX (バッファの末尾のindex % 1024)
ff000604            : UART RX (バッファを何周したか)
```

#### サンプルプログラム

|  ファイル名  |  概要  |
| ---- | ---- |
|  [test/c/uart_rx.c](https://github.com/nananapo/rvcpu/blob/main/test/c/uart_rx.c)  |  UART_RXで受信した文字に基づいてLEDの点灯を変えます  |
|  [test/c/uart_tx.c](https://github.com/nananapo/rvcpu/blob/main/test/c/uart_tx.c)  |  UART_TXで「Hello World!」を送信します  |

#### シリアル通信でメモリ操作

UARTでメモリ操作(load, store)を行います  

```sh
$ python3 test/uart/hand.py
input port : COM4
--------------------
INST :  LOAD
ADDR :  00000000
DATA :  0480006f
-------------------- 
INST :  LOAD
ADDR :  00000004     
DATA :  34202f73
--------------------  
INST :  LOAD
ADDR :  00000048      
DATA :  00000093
...
```

下記をコメントアウトすると、[test/uart/hand.py](https://github.com/nananapo/rvcpu/blob/main/test/uart/hand.py) で試すことができます
https://github.com/nananapo/rvcpu/blob/8ffd14d2b5fd7aa3b2b501a41bf194a244ea2803/src/include/memoryinterface.v#L1
