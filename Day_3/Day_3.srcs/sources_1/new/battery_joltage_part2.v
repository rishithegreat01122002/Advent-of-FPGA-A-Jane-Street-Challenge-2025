`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/11/2026 11:12:06 AM
// Design Name: 
// Module Name: battery_joltage_part2
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module battery_joltage_part2 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  s_axis_tdata,
    input  wire        s_axis_tvalid,
    input  wire        s_axis_tlast,
    output reg         s_axis_tready,
    output reg [63:0]  total_joltage
);

    localparam TARGET_LEN = 12;
    localparam MAX_LINE_LEN = 1024;
    localparam S_READ      = 0;
    localparam S_PROCESS   = 1;
    localparam S_CALC_SUM  = 2;
    localparam S_ADD_TOTAL = 3;
    
    reg [2:0] state;
    reg [3:0] line_mem [0:MAX_LINE_LEN-1]; 
    reg [3:0] stack    [0:11];            
    reg [9:0] write_ptr; 
    reg [9:0] read_ptr;  
    reg [3:0] stack_ptr;
    reg [63:0] bank_value;
    reg [3:0]  calc_idx;
    
    wire [3:0] current_digit;
    wire [3:0] stack_top;
    wire [9:0] remaining_input;
    wire       can_pop;

    assign current_digit   = line_mem[read_ptr];
    assign stack_top       = stack[stack_ptr - 1];
    assign remaining_input = write_ptr - read_ptr; 
    assign can_pop         = (stack_ptr > 0) && ((stack_ptr - 1 + remaining_input) >= TARGET_LEN);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= S_READ;
            total_joltage <= 64'd0;
            write_ptr     <= 10'd0;
            read_ptr      <= 10'd0;
            stack_ptr     <= 4'd0;
            s_axis_tready <= 1'b0;
            bank_value    <= 64'd0;
            calc_idx      <= 4'd0;
        end else begin
            case (state)
                S_READ: begin
                    s_axis_tready <= 1'b1;
                    
                    if (s_axis_tvalid) begin
                        if (s_axis_tdata >= 8'h30 && s_axis_tdata <= 8'h39) begin
                            line_mem[write_ptr] <= s_axis_tdata[3:0];
                            write_ptr <= write_ptr + 1;
                        end

                        if (s_axis_tlast) begin
                            s_axis_tready <= 1'b0;
                            state         <= S_PROCESS;
                            read_ptr      <= 10'd0;
                            stack_ptr     <= 4'd0;
                        end
                    end
                end

                S_PROCESS: begin
                    if (read_ptr == write_ptr) begin
                        state      <= S_CALC_SUM;
                        bank_value <= 64'd0;
                        calc_idx   <= 4'd0;
                    end else begin
                        if (can_pop && (current_digit > stack_top)) begin
                            stack_ptr <= stack_ptr - 1; 
                        end 
                 
                        else begin
                            if (stack_ptr < TARGET_LEN) begin
                                stack[stack_ptr] <= current_digit;
                                stack_ptr        <= stack_ptr + 1;
                            end
                            // Move to next input digit
                            read_ptr <= read_ptr + 1;
                        end
                    end
                end


                S_CALC_SUM: begin
                    if (calc_idx == TARGET_LEN) begin
                        state <= S_ADD_TOTAL;
                    end else begin
        
                        bank_value <= (bank_value * 10) + stack[calc_idx];
                        calc_idx   <= calc_idx + 1;
                    end
                end


                S_ADD_TOTAL: begin
                    total_joltage <= total_joltage + bank_value;
                    

                    write_ptr     <= 10'd0;
                    state         <= S_READ;
                end
            endcase
        end
    end

endmodule
