`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/17/2026 09:00:28 AM
// Design Name: 
// Module Name: cafeteria_engine_part2
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
package CafeteriaTypes_Part2;
    typedef struct packed {
        logic [63:0] start_addr;
        logic [63:0] end_addr;
        logic        valid;
    } range_t;
endpackage

import CafeteriaTypes_Part2::*;

module cafeteria_engine_part2 #(
    parameter MAX_RANGES = 200
)(
    input  logic clk,
    input  logic rst_n,
    input  logic start_calc,
    
    input  logic        cfg_write_en,
    input  range_t      cfg_range_data,
    input  logic [$clog2(MAX_RANGES)-1:0] cfg_addr,

    output logic [63:0] total_fresh_count,
    output logic        done
);

    range_t range_db [MAX_RANGES-1:0];
    logic [$clog2(MAX_RANGES):0] num_ranges;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            num_ranges <= 0;
            for (int k = 0; k < MAX_RANGES; k++) begin
                range_db[k] <= '0; // Initialize everything to invalid/zero
            end
        end else if (cfg_write_en && cfg_range_data.valid) begin
            range_db[cfg_addr] <= cfg_range_data;
            if ((cfg_addr + 1) > num_ranges) num_ranges <= cfg_addr + 1;
        end
    end

    typedef enum logic [1:0] {IDLE, SORT, MERGE, FINISH} state_t;
    state_t state;
    
    logic [63:0] acc;
    logic [63:0] cur_start, cur_end;
    logic [$clog2(MAX_RANGES):0] i, j;

    

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            total_fresh_count <= 0;
            done <= 0;
            acc <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start_calc && num_ranges > 0) begin
                        state <= SORT;
                        i <= 0;
                        j <= 0;
                    end
                end

                SORT: begin
                    if (i < num_ranges - 1) begin
                        if (j < num_ranges - i - 1) begin
                            if (range_db[j].start_addr > range_db[j+1].start_addr) begin
                                range_db[j]   <= range_db[j+1];
                                range_db[j+1] <= range_db[j];
                            end
                            j <= j + 1;
                        end else begin
                            j <= 0;
                            i <= i + 1;
                        end
                    end else begin
                        state <= MERGE;
                        i <= 1; 
                        cur_start <= range_db[0].start_addr;
                        cur_end   <= range_db[0].end_addr;
                        acc <= 0;
                    end
                end

                MERGE: begin
                    if (i < num_ranges) begin
                        if (range_db[i].start_addr <= (cur_end + 1)) begin
                            if (range_db[i].end_addr > cur_end) begin
                                cur_end <= range_db[i].end_addr;
                            end
                        end else begin
                            acc <= acc + (cur_end - cur_start + 1);
                            cur_start <= range_db[i].start_addr;
                            cur_end   <= range_db[i].end_addr;
                        end
                        i <= i + 1;
                    end else begin
                        total_fresh_count <= acc + (cur_end - cur_start + 1);
                        state <= FINISH;
                    end
                end

                FINISH: begin
                    done <= 1;
                    if (!start_calc) state <= IDLE;
                end
            endcase
        end
    end
endmodule
