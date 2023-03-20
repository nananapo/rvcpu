OUTPUT_ARCH( "riscv" )
ENTRY(main)

SECTIONS
{
  . = 0x00000000;
  .text : { 
    *(.kernelEntry)
    . = 0x00001800;
    *(.text)
  }
  .data : { *(.data) }
  .bss : { *(.bss) }
  _end = .;
}
