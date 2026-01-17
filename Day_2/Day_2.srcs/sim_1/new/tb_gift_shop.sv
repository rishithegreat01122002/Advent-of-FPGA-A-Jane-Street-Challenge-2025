`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/15/2026 01:04:53 PM
// Design Name: 
// Module Name: tb_gift_shop
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
module tb_gift_shop;

    localparam int MAX_DIGITS = 20; 
    parameter string INPUT_FILE_PATH = "/home/rishi/jane_street_challenge/Day_2/Day_2.srcs/sim_1/new/input.txt";

    logic clk;
    logic rst_n;
    logic [7:0] s_axis_tdata;
    logic s_axis_tvalid;
    logic s_axis_tready;
    logic s_axis_tlast;
    
    logic [63:0] total_sum;
    logic result_valid;

    integer fd, char_in, code;
    logic loop_active;

    gift_shop_solver #(.MAX_DIGITS(MAX_DIGITS)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .total_sum(total_sum),
        .result_valid(result_valid)
    );

    initial clk = 0;
    always #5 clk = ~clk; 

    initial begin
        rst_n = 0;
        s_axis_tvalid = 0;
        s_axis_tdata = 0;
        s_axis_tlast = 0;
        loop_active = 0;
        
        #100;
        rst_n = 1;
        #20;

        fd = $fopen(INPUT_FILE_PATH, "r");
        if (fd == 0) begin
            $display("ERROR: Could not open file at %s", INPUT_FILE_PATH);
            $finish;
        end

        $display("Starting Simulation...");
        
        char_in = $fgetc(fd);
        if (char_in != -1) loop_active = 1;

        while (loop_active) begin
            while (!s_axis_tready) @(posedge clk);
            
            s_axis_tdata  <= char_in[7:0];
            s_axis_tvalid <= 1'b1;
            
            code = $fgetc(fd); 
            if (code == -1) begin
                s_axis_tlast <= 1'b1;
            end else begin
                code = $ungetc(code, fd);
            end

            @(posedge clk);
            
            if (s_axis_tlast) begin
                s_axis_tvalid <= 0;
                s_axis_tlast  <= 0;
                loop_active = 0;
            end else begin
                while (!s_axis_tready) @(posedge clk);
                char_in = $fgetc(fd);
                if (char_in == -1) loop_active = 0;
            end
        end

        s_axis_tvalid <= 0;
        $fclose(fd);

        fork : wait_block
            begin
                wait(result_valid);
                disable timeout_block;
            end
            begin : timeout_block
                #100000000;
                $display("TIMEOUT");
                $finish;
            end
        join

        #50;
        $display("--------------------------------------------------");
        $display(" FINAL RESULT ");
        $display("--------------------------------------------------");
        $display("Total Sum of Invalid IDs: %0d", total_sum);
        $display("--------------------------------------------------");
        
        $finish;
    end

endmodule
