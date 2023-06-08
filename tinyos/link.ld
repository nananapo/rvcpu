OUTPUT_ARCH( "riscv" )
ENTRY(main)

SECTIONS
{
  . = 0x00000000;
  .text : { 
    *(.kernelEntry)
    . = 0x00001800;
    *(.text)
    . = ALIGN(0x1000);
    PROVIDE(etext = .);
  }
  .data : { *(.data) }
  .bss : { *(.bss) }
  PROVIDE(kernel_endaddr = .);
}
