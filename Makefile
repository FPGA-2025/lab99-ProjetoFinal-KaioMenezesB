# --- NOME DO PROJETO E DIRETÓRIOS ---
PROJ = top
BUILD_DIR = build
RTL_DIR = rtl
HDMI_DIR = $(RTL_DIR)/hdmi

# --- FERRAMENTAS ---
YOSYS     = yosys
NEXTPNR   = nextpnr-ecp5
ECPPACK   = ecppack
LOADER    = openFPGALoader

# --- ARQUIVOS FONTE VERILOG (COM OS NOVOS CAMINHOS) ---
VERILOG_SOURCES = \
	$(RTL_DIR)/top.v \
	$(RTL_DIR)/bh1750_i2c.v \
	$(RTL_DIR)/i2c.v \
	$(RTL_DIR)/keypad_scanner.v \
	$(RTL_DIR)/servo_pwm.v \
	$(HDMI_DIR)/ULX3S_25F.v \
	$(HDMI_DIR)/vgatestsrc.v \
	$(HDMI_DIR)/clock.v \
	$(HDMI_DIR)/llhdmi.v \
	$(HDMI_DIR)/TMDS_encoder.v \
	$(HDMI_DIR)/OBUFDS.v

# --- PARÂMETROS DA PLACA E FERRAMENTAS ---
NEXTPNR_ARGS = --45k --package CABGA381 --speed 6 --json $(BUILD_DIR)/$(PROJ).json --textcfg $(BUILD_DIR)/$(PROJ).config --lpf $(PROJ).lpf
LOADER_ARGS = -b colorlight-i9

# --- REGRAS DO MAKE ---
.PHONY: all prog clean

all: $(BUILD_DIR)/$(PROJ).bit

prog: $(BUILD_DIR)/$(PROJ).bit
	sudo $(LOADER) $(LOADER_ARGS) $(BUILD_DIR)/$(PROJ).bit

$(BUILD_DIR)/$(PROJ).bit: $(BUILD_DIR)/$(PROJ).config
	$(ECPPACK) $(BUILD_DIR)/$(PROJ).config $(BUILD_DIR)/$(PROJ).bit

$(BUILD_DIR)/$(PROJ).config: $(BUILD_DIR)/$(PROJ).json
	$(NEXTPNR) $(NEXTPNR_ARGS) --freq 25

$(BUILD_DIR)/$(PROJ).json: $(VERILOG_SOURCES)
	@mkdir -p $(BUILD_DIR)
	$(YOSYS) -p "synth_ecp5 -top $(PROJ) -json $(BUILD_DIR)/$(PROJ).json" $(VERILOG_SOURCES)

clean:
	rm -rf $(BUILD_DIR)