# Origem e seleção

Inspeção somente leitura feita em 13 de setembro de 2026 pela API do GitHub,
pela árvore Git e pela leitura integral dos arquivos Pascal dos dois projetos.

| Evidência | Snake | Chess |
|---|---|---|
| Repositório | [coisa/pascal-snake](https://github.com/coisa/pascal-snake) | [coisa/pascal-chess](https://github.com/coisa/pascal-chess) |
| Ref inspecionada | `master` | `master` |
| Commit | `15477b37f4d26bc9571228086d40884991633efb` | `bec5c0cedae44637e2086ba9d6d52eb42a64b945` |
| Data do commit | 2024-01-06 | 2017-12-01 |
| Arquivos | 3 | 1 |
| Pascal | `SnakeGame.pas`, 4.107 bytes | `chess.pas`, 6.516 bytes |
| Outros arquivos | Dockerfile, docker-compose.yml | nenhum |
| Commits no histórico | 2 | 1 |
| Visibilidade | público | público |
| Arquivado na consulta | **não** | **sim** |

O pedido descrevia ambos como arquivados. A consulta atual retornou
`archived: false` para Snake; isso é uma diferença factual do baseline.
Nenhum estado remoto foi alterado para executar esta prova de conceito.
Nenhum dos dois possui arquivo de licença na árvore examinada; esta mudança
não escolhe uma licença pelo autor.

Snake é o candidato menor por volume de código e complexidade funcional.
Já possui movimento, alimento, crescimento e encerramento por colisão.
Chess ocupa menos arquivos, mas seu `move` transfere qualquer peça para qualquer
casa: não verifica turno, legalidade do movimento, caminho, xeque ou mate.
Seu loop principal não termina. Transformá-lo em uma referência de xadrez
ampliaria significativamente o exercício. Chess permanece somente inspecionado.

## O que o original ensina

[SnakeGame.pas no commit-base](https://github.com/coisa/pascal-snake/blob/15477b37f4d26bc9571228086d40884991633efb/SnakeGame.pas)
usa records, um array de segmentos, procedures, funções, condicionais e um
loop temporizado com Crt. Começa com cinco segmentos e usa WASD, paredes
fatais, crescimento de cinco posições por alimento e aceleração progressiva.
Esses elementos continuam reconhecíveis na implementação.

## Problemas demonstráveis pela leitura

- `size := size + 5` amplia o comprimento sem inicializar as novas posições.
- O array comporta 1.400 segmentos, mas a área útil original tem 3.696 células;
  não existe guarda para impedir a escrita além da capacidade.
- `PutFood` sorteia coordenadas sem verificar ocupação pelo corpo.
- `Randomize` é chamado dentro do loop, sem necessidade e sem replay por seed.
- A interface exige 79 colunas e 50 linhas, usa caracteres de página de código
  DOS e não oferece ajuda, pausa, reinício, saída explícita ou pontuação.
- Regras, renderização, entrada e tempo estão misturados; não há testes ou README.
- O Dockerfile usa `frolvlad/alpine-fpc` sem versão/digest e compila apenas o jogo.

São observações do código, não resultados de execução do original.
Os testes de compilação e da nova implementação são registrados separadamente
em [validation.md](validation.md).

## Mudanças deliberadas

O modo desta intervenção é **feature + bugfix**. Não se promete equivalência
visual ou temporal com o original: o tabuleiro passa a 30 × 14 células, o
crescimento de cinco segmentos é consumido gradualmente, os intervalos têm
limite jogável e aparecem placar, velocidades, pausa, reinício e vitória.
O objetivo é manter o exercício de Pascal compreensível e corrigir suas
fronteiras, sem adicionar servidor, gráficos externos, contas ou persistência.
