module test();
  reg rst_n = 0;
  reg clk = 0;
  wire [5:0] led;

  main #() m(
    .rst_n(rst_n),
    .clk(clk),
    .led(led)
  );

  always
    #1 clk = ~clk;

  initial begin
    $display("Starting");
    #1000 $finish;
  end

  initial begin
    $dumpfile("debug.vcd");
    $dumpvars(0,test);
  end

endmodule
