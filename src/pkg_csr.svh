`ifndef PKG_CSR_H
`define PKG_CSR_H
package csrpkg;
    
endpackage

package CsrAddr;
// TODO XLEN = 64
parameter CYCLE         = 12'hc00;
parameter TIME          = 12'hc01;
parameter CYCLEH        = 12'hc80;
parameter TIMEH         = 12'hc81;
// Supervisor Trap Setup
parameter SSTATUS       = 12'h100;
parameter SIE           = 12'h104;
parameter STVEC         = 12'h105;
parameter SCOUNTEREN    = 12'h106; // 5.1.5 U-modeがcycle, time, instret, or hpmcounternにアクセスできるかどうかのフラグ
// Supervisor Configuration
// Supervisor Trap Handling
parameter SSCRATCH      = 12'h140;
parameter SEPC          = 12'h141;
parameter SCAUSE        = 12'h142;
parameter STVAL         = 12'h143;
parameter SIP           = 12'h144;
// Supervisor Protection and Translation
parameter SATP          = 12'h180;
// Debug/Trace Registers
// Machine Information Registers
// Machine Trap Setup
parameter MSTATUS       = 12'h300;
parameter MISA          = 12'h301; // RV32IM(A)
parameter MEDELEG       = 12'h302;
parameter MIDELEG       = 12'h303;
parameter MIE           = 12'h304;
parameter MTVEC         = 12'h305;
parameter MCOUNTEREN    = 12'h306;
parameter MSTATUSH      = 12'h310;
// Machine Trap Handling
parameter MSCRATCH      = 12'h340; // 自由
parameter MEPC          = 12'h341; // M-modeにトラップするとき、仮想アドレスに設定する
parameter MCAUSE        = 12'h342; // trapするときに書き込む。上位1bitでInterruptかを判断する
parameter MTVAL         = 12'h343; // exceptionなら実装によって書き込まれる。だが、read-only zeroでもよい
parameter MIP           = 12'h344; // 3.1.9
parameter MTINST        = 12'h34a; // 9.4.5
parameter MTVAL2        = 12'h34b;
// Machine Configuration
// Machine Memory Protection
// Machine Non-Maskable Interrupt Handling 未確認
// Machine Counter/Timers
parameter MCYCLE        = 12'hb00;
parameter MINSTRET      = 12'hb02;
parameter MCYCLEH       = 12'hb80;
parameter MINSTRETH     = 12'hb82;
// parameter INSTRET        = 12'hc02; // read-only 0
// parameter HPMCOUNTER~    = 12'hc03 ~ 12'hc1f; // read-only 0
// parameter INSTRETH       = 12'hc82;
// parameter HPMCOUNTERH~   = 12'hc83 ~ 12'hc9f; // read-only 0
// parameter SENVCFG        = 12'h10a; // read-only 0
// parameter SCONTEXT       = 12'h5a8
// parameter MVENDORID      = 12'hf11; // read-only 0
// parameter MARCHID        = 12'hf12; // read-only 0
// parameter MIMPID         = 12'hf13; // read-only 0
// parameter MHARTID        = 12'hf14; // read-only 0
// parameter MCONFIGPTR     = 12'hf15; // read-only 0
// parameter MENVCFG        = 12'h30A; // 未確認
// parameter MENVCFGH       = 12'h31A; // 未確認
// parameter MSECCFG        = 12'h747; // 未確認
// parameter MSECCFGH       = 12'h757; // 未確認
// parameter PMPADDR0       = 12'h3B0; // read-only 0 // 実装しない
// parameter PMPCFG0        = 12'h3A0; // read-only 0 // 実装しない
endpackage

package CsrCause;

`ifdef XLEN32
    parameter INTERRUPT_BIT = 32'h80000000;
`else
    parameter INTERRUPT_BIT = 64'h80000000_00000000;
`endif
                                                                // I ECODE Description 
parameter SUPERVISOR_SOFTWARE_INTERRUPT  = INTERRUPT_BIT | 1;   // 1 1     Supervisor software interrupt
parameter MACHINE_SOFTWARE_INTERRUPT     = INTERRUPT_BIT | 3;   // 1 3     Machine software interrupt
parameter SUPERVISOR_TIMER_INTERRUPT     = INTERRUPT_BIT | 5;   // 1 5     Supervisor timer interrupt
parameter MACHINE_TIMER_INTERRUPT        = INTERRUPT_BIT | 7;   // 1 7     Machine timer interrupt
parameter SUPERVISOR_EXTERNAL_INTERRUPT  = INTERRUPT_BIT | 9;   // 1 9     Supervisor external interrupt
parameter MACHINE_EXTERNAL_INTERRUPT     = INTERRUPT_BIT | 11;  // 1 11    Machine external interrupt
                                                    // I ECODE Description 
parameter INSTRUCTION_ADDRESS_MISALIGNED = 0;   // 0 0     Instruction address misaligned
parameter INSTRUCTION_ACCESS_FAULT       = 1;   // 0 1     Instruction access fault
parameter ILLEGAL_INSTRUCTION            = 2;   // 0 2     Illegal instruction
parameter BREAKPOINT                     = 3;   // 0 3     Breakpoint
parameter LOAD_ADDRESS_MISALIGNED        = 4;   // 0 4     Load address misaligned
parameter LOAD_ACCESS_FAULT              = 5;   // 0 5     Load access fault
parameter STORE_AMO_ADDRESS_MISALIGNED   = 6;   // 0 6     Store/AMO address misaligned
parameter STORE_AMO_ACCESS_FAULT         = 7;   // 0 7     Store/AMO access fault
parameter ENVIRONMENT_CALL_FROM_U_MODE   = 8;   // 0 8     Environment call from U-mode
parameter ENVIRONMENT_CALL_FROM_S_MODE   = 9;   // 0 9     Environment call from S-mode
parameter ENVIRONMENT_CALL_FROM_M_MODE   = 10;  // 0 11    Environment call from M-mode
parameter INSTRUCTION_PAGE_FAULT         = 11;  // 0 12    Instruction page fault
parameter LOAD_PAGE_FAULT                = 12;  // 0 13    Load page fault
parameter STORE_AMO_PAGE_FAULT           = 13;  // 0 15    Store/AMO page fault
endpackage

`endif