`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/15/2026 03:29:27 PM
// Design Name: 
// Module Name: tb_cafeteria
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
import CafeteriaTypes::*;

module tb_cafeteria;
    parameter MAX_RANGES = 200; 
    parameter CLK_PERIOD = 10;
    
    logic clk = 0, rst_n = 0, cfg_write_en = 0, id_valid_in = 0;
    range_t cfg_range_data;
    logic [$clog2(MAX_RANGES)-1:0] cfg_addr = 0;
    logic [63:0] id_in; 
    logic match_valid_out, is_fresh_out;

    integer total_fresh = 0;
    integer total_checked = 0;
    integer fd;
    string line;
    longint val1, val2;
    bit loading_ranges = 1;

    cafeteria_engine #(.MAX_RANGES(MAX_RANGES), .RANGES_PER_STAGE(8)) dut (.*);

    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        rst_n = 0; #(CLK_PERIOD*5); rst_n = 1;
        
        fd = $fopen("/home/rishi/jane_street_challenge/Day_5/Day_5.srcs/sim_1/new/input.txt", "r");
        
        if (fd == 0) begin
            $display("FATAL ERROR: File not found at path. Please verify the file exists.");
            $finish;
        end


        while (!$feof(fd)) begin
            void'($fgets(line, fd)); 
            
            // Check for blank line or end of ranges
            if (line.len() <= 1 || line == "\n" || line == "\r\n") begin
                if (loading_ranges && cfg_addr > 0) begin
                    loading_ranges = 0;
                end
                continue;
            end

            if (loading_ranges) begin
                // Use %d for 64-bit compatibility
                if ($sscanf(line, "%d-%d", val1, val2) == 2) begin
                    @(posedge clk);
                    cfg_write_en <= 1;
                    cfg_range_data.start_addr <= val1;
                    cfg_range_data.end_addr   <= val2;
                    cfg_range_data.valid      <= 1'b1;
                    cfg_addr <= cfg_addr + 1;
                end
            end else begin
                if ($sscanf(line, "%d", val1) == 1) begin
                    @(posedge clk);
                    cfg_write_en <= 0;
                    id_valid_in  <= 1;
                    id_in        <= val1;
                end
            end
        end

        $fclose(fd);
        @(posedge clk); id_valid_in <= 0;
        repeat(50) @(posedge clk); 

        $display("==================================================");
        $display("FINAL RESULTS");
        $display("Total Fresh:   %0d", total_fresh);
        $display("==================================================");
        $finish;
    end

    always @(posedge clk) begin
        if (match_valid_out) begin
            total_checked++;
            if (is_fresh_out) total_fresh++;
        end
    end
endmodule
