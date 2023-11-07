// 設定ファイル、依存はない
`include "pkg_conf.svh"
// iid、依存はない
`include "pkg_iid.svh"
// confにのみ依存
`include "pkg_csr.svh"
`include "pkg_basic.svh"
// basicにのみ依存
`include "pkg_util.svh"
// basic, utilに依存
`include "pkg_memory.svh"
// basic, iidに依存
`include "pkg_meminf.svh"
// basic, iid, meminfに依存
`include "pkg_stageinfo.svh"
// basic, stageinfoに依存
`include "pkg_muldiv.svh"