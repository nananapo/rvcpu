module StructPortModule(
    input wire clock,
    input wire reset,
    output wire struct packed {
        logic [7:0] value1;
        struct packed {
            logic [15:0] value2;
        } structInA;
    } structA
);
    assign structA.value1 = 8'd42;
    assign structA.structInA.value2 = 16'd65535;
endmodule