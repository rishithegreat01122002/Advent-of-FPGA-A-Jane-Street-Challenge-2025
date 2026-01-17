`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/15/2026 02:52:12 PM
// Design Name: 
// Module Name: safe_cracker_part2
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
`default_nettype none

package safe_pkg_part2;
    localparam int BATCH_SIZE = 8;
    localparam int MODULUS = 100;
    
    typedef struct packed {
        logic [15:0] magnitude; 
        logic        direction; // 0=L, 1=R
    } cmd_t;
endpackage

module safe_cracker_part2
    import safe_pkg::*;
(
    input  wire logic clk,
    input  wire logic rst_n,
    input  wire cmd_t [BATCH_SIZE-1:0] cmd_in,
    input  wire logic                  valid_in,
    output logic                       ready_out,
    output logic [31:0]                total_zeros,
    output logic                       done
);

    logic [7:0]  current_pos;
    logic [31:0] total_zeros_reg;

    logic [7:0]  step_rem     [BATCH_SIZE-1:0];
    logic [7:0]  step_offset  [BATCH_SIZE-1:0];
    logic [15:0] step_full_spins [BATCH_SIZE-1:0];
    logic [7:0]  start_pos_of_step [BATCH_SIZE-1:0];
    logic        step_crosses_zero [BATCH_SIZE-1:0];
    
    logic [31:0] batch_full_spins_sum;

    always_comb begin
        logic [15:0] running_offset_accum;
        
        running_offset_accum = 0;
        batch_full_spins_sum = 0;

        foreach (cmd_in[i]) begin
            step_full_spins[i] = cmd_in[i].magnitude / MODULUS;
            step_rem[i] = cmd_in[i].magnitude % MODULUS;
            
            if (cmd_in[i].direction == 1'b0) // Left
                step_offset[i] = (MODULUS - step_rem[i]) % MODULUS;
            else // Right
                step_offset[i] = step_rem[i];
        end

        for (int i = 0; i < BATCH_SIZE; i++) begin
            start_pos_of_step[i] = (current_pos + running_offset_accum) % MODULUS;
            running_offset_accum = running_offset_accum + step_offset[i];
        end

        for (int i = 0; i < BATCH_SIZE; i++) begin
            step_crosses_zero[i] = 1'b0;
            if (valid_in) begin
                if (cmd_in[i].direction == 1'b1) begin // Right
                    if ((start_pos_of_step[i] + step_rem[i]) >= MODULUS)
                        step_crosses_zero[i] = 1'b1;
                end else begin // Left
                    if (start_pos_of_step[i] > 0 && step_rem[i] >= start_pos_of_step[i])
                        step_crosses_zero[i] = 1'b1;
                end
            end
        end

        for (int k = 0; k < BATCH_SIZE; k++) begin
            batch_full_spins_sum = batch_full_spins_sum + step_full_spins[k];
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_pos <= 50;
            total_zeros_reg <= 0;
            ready_out <= 1;
        end else begin
            if (valid_in) begin
                current_pos <= (start_pos_of_step[BATCH_SIZE-1] + step_offset[BATCH_SIZE-1]) % MODULUS;
                total_zeros_reg <= total_zeros_reg + batch_full_spins_sum + $countones(step_crosses_zero);
            end
        end
    end
    
    assign total_zeros = total_zeros_reg;
    assign done = 0;

endmodule
