# rvcpu

「RISC-VとChiselで学ぶ　はじめてのCPU自作」本を参考にVerilogでRISC-Vを実装したもの
TangNano9Kで動くことを確認済み

### 第二部 簡単なCPUの実装まで
https://github.com/nananapo/rvcpu/tree/8424b1996c31f129cd42e1bad60f8112c8c1eaa4  
追加でlb, lh, lbu, lhu, sb, sh命令を実装した

### 第三部 パイプラインの実装
lb, lh, lbu, lhu, sb, shを捨てて実装
CSR命令とメモリ命令を並列に動かす5段パイプライン
