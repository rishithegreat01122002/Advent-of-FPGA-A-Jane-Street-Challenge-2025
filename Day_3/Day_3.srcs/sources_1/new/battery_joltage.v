`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/10/2026 04:37:12 PM
// Design Name: 
// Module Name: battery_joltage
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
module battery_joltage (
    input  wire        clk,
    input  wire        rst_n,         // Active Low Reset
    
    input  wire [7:0]  s_axis_tdata,  
    input  wire        s_axis_tvalid,
    input  wire        s_axis_tlast,
    output wire        s_axis_tready, 
    
    output reg [31:0]  total_joltage
);

    assign s_axis_tready = 1'b1;

    wire [3:0] digit_val;
    wire       is_valid_digit;
    
    assign is_valid_digit = (s_axis_tdata >= 8'h30) && (s_axis_tdata <= 8'h39);
    assign digit_val      = s_axis_tdata[3:0];

    reg [3:0]  max_digit_seen;    
    reg [6:0]  max_pair_seen;     
    reg        first_digit_found; 

    wire [6:0] calculated_pair;
    assign calculated_pair = (max_digit_seen * 10) + digit_val;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            total_joltage     <= 32'd0;
            max_digit_seen    <= 4'd0;
            max_pair_seen     <= 7'd0;
            first_digit_found <= 1'b0;
        end else begin
            if (s_axis_tvalid && is_valid_digit) begin
                
                if (first_digit_found) begin
                    if (calculated_pair > max_pair_seen) begin
                        max_pair_seen <= calculated_pair;
                    end
                end
                if (!first_digit_found) begin
                    max_digit_seen    <= digit_val;
                    first_digit_found <= 1'b1;
                end else if (digit_val > max_digit_seen) begin
                    max_digit_seen    <= digit_val;
                end
            end

            if (s_axis_tvalid && s_axis_tlast) begin
                
                if (is_valid_digit && first_digit_found && (calculated_pair > max_pair_seen)) begin
                    total_joltage <= total_joltage + calculated_pair;
                end else begin
                    total_joltage <= total_joltage + max_pair_seen;
                end
                
                max_digit_seen    <= 4'd0;
                max_pair_seen     <= 7'd0;
                first_digit_found <= 1'b0;
            end
        end
    end

endmodule
