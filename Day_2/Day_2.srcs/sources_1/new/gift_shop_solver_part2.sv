//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/15/2026 01:36:33 PM
// Design Name: 
// Module Name: gift_shop_solver_part2
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
`timescale 1ns / 1ps

module gift_shop_solver_part2 #(
    parameter int MAX_DIGITS = 20
)(
    input  wire        clk,
    input  wire        rst_n,
    
    input  wire [7:0]  s_axis_tdata,
    input  wire        s_axis_tvalid,
    output logic       s_axis_tready,
    input  wire        s_axis_tlast, 

    output logic [63:0] total_sum,
    output logic        result_valid
);

    localparam int BIN_WIDTH = (MAX_DIGITS * 4);
    localparam int LEN_WIDTH = $clog2(MAX_DIGITS + 1);

    typedef logic [MAX_DIGITS-1:0][3:0] bcd_vector_t;

    typedef enum logic [2:0] {
        IDLE,
        PARSE_START,
        PARSE_END,
        PROCESS_RANGE,
        DONE
    } state_t;

    state_t state;

    bcd_vector_t  start_bcd, curr_bcd, next_bcd_val;
    logic [BIN_WIDTH-1:0] start_bin, end_bin, curr_bin;
    logic [63:0]  accumulator;
    
    logic stream_finished;
    logic is_pattern_match;
    logic len_increase_carry;

    logic [LEN_WIDTH-1:0] current_len;
    logic [LEN_WIDTH-1:0] start_len;

    
    logic [MAX_DIGITS:0] match_by_len; 

    generate
        genvar L, k;
        
        for (L = 2; L <= MAX_DIGITS; L = L + 1) begin : gen_len_check
            
            wire [L/2 : 1] k_matches; 
            
            for (k = 1; k <= L/2; k = k + 1) begin : gen_pattern_check
                if (L % k == 0) begin
                    assign k_matches[k] = (curr_bcd[L-1 : k] == curr_bcd[L-1-k : 0]);
                end else begin
                    assign k_matches[k] = 1'b0;
                end
            end
            
            assign match_by_len[L] = |k_matches;
        end

        assign match_by_len[0] = 1'b0;
        assign match_by_len[1] = 1'b0;
    endgenerate

    always_comb begin
        if (current_len <= MAX_DIGITS) 
            is_pattern_match = match_by_len[current_len];
        else 
            is_pattern_match = 1'b0;
    end

    always_comb begin
        next_bcd_val = curr_bcd;
        begin
            automatic logic carry = 1'b1;
            for (int i = 0; i < MAX_DIGITS; i++) begin
                if (carry) begin
                    if (curr_bcd[i] == 4'd9) begin
                        next_bcd_val[i] = 4'd0;
                        carry = 1'b1; 
                    end else begin
                        next_bcd_val[i] = curr_bcd[i] + 4'd1;
                        carry = 1'b0; 
                    end
                end
            end
        end
    end

    assign len_increase_carry = (curr_bcd[current_len-1] == 4'd9) && 
                                (next_bcd_val[current_len-1] == 4'd0) && 
                                (current_len < MAX_DIGITS);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= IDLE;
            start_bcd       <= '0;
            start_bin       <= '0;
            end_bin         <= '0;
            curr_bcd        <= '0;
            curr_bin        <= '0;
            accumulator     <= '0;
            total_sum       <= '0;
            result_valid    <= 1'b0;
            stream_finished <= 1'b0;
            current_len     <= '0;
            start_len       <= '0;
        end else begin
            case (state)
                IDLE: begin
                    result_valid <= 1'b0;
                    start_bcd <= '0;
                    start_bin <= '0;
                    end_bin   <= '0;
                    start_len <= '0;
                    stream_finished <= 1'b0;

                    if (s_axis_tvalid && s_axis_tdata >= "0" && s_axis_tdata <= "9") begin
                        start_bin <= (BIN_WIDTH'(s_axis_tdata) - "0");
                        start_bcd[0] <= 4'(s_axis_tdata - "0");
                        start_len <= 1;
                        state <= PARSE_START;
                    end
                end

                PARSE_START: begin
                    if (s_axis_tvalid) begin
                        if (s_axis_tdata == "-") begin
                            state <= PARSE_END;
                            end_bin <= '0; 
                        end 
                        else if (s_axis_tdata >= "0" && s_axis_tdata <= "9") begin
                            start_bcd <= {start_bcd[MAX_DIGITS-2:0], 4'(s_axis_tdata - "0")};
                            start_bin <= (start_bin * 10) + (BIN_WIDTH'(s_axis_tdata) - "0");
                            start_len <= start_len + 1;
                        end
                    end
                end

                PARSE_END: begin
                    if (s_axis_tvalid) begin
                        if (s_axis_tdata == "," || s_axis_tdata == 8'h0A || s_axis_tdata == 8'h0D) begin
                            curr_bcd    <= start_bcd;
                            curr_bin    <= start_bin;
                            current_len <= start_len;
                            state       <= PROCESS_RANGE;
                            if (s_axis_tlast) stream_finished <= 1'b1;
                        end 
                        else if (s_axis_tdata >= "0" && s_axis_tdata <= "9") begin
                            end_bin <= (end_bin * 10) + (BIN_WIDTH'(s_axis_tdata) - "0");
                            
                            if (s_axis_tlast) begin
                                curr_bcd    <= start_bcd;
                                curr_bin    <= start_bin;
                                current_len <= start_len;
                                stream_finished <= 1'b1;
                                state       <= PROCESS_RANGE;
                            end
                        end
                    end
                end

                PROCESS_RANGE: begin
                    if (curr_bin <= end_bin) begin
                        if (is_pattern_match) begin
                            accumulator <= accumulator + curr_bin;
                        end
                        
                        curr_bcd <= next_bcd_val;
                        curr_bin <= curr_bin + 1'b1;
                        
                        if (len_increase_carry) begin
                            current_len <= current_len + 1'b1;
                        end
                    end else begin
                        start_bcd <= '0;
                        start_bin <= '0;
                        end_bin   <= '0;
                        start_len <= '0;
                        
                        if (stream_finished) state <= DONE;
                        else state <= PARSE_START;
                    end
                end

                DONE: begin
                    total_sum <= accumulator;
                    result_valid <= 1'b1;
                end
            endcase
        end
    end

    assign s_axis_tready = (state == IDLE || state == PARSE_START || state == PARSE_END);

endmodule
`default_nettype wire
