# rvcpu

[![behaviour tests](https://github.com/nananapo/rvcpu/actions/workflows/test.yml/badge.svg)](https://github.com/nananapo/rvcpu/actions/workflows/test.yml)
[![riscv-tests](https://github.com/nananapo/rvcpu/actions/workflows/riscv-tests-verilator.yml/badge.svg)](https://github.com/nananapo/rvcpu/actions/workflows/riscv-tests-verilator.yml)

```txt
      RAM
        |
        |-------------------------\
        |                      DCache
        |          ---------------|----------
     ICache        |         MisalignCntr   |
        |          |              |         |
       PTW----------          MMIO_Cntr     |
        |                         |         |
      Fetch                      PTW---------
        |                         |
        |---> ID -> DS -> EXE -> MEM -> CSR -> WB
                           |
                        Mul/Div
```

RV32IMA_Zicsr_Zicond_Zifencei CPU written in SystemVerilog

## riscv-tests
- [x] rv32mi-p
- [x] rv32si-p
- [x] rv32ui-p/v
- [x] rv32um-p/v
- [x] rv32ua-p/v
- [ ] rv32uc-p/v
- [ ] rv64

## メモリマップ
```
00000000 - MEM_SIZE : RAM
f0000000 - f0000007 : mtime
f0000008 - f000000f : mtimecmp
ff000000            : UART TX (storeで送信, loadの結果は不定)
ff000010            : UART RX (0ならバッファに文字列無し, 書き込みは無視)
ff000018            : UART RX (loadでバッファから1文字読みとる, 書き込みは無視)
```
MMIOにアラインされていないアクセスをした場合の結果は不定 (禁止)

## デバッグログについて

$display、$writeで出力しているデバッグ情報は、分析しやすくすることを目的として下記のフォーマットで出力しています。  
数字は必ず2進数で出力しているため、そのまま人が読むのは難しいです。人にとって読みやすい形にログを変換するには、log/log2human.pyを使用します。

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

デバッグログをkanataに変換するためには、log/log2kanata.pyを使用します。
