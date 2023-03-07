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

lb, lh, lbu, lhu, sb, shは未実装

TangNano9Kで動作確認済み

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
