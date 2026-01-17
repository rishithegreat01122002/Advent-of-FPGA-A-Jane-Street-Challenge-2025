`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/17/2026 09:00:53 AM
// Design Name: 
// Module Name: tb_cafeteria_part2
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
import CafeteriaTypes_Part2::*;

module tb_cafeteria_part2;
    parameter MAX_RANGES = 200;
    
    logic clk = 0, rst_n = 0, start_calc = 0, cfg_write_en = 0, done;
    range_t cfg_range_data = '0;
    logic [$clog2(MAX_RANGES)-1:0] cfg_addr = 0;
    logic [63:0] total_fresh_count;

    cafeteria_engine_part2 #(.MAX_RANGES(MAX_RANGES)) dut (.*);

    always #5 clk = ~clk;

    initial begin
        string line;
        longint v1, v2;
        integer fd;
        
        fd = $fopen("/home/rishi/jane_street_challenge/Day_5/Day_5.srcs/sim_1/new/input.txt", "r");
        if (fd == 0) begin
            $display("FATAL ERROR: Could not open input.txt");
            $finish;
        end

        rst_n = 0; #50; rst_n = 1; #50;

        $display("--- Loading Ranges ---");
        while (!$feof(fd)) begin
            void'($fgets(line, fd));
            if (line.len() <= 1 || line == "\n" || line == "\r\n") break;

            if ($sscanf(line, "%d-%d", v1, v2) == 2) begin
                @(posedge clk);
                cfg_write_en <= 1;
                cfg_range_data.start_addr <= v1;
                cfg_range_data.end_addr   <= v2;
                cfg_range_data.valid      <= 1'b1;
                cfg_addr <= cfg_addr + 1;
            end
        end
        $fclose(fd);

        @(posedge clk);
        cfg_write_en <= 0;
        start_calc <= 1;

        wait(done == 1);
        $display("==================================================");
        $display("PART 2 RESULT: Total Fresh IDs = %d", total_fresh_count);
        $display("==================================================");
        
        #(100);
        $finish;
    end
endmodule
