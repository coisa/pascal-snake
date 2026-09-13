# Changelog

## Não publicado

### Adicionado

- Motor Pascal determinístico, testes de regras e smoke de terminal com PTY.
- Placar, recorde da sessão, três velocidades, setas, pausa, reinício e saída.
- Vitória ao preencher o tabuleiro, ajuda de CLI e seed decimal opcional.
- README, baseline comparativo, arquitetura, validação e plano anterior ao código.

### Alterado

- Tabuleiro de 30 × 14, células em duas colunas e painéis de estado em ASCII.
- Desenho incremental, preservando as células que não mudaram.
- Docker oficial Debian por digest, snapshot APT e Free Pascal 3.2.2 fixados.
- Imagem final sem compilador, usuário não root e execução local sem rede.

### Corrigido

- Crescimento inicializa cada segmento e respeita a capacidade do tabuleiro.
- Comida somente em célula livre, sem loop aleatório potencialmente infinito.
- Entrada aceita no máximo uma curva válida por tick.
- Colisão considera se a cauda vai sair ou permanecer durante o crescimento.
- Terminal pausa ao redimensionar e restaura cursor e teclado na saída.
