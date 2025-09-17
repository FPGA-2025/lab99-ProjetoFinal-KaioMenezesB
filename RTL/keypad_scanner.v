// Módulo: keypad_scanner
module keypad_scanner (
    input  wire clk_i,
    input  wire rst_i,
    output reg  [3:0] keypad_rows_o,
    input  wire [3:0] keypad_cols_i,
    output reg [3:0] key_code_o,
    output reg       key_pressed_o
);
    localparam integer SCAN_TIME_COUNT = 31250;
    reg [14:0] scanner_counter;
    reg [1:0]  row_scanner;
    reg [3:0]  key_code_prev;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            scanner_counter <= 0;
            row_scanner <= 0;
        end else if (scanner_counter < SCAN_TIME_COUNT - 1) begin
            scanner_counter <= scanner_counter + 1;
        end else begin
            scanner_counter <= 0;
            row_scanner <= (row_scanner == 3) ? 0 : row_scanner + 1;
        end
    end

    always @(*) begin
        case (row_scanner)
            2'b00:   keypad_rows_o = 4'b1110;
            2'b01:   keypad_rows_o = 4'b1101;
            2'b10:   keypad_rows_o = 4'b1011;
            2'b11:   keypad_rows_o = 4'b0111;
            default: keypad_rows_o = 4'b1111;
        endcase
    end

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            key_code_o <= 4'hF;
        end else begin
            case (row_scanner)
                2'b00: case (~keypad_cols_i) 4'b0001: key_code_o <= 4'h1; 4'b0010: key_code_o <= 4'h2; 4'b0100: key_code_o <= 4'h3; 4'b1000: key_code_o <= 4'hA; default: key_code_o <= 4'hF; endcase
                2'b01: case (~keypad_cols_i) 4'b0001: key_code_o <= 4'h4; 4'b0010: key_code_o <= 4'h5; 4'b0100: key_code_o <= 4'h6; 4'b1000: key_code_o <= 4'hB; default: key_code_o <= 4'hF; endcase
                2'b10: case (~keypad_cols_i) 4'b0001: key_code_o <= 4'h7; 4'b0010: key_code_o <= 4'h8; 4'b0100: key_code_o <= 4'h9; 4'b1000: key_code_o <= 4'hC; default: key_code_o <= 4'hF; endcase
                2'b11: case (~keypad_cols_i) 4'b0001: key_code_o <= 4'hE; 4'b0010: key_code_o <= 4'h0; 4'b0100: key_code_o <= 4'hD; 4'b1000: key_code_o <= 4'hF; default: key_code_o <= 4'hF; endcase
                default: key_code_o <= 4'hF;
            endcase
        end
    end
    
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            key_pressed_o <= 1'b0;
            key_code_prev <= 4'hF;
        end else begin
            key_code_prev <= key_code_o;
            if (key_code_o != 4'hF && key_code_prev == 4'hF) begin
                key_pressed_o <= 1'b1;
            end else begin
                key_pressed_o <= 1'b0;
            end
        end
    end
endmodule