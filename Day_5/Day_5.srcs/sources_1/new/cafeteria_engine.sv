`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/15/2026 03:28:30 PM
// Design Name: 
// Module Name: cafeteria_engine
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
package CafeteriaTypes;
    typedef struct packed {
        logic [63:0] start_addr;
        logic [63:0] end_addr;
        logic        valid;
    } range_t;
endpackage

import CafeteriaTypes::*;

module cafeteria_engine #(
    parameter MAX_RANGES = 128,     
    parameter RANGES_PER_STAGE = 4  
)(
    input  logic clk,
    input  logic rst_n,
    
    input  logic        cfg_write_en,
    input  range_t      cfg_range_data,
    input  logic [$clog2(MAX_RANGES)-1:0] cfg_addr,

    input  logic        id_valid_in,
    input  logic [63:0] id_in,
    
    output logic        match_valid_out,
    output logic        is_fresh_out
);

    range_t range_db [MAX_RANGES-1:0];

    always_ff @(posedge clk) begin
        if (cfg_write_en) range_db[cfg_addr] <= cfg_range_data;
    end

    localparam NUM_STAGES = (MAX_RANGES + RANGES_PER_STAGE - 1) / RANGES_PER_STAGE;

    logic [63:0] pipe_id    [NUM_STAGES:0];
    logic        pipe_valid [NUM_STAGES:0];
    logic        pipe_match [NUM_STAGES:0];

    assign pipe_id[0]    = id_in;
    assign pipe_valid[0] = id_valid_in;
    assign pipe_match[0] = 1'b0;

    genvar s;
    generate
        for (s = 0; s < NUM_STAGES; s++) begin : STAGE_GEN
            logic stage_hit;
            
            always_comb begin
                stage_hit = 1'b0;
                for (int i = 0; i < RANGES_PER_STAGE; i++) begin
                    int idx = s * RANGES_PER_STAGE + i;
                    if (idx < MAX_RANGES) begin
                        if (range_db[idx].valid && 
                           (pipe_id[s] >= range_db[idx].start_addr) && 
                           (pipe_id[s] <= range_db[idx].end_addr)) begin
                            stage_hit = 1'b1;
                        end
                    end
                end
            end

            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    pipe_valid[s+1] <= 1'b0;
                    pipe_match[s+1] <= 1'b0;
                end else begin
                    pipe_valid[s+1] <= pipe_valid[s];
                    pipe_id[s+1]    <= pipe_id[s];
                    pipe_match[s+1] <= pipe_match[s] | stage_hit;
                end
            end
        end
    endgenerate

    assign match_valid_out = pipe_valid[NUM_STAGES];
    assign is_fresh_out    = pipe_match[NUM_STAGES];

endmodule
