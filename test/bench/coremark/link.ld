OUTPUT_ARCH( "riscv" )
ENTRY(_entry)

SECTIONS
{
  . = 0x00000000;
  .text : { 
    *(.entry_sec)
    . = ALIGN(0x4000);
    *(.startup_main)
    *(.text) 
  }
  .data : { *(.data) }
  .bss : { *(.bss) }
  _end = .;
}