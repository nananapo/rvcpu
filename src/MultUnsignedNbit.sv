module MultUnsignedNbit #(
    parameter SIZE = 32
) (
    input wire  clk,

    input wire  start,
    output wire ready,
    output wire valid,

    input wire [SIZE-1:0]   multiplicand,   // 被乗数
    input wire [SIZE-1:0]   multiplier,     // 乗数
    output logic [SIZE*2-1:0] product         // 積
);

typedef enum logic [1:0] { 
    IDLE, EXECUTE, DONE
} statetype;

statetype state = IDLE;

logic [9:0] count = 0;

logic [SIZE*2-1:0] save_multiplicand;
logic [SIZE-1:0] save_multiplier;

assign ready = state == IDLE;
assign valid = state == DONE;

always @(posedge clk) begin
    case (state)
        IDLE: begin
            if (start) begin
                state               <= EXECUTE;
                save_multiplicand   <= {{SIZE{1'b0}}, multiplicand};
                save_multiplier     <= multiplier;
                product             <= 0;
                count               <= 0;
            end
        end
        EXECUTE: begin
            if (count == SIZE - 1)
                state <= DONE;
            if (save_multiplier[0] == 1)
                product <= product + save_multiplicand;
            save_multiplicand   <= save_multiplicand << 1;
            save_multiplier     <= save_multiplier >> 1; 
            count               <= count + 1;
        end
        default: state <= IDLE;
    endcase
end

`ifdef PRINT_DEBUGINFO
`ifdef PRINT_ALU_MODULE
always @(posedge clk) begin
    $display("data,multunbit.input.start,b,%b", start);
    $display("data,multunbit.input.ready,b,%b", ready);
    $display("data,multunbit.input.valid,b,%b", valid);
    $display("data,multunbit.input.multiplicand,d,%b", multiplicand);
    $display("data,multunbit.input.multiplier,d,%b", multiplier);
    $display("data,multunbit.output.product,d,%b", product);
    
    $display("data,multunbit.state,d,%b", state);
    $display("data,multunbit.count,d,%b", count);
    $display("data,multunbit.save_multiplicand,d,%b", save_multiplicand);
    $display("data,multunbit.save_multiplier,d,%b", save_multiplier);
end
`endif
`endif

endmodule