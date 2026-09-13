# AGENTS.md

## Purpose

Implementar o jogo em duas unidades Pascal pequenas e legíveis.

## Ownership

O motor governa as regras; o terminal governa apresentação, teclado e relógio.

## Local Contracts

- snake_engine não importa Crt, relógio, arquivos ou rede.
- Inicialize o estado pela API; o record público facilita o estudo e fixtures.
- Valide colisão antes de mover. Cresça somente inicializando um segmento.
- Comida ocupa uma célula livre; o tabuleiro cheio termina em vitória.
- O terminal usa o motor para todas as transições e guarda o recorde da sessão.
- Comentários em PT-BR; tipos e funções em inglês. Use arrays, records e
  procedures sem introduzir frameworks ou hierarquias de classes.

## Work Guidance

Ao alterar regras, atualize os testes Pascal e a explicação em docs.
Ao alterar entrada, renderização ou lifecycle, atualize o smoke PTY.

## Verification

Use make test e make smoke. Compile com verificações de faixa e overflow.

## Child DOX Index

- snake_engine.pas: estado e regras determinísticas.
- snake_terminal.pas: interação Crt, desenho incremental e lifecycle.
