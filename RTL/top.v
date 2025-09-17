module top(
    input  wire sys_clk, 
    inout  wire SDA,
    inout  wire SCL,
    output wire servo_o,
    output wire [3:0] keypad_rows_o,
    input  wire [3:0] keypad_cols_i,
    output [3:0] gpdi_dp, gpdi_dn,
    output wire led_o
);

    //Reset Inicial
    reg [7:0] reset_counter = 8'hFF;
    wire reset_n;
    // O reset deve ser rápido, então usei o clock principal de 25MHz aqui
    always @(posedge sys_clk) reset_counter <= (reset_counter == 8'h00) ? 8'h00 : reset_counter - 1;
    assign reset_n = (reset_counter == 8'h00);
    
    //Definições dos estados principais
    localparam [1:0] S_MONITORANDO = 2'b00,
                     S_ALERTA_SENHA = 2'b01,
                     S_TRAVADO_ESPERA   = 2'b10;
    reg [1:0] current_state;

    //Sinais dos módulos
    wire [15:0] lux_value_from_sensor;
    wire        data_ready_pulse;
    wire [3:0]  key_code;
    wire        key_pressed;
    reg         lock_state = 1'b1;
    reg screen_color_alert = 1'b0;

    bh1750_i2c bh1750_inst (
        .i_clk(sys_clk), .i_rst(reset_n), .io_scl(SCL), .io_sda(SDA),
        .o_data(lux_value_from_sensor), .o_tick_done(data_ready_pulse)
    );

    keypad_scanner scanner_inst (
        .clk_i(sys_clk), .rst_i(~reset_n),
        .keypad_rows_o(keypad_rows_o), .keypad_cols_i(keypad_cols_i),
        .key_code_o(key_code), .key_pressed_o(key_pressed)
    );

    servo_pwm #( .CLK_HZ(25_000_000) ) servo_inst (
        .clk(sys_clk), .rst_n(reset_n),
        .lock(lock_state),
        .servo_out(servo_o)
    );

    ULX3S_25F u_ULX3S_25F (
    .clk_25mhz            (sys_clk),
    .gpdi_dp              (gpdi_dp),
    .gpdi_dn               (gpdi_dn),                       
    .wifi_gpio0           (),
    .color_select          (screen_color_alert)
    );
    //  LÓGICA PRINCIPAL
    localparam LUX_THRESHOLD = 16'd30; // Limiar de luminosidade

    localparam [30:0] TEMPO_ESPERA = 25_000_000 * 60; // tempo para voltar a monitorar

    reg [15:0] last_valid_lux;
    reg [30:0] timeout_counter;

    always @(posedge sys_clk) begin
        if (data_ready_pulse) last_valid_lux <= lux_value_from_sensor;
    end

    // LOGICA DA SENHA
    parameter [7:0] PASSWORD = 8'h251C; // Senha "251C"
    reg [7:0] password_buffer = 8'hFF;
    
    // Máquina de estados principal
    always @(posedge sys_clk) begin
        if (!reset_n) begin // Condição de Reset
            current_state      <= S_MONITORANDO
    ;
            lock_state         <= 1'b1;
            password_buffer    <= 8'hFF;
            timeout_counter    <= 31'd0;
            screen_color_alert <= 1'b0; // Tela começa VERDE
        end else begin
            case (current_state)
                S_MONITORANDO
        : begin
                    lock_state         <= 1'b0;
                    screen_color_alert <= 1'b0; // Tela permanece VERDE
                    if (last_valid_lux > LUX_THRESHOLD) begin
                        current_state <= S_ALERTA_SENHA;
                    end
                end

                S_ALERTA_SENHA: begin
                    lock_state         <= 1'b1;
                    screen_color_alert <= 1'b1; // Tela de alerta VERMELHA
                    // Lógica da senha
                    if (key_pressed && key_code != 4'hF) begin
                        password_buffer <= {password_buffer[3:0], key_code};
                    end
                    
                    if (password_buffer == PASSWORD) begin
                        current_state   <= S_TRAVADO_ESPERA;
                        timeout_counter <= 31'd0;
                        password_buffer <= 8'hFF; // Limpa o buffer para a próxima vez
                    end
                end

                S_TRAVADO_ESPERA: begin
                    lock_state         <= 1'b0;
                    screen_color_alert <= 1'b0; // Tela volta a ser VERDE
                    if (timeout_counter < TEMPO_ESPERA - 1) begin
                        timeout_counter <= timeout_counter + 1;
                    end else begin
                        current_state <= S_MONITORANDO
                ;
                    end
                end
            endcase
        end
    end
    
    assign led_o = ~lock_state; // LED acende quando destravado

endmodule