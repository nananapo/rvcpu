`include "pkg_conf.svh"     // 設定ファイル、依存はない
`include "pkg_csr.svh"      // confにのみ依存
`include "pkg_basic.svh"    // confにのみ依存

`include "pkg_util.svh"     // basicにのみ依存

`include "pkg_iid.svh"

`include "pkg_meminf.svh" // basic, iidに依存

`include "pkg_stageinfo.svh" // basic, iid, meminfに依存

`include "pkg_muldiv.svh" // basic, stageinfoに依存

`include "pkg_memory.svh"