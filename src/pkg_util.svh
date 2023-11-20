`ifndef PKG_UTIL_H
`define PKG_UTIL_H

// fflushして強制終了
`define ffinish \
    begin \
        `ifdef RISCV_TESTS \
            if (util::test_success == 0) $fatal(1, "test : unexpected finish"); \
        `endif \
        $fflush;$finish;$finish;$finish;$finish;$finish;$finish; \
    end

// TODO logはpackageではなくclassにしてみる？
package util;

import basic::Addr, basic::UIntX;

`ifdef RISCV_TESTS
    int test_success = 0;
`endif

int logLevel = 0;

function void setLogLevel(int level);
    logLevel = level;
endfunction

function logic logEnabled();
`ifdef PRINT_DEBUGINFO
    logEnabled = logLevel !== 0;
`else
    logEnabled = 0;
`endif
endfunction

// TODO logのlevelに応じた関数でdisplayする

// AddrがIALIGNにALIGNされているかどうか
// TODO IALIGNを使う
function logic ialigned(input Addr addr);
    ialigned = ~|addr[1:0];
endfunction

// addrがleftからrightの間にあるかどうか
// TODO Addrというパッケージを作る？
function logic x_in_range(
    input UIntX addr,
    input UIntX left,
    input UIntX right
);
    x_in_range = left <= addr && addr <= right;
endfunction

endpackage

`endif