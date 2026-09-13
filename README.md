# Pascal Snake

Um exercício de Pascal com regras pequenas, interface de terminal e testes
reproduzíveis. A cobra continua sendo um array de records; o jogo inteiro
continua em Pascal.

Esta prova de conceito parte de
[coisa/pascal-snake](https://github.com/coisa/pascal-snake), commit
`15477b37f4d26bc9571228086d40884991633efb`.

## Jogar

Com Docker em execução e Make disponível:

```sh
make test
make play
```

O primeiro build baixa a imagem e os pacotes fixados no Dockerfile. Depois,
a partida usa a imagem local e não precisa de rede. Abra um terminal ANSI
com pelo menos **70 colunas × 24 linhas**; 80 × 24 já acomoda a interface.

| Tecla | Ação |
|---|---|
| 1 / 2 / 3 | Escolher Calmo / Normal / Turbo na tela inicial |
| Enter ou Space | Começar |
| WASD ou setas | Mover |
| P ou Space | Pausar / continuar |
| R | Voltar à tela inicial, preservando o recorde da sessão |
| Q, Esc ou Ctrl-C | Sair e restaurar o terminal |

`@@` é a cabeça, `oo` é o corpo e `<>` é o alimento. As formas também
identificam os elementos sem depender apenas das cores. Cada alimento vale
10 pontos e cinco segmentos: eles aparecem um por movimento, sem posições
não inicializadas. Parede e corpo encerram a partida. Preencher o tabuleiro
é uma vitória. Redimensionar durante uma partida a pausa; retome com P.

O recorde dura somente até fechar o programa. O jogo não grava arquivos.
Reiniciar reutiliza a seed da sessão, útil para estudar a mesma abertura.

Para uma abertura reproduzível ou para usar Compose:

```sh
make image
docker run --rm -it --network none --read-only --cap-drop ALL \
  --security-opt no-new-privileges pascal-snake:local --seed 42
docker compose run --rm --build snake_game
```

`docker compose up` não é o fluxo de teclado recomendado: use `run`, que
conecta o terminal interativo. A seed aceita apenas decimal entre 0 e
4.294.967.295. `--help` funciona também com saída redirecionada.

## Compilar e testar

| Comando | O que faz |
|---|---|
| `make test` | Compila o jogo, executa regras Pascal e smoke PTY em Docker |
| `make image` | Compila, executa testes Pascal e monta a imagem do jogo |
| `make play` | Constrói a imagem e abre uma partida |
| `make smoke` | Testa a imagem já construída por um PTY do host; requer Python 3 |
| `make local-build local-test local-smoke` | Usa FPC e Python 3 já instalados |

O fluxo verificado é **Docker Linux ARM64**. O Dockerfile seleciona a
arquitetura nativa pela imagem oficial multiarch; AMD64 ainda precisa de
validação em um host nativo ou com emulação habilitada. A alternativa local
usa unidades Unix (`BaseUnix` e `Termio`) e não foi validada como binário
nativo de macOS ou Windows. Nenhum compilador foi instalado globalmente
durante esta POC.

Os testes Pascal usam seed fixa e verificações do compilador para faixa,
overflow, I/O e assertions. O smoke usa apenas a biblioteca padrão Python
para operar PTYs; Python não implementa as regras nem participa da aplicação.
Saídas locais ficam em `build/`; fontes, cache, `.git` e arquivos pessoais
não entram acidentalmente no contexto Docker, que usa uma allowlist.

## Estudar o código

1. Comece em [SnakeGame.pas](SnakeGame.pas): argumentos e entrada da aplicação.
2. Leia [snake_engine.pas](src/snake_engine.pas): records, direção, passo,
   colisão, crescimento e seleção finita de comida.
3. Execute [test_snake_engine.pas](tests/test_snake_engine.pas) e observe os
   casos em que a cauda deixa de ser um obstáculo.
4. Leia [snake_terminal.pas](src/snake_terminal.pas): tradução do teclado em
   intenções, relógio e atualização das células que mudaram.

Experimentos pequenos: mudar o intervalo de uma velocidade, adicionar uma
regra de pontuação com teste ou comparar um RNG alternativo mantendo a seed.
Não é necessário introduzir classes, servidor ou bibliotecas gráficas para
entender essas mudanças.

O [plano](plans/2026-09-13-implementation.md) foi commitado antes do código.
Veja também o [baseline comparativo](docs/baseline.md), a
[arquitetura](docs/architecture.md) e a [validação executada](docs/validation.md).
O original permanece recuperável pelo Git; a modernização não cria cópias
paralelas nem escolhe uma licença pelo autor.
