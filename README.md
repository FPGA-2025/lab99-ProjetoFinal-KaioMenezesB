Controle de Acesso Óptico com FPGA

Visão Geral

Este projeto implementa um sistema de segurança de duplo estágio para um ambiente seguro (como uma sala-cofre), utilizando uma FPGA Lattice ECP5-45F na placa Colorlight i9. O sistema utiliza um sensor de luz como gatilho principal, acionando uma trava secundária e um alerta visual via HDMI, com anulação por senha por meio de um teclado matricial.

O projeto foi desenvolvido em Verilog e sintetizado utilizando a toolchain de código aberto (Yosys, nextpnr, ecppack).

Conceito de Operação

O sistema foi projetado para proteger um ambiente que deve permanecer escuro, como uma sala-cofre. A lógica de segurança funciona em duas etapas:

Gatilho de Violação (Porta da Sala): A primeira barreira de segurança é a porta da sala. Se esta for violada, a luz do ambiente externo entra na sala escura. O sensor de luz BH1750 detecta essa mudança brusca de luminosidade, atuando como um gatilho da invasão.

Contenção Ativa (Trava do Cofre): No instante em que a luz é detectada, o sistema entra em modo de alerta. Um servo motor, atuando como uma trava de emergência, é imediatamente acionado para bloquear o cofre principal que está dentro da sala. Simultaneamente, a saída de vídeo HDMI muda do status normal (tela verde) para um status de alerta (tela vermelha), notificando uma central de segurança.

Anulação por Senha: Uma vez em estado de alerta, o sistema só pode ser desarmado através de uma senha de 4 dígitos inserida em um teclado matricial 4x4. Após a senha correta, a trava é liberada, o alerta visual é desativado e o sistema entra em um timeout de 1 minuto antes de ser rearmado.

Fluxo da Máquina de Estados

O controle central é realizado por uma máquina de três estados principais no módulo top.v:

S_MONITORANDO: Estado inicial e de repouso. O servo está destravado e a tela HDMI exibe a cor verde. O sistema monitora continuamente o sensor de luz.

S_ALERTA_SENHA: Acionado quando a luz ultrapassa um limiar. O servo é liberado (simulando o travamento do cofre), a tela HDMI muda para vermelho (alerta), e o sistema aguarda a inserção da senha.

S_TRAVADO_ESPERA: Acionado após a senha correta ser inserida. O servo volta a destravar, a tela HDMI volta para verde, e um contador de 1 minuto é iniciado antes de retornar ao estado S_MONITORANDO.

Componentes de Hardware

FPGA: Lattice ECP5-45F (Placa Colorlight i9)

Sensor de Luz: Módulo BH1750 (Comunicação I²C)

Atuador: Servo Motor SG90 (Controle por PWM)

Entrada de Usuário: Teclado Matricial 4x4

Saída de Vídeo: Conexão HDMI


Estrutura do Projeto e Módulos

O projeto é modular, com cada componente principal encapsulado em seu próprio arquivo Verilog.

top.v: O módulo principal que contém a máquina de estados e integra todos os outros componentes.

bh1750_i2c.v e i2c.v: Controlam a comunicação I²C e a leitura de dados do sensor de luz.

keypad_scanner.v: Realiza a varredura do teclado matricial 4x4 e decodifica a tecla pressionada.

servo_pwm.v: Gera o sinal PWM necessário para controlar a posição do servo motor com base em um sinal de "travar/destravar".

Módulos HDMI (Referência Externa):

ULX3S_25F.v: Módulo de alto nível que integra o gerador de imagem e o controlador HDMI.

vgatestsrc.v: Gera a imagem (neste caso, uma cor sólida controlada externamente).

clock.v, llhdmi.v, TMDS_encoder.v, OBUFDS.v: Módulos de baixo nível que geram os clocks e os sinais diferenciais TMDS para a saída HDMI.

Como Compilar e Gravar

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