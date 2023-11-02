`ifndef PKG_UTIL_H
`define PKG_UTIL_H

// TODO logはpackageではなくclassにしてみる？
package util;

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

// fflushして強制終了
task ffinish();
    $fflush;
    $finish;
    $finish;
    $finish;
    $finish;
endtask

// TODO logのlevelに応じた関数でdisplayする

// TODO finisher

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