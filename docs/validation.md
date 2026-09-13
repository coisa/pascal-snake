# Evidência de validação

Execução local em 13 de setembro de 2026. Host macOS com Docker/OrbStack
29.4.0; containers **Linux ARM64**, Free Pascal **3.2.2+dfsg-20**.

## Baseline

O checkout original estava em `15477b37f4d26bc9571228086d40884991633efb`.
Seu Dockerfile intacto foi executado com:

```sh
docker build --progress=plain --tag pascal-snake-baseline:local .
```

Resultado: **falha**, com `Fatal: Can't find unit crt used by SnakeGame`.
A tag flutuante `frolvlad/alpine-fpc` resolveu para o índice
`sha256:91da1f657792b48b3780c1c198d7892e99d25fdb4eb42e6a4167be81ee6e3b52`.

O mesmo `SnakeGame.pas`, montado somente para leitura em `/baseline`, foi
compilado na nova toolchain, com outputs no container descartável:

```sh
fpc -Mobjfpc -Cr -Co -FU/work -FE/work /baseline/SnakeGame.pas
```

Resultado: **169 linhas compiladas**, saída zero. Isso confirma a diferença
de empacotamento; não valida a jogabilidade ou os limites do código original.
Chess teve árvore e código integral inspecionados; não foi compilado ou alterado.

## Matriz de prova

| Critério | Comando ou teste executado | Resultado |
|---|---|---|
| Plano anterior ao código | Histórico Git: `45844b0` antes de `50aca1d` | Plano em commit próprio antes da implementação |
| Pascal continua sendo a aplicação | Compilação de `SnakeGame.pas` e duas units Pascal | Nenhuma regra ou interface de jogo em outra linguagem |
| Compilar e testar em ambiente fixado | `make test` | Build e testes em Docker aprovados |
| Dimensões, seeds e comida livre | Primeiro grupo da suíte Pascal; 1.024 aberturas | Aprovado |
| Direção, reversão e curva por tick | Segundo grupo, todas as direções | Aprovado |
| Crescimento e pontuação | Terceiro grupo, cinco segmentos contíguos e inicializados | Aprovado |
| Colisão e cauda | Quarto grupo, quatro paredes, corpo e cauda com/sem crescimento | Aprovado |
| Capacidade e vitória | Quinto grupo, célula única livre e array completo de 800 posições | Aprovado |
| Fases e velocidade | Sexto grupo, pausa sem mutação e limite de 45 ms | Aprovado |
| Determinismo e invariantes | Sétimo grupo, 256 seeds × 200 passos em pares | Aprovado |
| CLI e terminal sem Docker aninhado | `make local-smoke` no estágio `test` | Help limpo, argumentos inválidos, seeds-limite e rejeição sem TTY aprovados |
| Interação com o binário | Smoke PTY em container | Início, velocidade, pausa imóvel, setas, reinício, resize e derrota aprovados |
| Interação com a imagem final | `make image` seguido de `make smoke` | Aprovado pelo PTY do host e CLI Docker |
| Encerramento | Smoke PTY por Q, Esc e Ctrl-C | Saída zero, cursor visível e atributos do PTY restaurados |
| Janela pequena | PTY inicial 40 × 12 e redução de 80 × 24 para 50 × 16 | Mensagem e saída disponíveis; pausa preservada ao restaurar |
| Compose | `docker compose config --quiet` | Configuração válida |
| Isolamento da imagem | `docker image inspect pascal-snake:local` | ARM64; usuário `65532:65532`; sem portas ou volumes declarados |

A suíte Pascal passou com **7 grupos, 1.062.856 verificações**, incluindo
**51.200 passos comparados em pares**. O total de asserts não representa
milhões de cenários distintos: muitos são invariantes repetidos após um passo.
O compilador foi executado com `-Cr -Co -Ci -Sa`, símbolos de diagnóstico e
sem warnings nas fontes do jogo ou dos testes.

## Regressões encontradas durante a validação

O primeiro smoke identificou que `CursorOn/Off` do Crt em Unix não emitia
o modo de visibilidade esperado por terminais ANSI. A implementação passou
a emitir explicitamente `?25l` e `?25h`, com teste de restauração.

O primeiro smoke da imagem final também expôs uma particularidade do harness:
alterar o tamanho de um PTY sem grupo foreground não notificava o processo
Docker. O helper agora envia `SIGWINCH` após mudar o tamanho, permitindo ao
transporte encaminhar a nova geometria. Esse ajuste pertence ao teste; o jogo
continua consultando a geometria real do próprio terminal.

## Limites da evidência

- A tentativa de build `--platform linux/amd64 --target test` falhou antes
  de executar APT, com `exec /bin/sh: exec format error`. A base tem manifest
  AMD64, mas este runtime não a executa; o código nessa arquitetura permanece
  não validado. Não foi instalada emulação nem alterado o host para contornar isso.
- A inspeção do aplicativo Terminal por automação de UI foi bloqueada pela
  ferramenta. Há validação de interação por PTY, sem claim de screenshot ou
  inspeção visual humana. Vitória e capacidade máxima foram provadas no motor,
  sem alegar uma partida humana completa de 420 células.
- O binário nativo de macOS/Windows e terminais não ANSI não foram validados.
  O pacote usa unidades Unix; Docker é o caminho de referência.
- A configuração fixa entradas do build, mas não promete binários idênticos
  byte a byte entre plataformas.
- O diff inclui código e container: classificação de segurança `obrigatório`.
  O scanner agentic do harness permanece report-only, com
  `not_run_without_authorization`; testes e review não são prova de ausência
  de toda vulnerabilidade.

## Estado da entrega

O baseline, plano, código, testes e documentação ficam em commits locais
temáticos. Os SHAs finais e o veredito do review independente são apresentados
no relatório local de entrega, fora do HEAD que o próprio review avalia.
Nenhuma imagem, branch, Issue, Pull Request ou release foi publicada; nenhuma
visibilidade, estado de arquivamento ou ref remota foi modificada.
