# Controle de Acesso Óptico
### Kaio Henrique de Menezes Borduque

## Visão Geral

Este projeto implementa um sistema de segurança de duplo estágio para um ambiente seguro (como uma sala-cofre), utilizando uma FPGA Lattice ECP5-45F na placa Colorlight i9. O sistema utiliza um sensor de luz como gatilho principal, acionando uma trava secundária e um alerta visual via HDMI, com anulação por senha por meio de um teclado matricial.

O projeto foi desenvolvido em Verilog e sintetizado utilizando a toolchain de código aberto (Yosys, nextpnr, ecppack).

## Conceito de Operação

O sistema foi projetado para proteger um ambiente que deve permanecer escuro, como uma sala-cofre. A lógica de segurança funciona em duas etapas:

Gatilho de Violação (Porta da Sala): A primeira barreira de segurança é a porta da sala. Se esta for violada, a luz do ambiente externo entra na sala escura. O sensor de luz BH1750 detecta essa mudança brusca de luminosidade, atuando como um gatilho da invasão.

Contenção Ativa (Trava do Cofre): No instante em que a luz é detectada, o sistema entra em modo de alerta. Um servo motor, atuando como uma trava de emergência, é imediatamente acionado para bloquear o cofre principal que está dentro da sala. Simultaneamente, a saída de vídeo HDMI muda do status normal (tela verde) para um status de alerta (tela vermelha), notificando uma central de segurança.

Anulação por Senha: Uma vez em estado de alerta, o sistema só pode ser desarmado através de uma senha de 4 dígitos inserida em um teclado matricial 4x4. Após a senha correta, a trava é liberada, o alerta visual é desativado e o sistema entra em um timeout de 1 minuto antes de ser rearmado.

## Fluxo da Máquina de Estados

O controle central é realizado por uma máquina de três estados principais no módulo top.v:

S_MONITORANDO: Estado inicial e de repouso. O servo está destravado e a tela HDMI exibe a cor verde. O sistema monitora continuamente o sensor de luz.

S_ALERTA_SENHA: Acionado quando a luz ultrapassa um limiar. O servo é liberado (simulando o travamento do cofre), a tela HDMI muda para vermelho (alerta), e o sistema aguarda a inserção da senha.

S_TRAVADO_ESPERA: Acionado após a senha correta ser inserida. O servo volta a destravar, a tela HDMI volta para verde, e um contador de 1 minuto é iniciado antes de retornar ao estado S_MONITORANDO.

## Componentes de Hardware

FPGA: Lattice ECP5-45F (Placa Colorlight i9)

Sensor de Luz: Módulo BH1750 (Comunicação I²C)

Atuador: Servo Motor SG90 (Controle por PWM)

Entrada de Usuário: Teclado Matricial 4x4

Saída de Vídeo: Conexão HDMI


## Estrutura do Projeto e Módulos

O projeto é modular, com cada componente principal encapsulado em seu próprio arquivo Verilog.

top.v: O módulo principal que contém a máquina de estados e integra todos os outros componentes.

bh1750_i2c.v e i2c.v: Controlam a comunicação I²C e a leitura de dados do sensor de luz.

keypad_scanner.v: Realiza a varredura do teclado matricial 4x4 e decodifica a tecla pressionada.

servo_pwm.v: Gera o sinal PWM necessário para controlar a posição do servo motor com base em um sinal de "travar/destravar".

Módulos HDMI (Referência Externa):

ULX3S_25F.v: Módulo de alto nível que integra o gerador de imagem e o controlador HDMI.

vgatestsrc.v: Gera a imagem (neste caso, uma cor sólida controlada externamente).

clock.v, llhdmi.v, TMDS_encoder.v, OBUFDS.v: Módulos de baixo nível que geram os clocks e os sinais diferenciais TMDS para a saída HDMI.

## Resumo do Desenvolvimento e Limitações

A ideia inicial do projeto era criar uma "Proteção de Perímetro" usando um sensor de distância a laser. No entanto, durante os testes, tive algumas dificuldades para fazer esse sensor específico funcionar com a placa FPGA e percebi que levaria muito tempo para conseguir resolver todos os problemas.

Por causa disso, para garantir a entrega do projeto, decidi adaptar a ideia. Mudei o foco para o "Controle de Acesso Óptico", que manteve a essência de um sistema de segurança. Apenas troquei o sensor de distância por um sensor de luz (BH1750), que se encaixou muito bem no cenário de um cofre que, ao ser aberto, deixa a luz entrar.

Outro ponto foi a lógica da senha. A ideia era fazer algo mais complexo, como bloquear o sistema depois de vários erros, mas o teclado que eu usei estava com algumas teclas falhando. Para garantir que o projeto funcionasse de forma estável, optei por uma lógica mais simples, com um "buffer deslizante", que funcionou bem com as teclas que estavam operando corretamente.

## Pinagem do projeto

LOCATE COMP "sys_clk" SITE "P3";   IOBUF PORT "sys_clk" IO_TYPE=LVCMOS33;
LOCATE COMP "SDA" SITE "G3";       IOBUF PORT "SDA" IO_TYPE=LVCMOS33;
LOCATE COMP "SCL" SITE "F3";       IOBUF PORT "SCL" IO_TYPE=LVCMOS33;
LOCATE COMP "led_o" SITE "L2";     IOBUF PORT "led_o" IO_TYPE=LVCMOS33;
LOCATE COMP "servo_o" SITE "K3"; IOBUF PORT "servo_o" IO_TYPE=LVCMOS33;
#Linhas
LOCATE COMP "keypad_rows_o[0]" SITE "N3"; IOBUF PORT "keypad_rows_o[0]" IO_TYPE=LVCMOS33; // Linha 1
LOCATE COMP "keypad_rows_o[1]" SITE "M1"; IOBUF PORT "keypad_rows_o[1]" IO_TYPE=LVCMOS33; // Linha 2
LOCATE COMP "keypad_rows_o[2]" SITE "N2"; IOBUF PORT "keypad_rows_o[2]" IO_TYPE=LVCMOS33; // Linha 3
LOCATE COMP "keypad_rows_o[3]" SITE "T3"; IOBUF PORT "keypad_rows_o[3]" IO_TYPE=LVCMOS33; // Linha 4
#Colunas
LOCATE COMP "keypad_cols_i[0]" SITE "T2"; IOBUF PORT "keypad_cols_i[0]" IO_TYPE=LVCMOS33 PULLMODE=UP; // Coluna 1
LOCATE COMP "keypad_cols_i[1]" SITE "N4"; IOBUF PORT "keypad_cols_i[1]" IO_TYPE=LVCMOS33 PULLMODE=UP; // Coluna 2
LOCATE COMP "keypad_cols_i[2]" SITE "M4"; IOBUF PORT "keypad_cols_i[2]" IO_TYPE=LVCMOS33 PULLMODE=UP; // Coluna 3
LOCATE COMP "keypad_cols_i[3]" SITE "M3"; IOBUF PORT "keypad_cols_i[3]" IO_TYPE=LVCMOS33 PULLMODE=UP; // Coluna 4
#HDMI
LOCATE COMP "gpdi_dp[0]" SITE "G19"; # Blue +
LOCATE COMP "gpdi_dn[0]" SITE "H20"; # Blue -
LOCATE COMP "gpdi_dp[1]" SITE "E20"; # Green +
LOCATE COMP "gpdi_dn[1]" SITE "F19"; # Green -
LOCATE COMP "gpdi_dp[2]" SITE "C20"; # Red +
LOCATE COMP "gpdi_dn[2]" SITE "D19"; # Red -
LOCATE COMP "gpdi_dp[3]" SITE "J19"; # Clock +
LOCATE COMP "gpdi_dn[3]" SITE "K19"; # Clock -
IOBUF PORT "gpdi_dp[0]" IO_TYPE=LVCMOS33 DRIVE=4;
IOBUF PORT "gpdi_dn[0]" IO_TYPE=LVCMOS33 DRIVE=4;
IOBUF PORT "gpdi_dp[1]" IO_TYPE=LVCMOS33 DRIVE=4;
IOBUF PORT "gpdi_dn[1]" IO_TYPE=LVCMOS33 DRIVE=4;
IOBUF PORT "gpdi_dp[2]" IO_TYPE=LVCMOS33 DRIVE=4;
IOBUF PORT "gpdi_dn[2]" IO_TYPE=LVCMOS33 DRIVE=4;
IOBUF PORT "gpdi_dp[3]" IO_TYPE=LVCMOS33 DRIVE=4;
IOBUF PORT "gpdi_dn[3]" IO_TYPE=LVCMOS33 DRIVE=4;

## Como Compilar e Gravar

O projeto utiliza o Makefile para automatizar o fluxo de compilação com a toolchain de código aberto.

Pré-requisitos: Ter Yosys, nextpnr-ecp5, ecppack e openFPGALoader instalados.

Compilar o Projeto:

Bash

make
Gravar na Placa:

Bash

make prog
Limpar Arquivos Gerados:

Bash


make clean
