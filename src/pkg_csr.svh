`ifndef PKG_CSR_H
`define PKG_CSR_H

package csr;
typedef enum logic [1:0] {
    M_MODE = 2'b11, // Machine Mode
    H_MODE = 2'b10, // Hypervisor Mode
    S_MODE = 2'b01, // Supervisor Mode
    U_MODE = 2'b00  // User Mode
} Mode;
endpackage

package CsrAddr;
// TODO XLEN = 64
localparam CYCLE         = 12'hc00;
localparam TIME          = 12'hc01;
localparam CYCLEH        = 12'hc80;
localparam TIMEH         = 12'hc81;
// Supervisor Trap Setup
localparam SSTATUS       = 12'h100;
localparam SIE           = 12'h104;
localparam STVEC         = 12'h105;
localparam SCOUNTEREN    = 12'h106; // 5.1.5 U-modeがcycle, time, instret, or hpmcounternにアクセスできるかどうかのフラグ
// Supervisor Configuration
// Supervisor Trap Handling
localparam SSCRATCH      = 12'h140;
localparam SEPC          = 12'h141;
localparam SCAUSE        = 12'h142;
localparam STVAL         = 12'h143;
localparam SIP           = 12'h144;
// Supervisor Protection and Translation
localparam SATP          = 12'h180;
// Debug/Trace Registers
// Machine Information Registers
// Machine Trap Setup
localparam MSTATUS       = 12'h300;
localparam MISA          = 12'h301; // RV32IM(A)
localparam MEDELEG       = 12'h302;
localparam MIDELEG       = 12'h303;
localparam MIE           = 12'h304;
localparam MTVEC         = 12'h305;
localparam MCOUNTEREN    = 12'h306;
localparam MSTATUSH      = 12'h310;
// Machine Trap Handling
localparam MSCRATCH      = 12'h340; // 自由
localparam MEPC          = 12'h341; // M-modeにトラップするとき、仮想アドレスに設定する
localparam MCAUSE        = 12'h342; // trapするときに書き込む。上位1bitでInterruptかを判断する
localparam MTVAL         = 12'h343; // exceptionなら実装によって書き込まれる。だが、read-only zeroでもよい
localparam MIP           = 12'h344; // 3.1.9
localparam MTINST        = 12'h34a; // 9.4.5
localparam MTVAL2        = 12'h34b;
// Machine Configuration
// Machine Memory Protection
// Machine Non-Maskable Interrupt Handling 未確認
// Machine Counter/Timers
localparam MCYCLE        = 12'hb00;
localparam MINSTRET      = 12'hb02;
localparam MCYCLEH       = 12'hb80;
localparam MINSTRETH     = 12'hb82;
// localparam INSTRET        = 12'hc02; // read-only 0
// localparam HPMCOUNTER~    = 12'hc03 ~ 12'hc1f; // read-only 0
// localparam INSTRETH       = 12'hc82;
// localparam HPMCOUNTERH~   = 12'hc83 ~ 12'hc9f; // read-only 0
// localparam SENVCFG        = 12'h10a; // read-only 0
// localparam SCONTEXT       = 12'h5a8
// localparam MVENDORID      = 12'hf11; // read-only 0
// localparam MARCHID        = 12'hf12; // read-only 0
// localparam MIMPID         = 12'hf13; // read-only 0
// localparam MHARTID        = 12'hf14; // read-only 0
// localparam MCONFIGPTR     = 12'hf15; // read-only 0
// localparam MENVCFG        = 12'h30A; // 未確認
// localparam MENVCFGH       = 12'h31A; // 未確認
// localparam MSECCFG        = 12'h747; // 未確認
// localparam MSECCFGH       = 12'h757; // 未確認
// localparam PMPADDR0       = 12'h3B0; // read-only 0 // 実装しない
// localparam PMPCFG0        = 12'h3A0; // read-only 0 // 実装しない
endpackage

package CsrCause;

`ifdef XLEN32
    localparam INTERRUPT_BIT = 32'h80000000;
`else
    localparam INTERRUPT_BIT = 64'h80000000_00000000;
`endif
                                                                // I ECODE Description 
localparam SUPERVISOR_SOFTWARE_INTERRUPT  = INTERRUPT_BIT | 1;   // 1 1     Supervisor software interrupt
localparam MACHINE_SOFTWARE_INTERRUPT     = INTERRUPT_BIT | 3;   // 1 3     Machine software interrupt
localparam SUPERVISOR_TIMER_INTERRUPT     = INTERRUPT_BIT | 5;   // 1 5     Supervisor timer interrupt
localparam MACHINE_TIMER_INTERRUPT        = INTERRUPT_BIT | 7;   // 1 7     Machine timer interrupt
localparam SUPERVISOR_EXTERNAL_INTERRUPT  = INTERRUPT_BIT | 9;   // 1 9     Supervisor external interrupt
localparam MACHINE_EXTERNAL_INTERRUPT     = INTERRUPT_BIT | 11;  // 1 11    Machine external interrupt
                                                    // I ECODE Description 
localparam INSTRUCTION_ADDRESS_MISALIGNED = 0;   // 0 0     Instruction address misaligned
localparam INSTRUCTION_ACCESS_FAULT       = 1;   // 0 1     Instruction access fault
localparam ILLEGAL_INSTRUCTION            = 2;   // 0 2     Illegal instruction
localparam BREAKPOINT                     = 3;   // 0 3     Breakpoint
localparam LOAD_ADDRESS_MISALIGNED        = 4;   // 0 4     Load address misaligned
localparam LOAD_ACCESS_FAULT              = 5;   // 0 5     Load access fault
localparam STORE_AMO_ADDRESS_MISALIGNED   = 6;   // 0 6     Store/AMO address misaligned
localparam STORE_AMO_ACCESS_FAULT         = 7;   // 0 7     Store/AMO access fault
localparam ENVIRONMENT_CALL_FROM_U_MODE   = 8;   // 0 8     Environment call from U-mode
localparam ENVIRONMENT_CALL_FROM_S_MODE   = 9;   // 0 9     Environment call from S-mode
localparam ENVIRONMENT_CALL_FROM_M_MODE   = 11;  // 0 11    Environment call from M-mode
localparam INSTRUCTION_PAGE_FAULT         = 12;  // 0 12    Instruction page fault
localparam LOAD_PAGE_FAULT                = 13;  // 0 13    Load page fault
localparam STORE_AMO_PAGE_FAULT           = 15;  // 0 15    Store/AMO page fault

endpackage

`endif