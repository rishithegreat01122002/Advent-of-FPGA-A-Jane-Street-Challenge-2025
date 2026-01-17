`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/10/2026 04:37:51 PM
// Design Name: 
// Module Name: tb_battery
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

`timescale 1ns / 1ps

module tb_battery;

    reg clk;
    reg rst_n;
    reg [7:0] s_axis_tdata;
    reg s_axis_tvalid;
    reg s_axis_tlast;
    wire s_axis_tready;
    wire [31:0] total_joltage;

    battery_joltage uut (
        .clk(clk),
        .rst_n(rst_n),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tready(s_axis_tready),
        .total_joltage(total_joltage)
    );

    always #5 clk = ~clk;

    integer file_handle;
    integer char_in;
    reg [7:0] line_buffer [0:2047]; // Memory to hold digits of one line
    integer digit_count;            // How many digits in current line
    integer i;

    initial begin
        clk = 0;
        rst_n = 0;
        s_axis_tdata = 0;
        s_axis_tvalid = 0;
        s_axis_tlast = 0;

        file_handle = $fopen("/home/rishi/jane_street_challenge/Day_3/Day_3.srcs/sim_1/new/input.txt", "r");
        
        if (file_handle == 0) begin
            $display("ERROR: Could not open input.txt");
            $stop;
        end

        #100;
        rst_n = 1;
        #20;

        $display("Starting Robust Processing...");

        while (!$feof(file_handle)) begin
            
            digit_count = 0;
            char_in = $fgetc(file_handle);

            while (char_in != 8'h0A && char_in != -1) begin
                if (char_in >= "0" && char_in <= "9") begin
                    line_buffer[digit_count] = char_in;
                    digit_count = digit_count + 1;
                end
                
                char_in = $fgetc(file_handle);
            end

            if (digit_count > 0) begin
                for (i = 0; i < digit_count; i = i + 1) begin
                    @(posedge clk);
                    s_axis_tdata  <= line_buffer[i];
                    s_axis_tvalid <= 1;
                    
                    if (i == digit_count - 1) begin
                        s_axis_tlast <= 1;
                    end else begin
                        s_axis_tlast <= 0;
                    end
                end
                
                @(posedge clk);
                s_axis_tvalid <= 0;
                s_axis_tlast  <= 0;
                #20; // Small gap between banks
            end
        end

        $fclose(file_handle);
        #500; // Wait for final logic to settle
        $display("-------------------------------------------");
        $display("FINAL TOTAL JOLTAGE: %d", total_joltage);
        $display("-------------------------------------------");
        $stop;
    end

endmodule
