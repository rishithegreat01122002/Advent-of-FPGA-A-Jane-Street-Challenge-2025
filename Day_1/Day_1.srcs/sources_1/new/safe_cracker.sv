`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/15/2026 01:56:43 PM
// Design Name: 
// Module Name: safe_cracker
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

package safe_pkg;
    localparam int BATCH_SIZE = 8;
    localparam int MODULUS = 100;
    
    typedef struct packed {
        logic [15:0] magnitude;
        logic        direction;
    } cmd_t;

    typedef struct packed {
        logic [7:0] offset;
        logic       valid;
    } norm_cmd_t;
endpackage

module safe_cracker 
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

    norm_cmd_t [BATCH_SIZE-1:0] batch_offsets;
    
    always_comb begin
        logic [15:0] raw_mod;
        logic [7:0]  safe_mod;

        foreach (cmd_in[i]) begin
            batch_offsets[i].valid = valid_in;
            
            raw_mod = cmd_in[i].magnitude % MODULUS;
            safe_mod = raw_mod[7:0]; // Safe to cast now

            if (cmd_in[i].direction == 1'b0) begin // Left
                batch_offsets[i].offset = (MODULUS - safe_mod) % MODULUS;
            end else begin // Right
                batch_offsets[i].offset = safe_mod;
            end
        end
    end
    logic [7:0] current_pos;
    logic [7:0] next_pos_candidates [BATCH_SIZE-1:0];
    logic [BATCH_SIZE-1:0] is_zero_match;
    logic [$clog2(BATCH_SIZE)+1:0] batch_zero_count;

    always_comb begin
        logic [15:0] accum; 
        accum = 0;
        
        for (int i = 0; i < BATCH_SIZE; i++) begin
            accum = accum + batch_offsets[i].offset;
            next_pos_candidates[i] = (current_pos + accum) % MODULUS;

            if (valid_in && next_pos_candidates[i] == 8'd0) begin
                is_zero_match[i] = 1'b1;
            end else begin
                is_zero_match[i] = 1'b0;
            end
        end
        batch_zero_count = $countones(is_zero_match);
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_pos <= 50;
            total_zeros <= 0;
            ready_out   <= 1'b1;
        end else begin
            if (valid_in) begin
                current_pos <= next_pos_candidates[BATCH_SIZE-1];
                total_zeros <= total_zeros + batch_zero_count;
            end
        end
    end
endmodule
