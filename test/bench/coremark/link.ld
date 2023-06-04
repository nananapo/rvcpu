OUTPUT_ARCH( "riscv" )
ENTRY(main)

SECTIONS
{
  . = 0x00000000;
  .text : { 
    *(.text.startup)
    *(.text) 
  }
  .data : { *(.data) }
  .bss : { *(.bss) }
  _end = .;
}