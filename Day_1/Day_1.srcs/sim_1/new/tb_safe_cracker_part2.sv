`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/15/2026 03:03:25 PM
// Design Name: 
// Module Name: tb_safe_cracker_part2
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
module tb_safe_cracker_part2;
    import safe_pkg_part2::*;

    logic clk = 0;
    logic rst_n = 0;
    cmd_t [BATCH_SIZE-1:0] cmd_in;
    logic valid_in;
    logic ready_out;
    logic [31:0] total_zeros;
    logic done;

    int fd;
    int scan_res;
    string line_str; // Helper string to read "R577"
    
    safe_cracker_part2 dut (.*);

    always #5 clk = ~clk;

    function void parse_token(input string s, output logic d, output logic [15:0] m);
        d = (s.getc(0) == "R") ? 1'b1 : 1'b0;
        m = s.substr(1, s.len()-1).atoi();
    endfunction

    initial begin
        $display("--- Starting Part 2 Simulation ---");
        
        fd = $fopen("/home/rishi/jane_street_challenge/Day_1/Day_1.srcs/sim_1/new/input.txt", "r");
        if (fd == 0) begin
            $fatal(1, "Error: Could not open input.txt");
        end

        rst_n = 0; 
        cmd_in = '0; 
        valid_in = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);
        
        while (!$feof(fd)) begin
            valid_in = 0;
            cmd_in = '0; 
            
            for (int i = 0; i < BATCH_SIZE; i++) begin
                scan_res = $fscanf(fd, "%s", line_str);
                
                if (scan_res == 1) begin
                    parse_token(line_str, cmd_in[i].direction, cmd_in[i].magnitude);
                    valid_in = 1;
                end else begin
                    cmd_in[i].magnitude = 0; 
                    cmd_in[i].direction = 1'b1;
                end
            end

            if (valid_in) begin
                @(posedge clk);
            end
        end

        valid_in = 0;
        repeat(10) @(posedge clk); 
        
        $display("----------------------------------------");
        $display("PART 2 PASSWORD: %0d", total_zeros);
        $display("----------------------------------------");
        
        $fclose(fd);
        $finish;
    end

endmodule
