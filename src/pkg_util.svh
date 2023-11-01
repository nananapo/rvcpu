`ifndef PKG_UTIL_H
`define PKG_UTIL_H

package util;

// AddrがIALIGNにALIGNされているかどうか
// TODO IALIGNを使う
function ialigned(input Addr addr);
    ialigned = ~|addr[1:0];
endfunction

// addrがleftからrightの間にあるかどうか
// TODO Addrというパッケージを作る？
function x_in_range(
    input UIntX addr,
    input UIntX left,
    input UIntX right
);
    x_in_range = left <= addr && addr <= right;
endfunction

endpackage

`endif