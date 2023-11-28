.section .entry_sec
.globl main
.globl _entry
_entry:
        li sp, 1024*16
        call main
