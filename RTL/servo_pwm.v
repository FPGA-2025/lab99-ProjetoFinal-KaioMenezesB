module servo_pwm #(
    parameter CLK_HZ = 25_000_000
)(
    input  wire clk,
    input  wire rst_n,
    input  wire lock,      // 1 = tranca, 0 = destranca
    output reg  servo_out
);
    localparam integer PERIOD_TICKS = CLK_HZ / 50;
    localparam [7:0] ANGLE_UNLOCK = 8'd10;
    localparam [7:0] ANGLE_LOCK   = 8'd170;
    reg [7:0] angle;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) angle <= ANGLE_LOCK; // Começa trancado
        else        angle <= (lock ? ANGLE_LOCK : ANGLE_UNLOCK);
    end
    wire [31:0] min_ticks = CLK_HZ/1000;
    wire [31:0] max_ticks = (CLK_HZ/1000)*2;
    wire [31:0] pulse_ticks = min_ticks + ( (max_ticks - min_ticks) * angle ) / 180;
    reg [31:0] cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) {cnt, servo_out} <= 0;
        else begin
            if (cnt >= PERIOD_TICKS-1) cnt <= 0;
            else cnt <= cnt + 1;
            servo_out <= (cnt < pulse_ticks);
        end
    end
endmodule