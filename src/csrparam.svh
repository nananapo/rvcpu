// Table 3.6
                                                                                           // I ECODE Description 
localparam CAUSE_SUPERVISOR_SOFTWARE_INTERRUPT  = 32'b10000000_00000000_00000000_00000001; // 1 1     Supervisor software interrupt
localparam CAUSE_MACHINE_SOFTWARE_INTERRUPT     = 32'b10000000_00000000_00000000_00000011; // 1 3     Machine software interrupt
localparam CAUSE_SUPERVISOR_TIMER_INTERRUPT     = 32'b10000000_00000000_00000000_00000101; // 1 5     Supervisor timer interrupt
localparam CAUSE_MACHINE_TIMER_INTERRUPT        = 32'b10000000_00000000_00000000_00000111; // 1 7     Machine timer interrupt
localparam CAUSE_SUPERVISOR_EXTERNAL_INTERRUPT  = 32'b10000000_00000000_00000000_00001001; // 1 9     Supervisor external interrupt
localparam CAUSE_MACHINE_EXTERNAL_INTERRUPT     = 32'b10000000_00000000_00000000_00001011; // 1 11    Machine external interrupt
                                                             // I ECODE Description 
localparam CAUSE_INSTRUCTION_ADDRESS_MISALIGNED = 32'b0000; // 0 0     Instruction address misaligned
localparam CAUSE_INSTRUCTION_ACCESS_FAULT       = 32'b0001; // 0 1     Instruction access fault
localparam CAUSE_ILLEGAL_INSTRUCTION            = 32'b0010; // 0 2     Illegal instruction
localparam CAUSE_BREAKPOINT                     = 32'b0011; // 0 3     Breakpoint
localparam CAUSE_LOAD_ADDRESS_MISALIGNED        = 32'b0100; // 0 4     Load address misaligned
localparam CAUSE_LOAD_ACCESS_FAULT              = 32'b0101; // 0 5     Load access fault
localparam CAUSE_STORE_AMO_ADDRESS_MISALIGNED   = 32'b0110; // 0 6     Store/AMO address misaligned
localparam CAUSE_STORE_AMO_ACCESS_FAULT         = 32'b0111; // 0 7     Store/AMO access fault
localparam CAUSE_ENVIRONMENT_CALL_FROM_U_MODE   = 32'b1000; // 0 8     Environment call from U-mode
localparam CAUSE_ENVIRONMENT_CALL_FROM_S_MODE   = 32'b1001; // 0 9     Environment call from S-mode
localparam CAUSE_ENVIRONMENT_CALL_FROM_M_MODE   = 32'b1011; // 0 11    Environment call from M-mode
localparam CAUSE_INSTRUCTION_PAGE_FAULT         = 32'b1100; // 0 12    Instruction page fault
localparam CAUSE_LOAD_PAGE_FAULT                = 32'b1101; // 0 13    Load page fault
localparam CAUSE_STORE_AMO_PAGE_FAULT           = 32'b1111; // 0 15    Store/AMO page fault