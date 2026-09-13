# Regras e apresentação

O programa tem três peças. `SnakeGame.pas` valida argumentos e chama a
interface. `snake_terminal` usa teclado, relógio e Crt. `snake_engine` recebe
intenções, transforma um record e devolve um resultado, sem I/O ou tempo.

```text
teclado ──> RequestTurn / StartGame / TogglePause
relógio ──> StepGame ──> TGame ──> células e placar no terminal
                         ↑
               testes Pascal sem terminal
```

## Um passo, em ordem

1. Se a partida não está em andamento, retornar sem alterar o estado.
2. Calcular a próxima cabeça a partir da direção aceita neste tick.
3. Verificar comida, dívida de crescimento, parede e corpo antes de mover.
4. Se a cauda vai sair, excluí-la dos obstáculos deste passo.
5. Crescer no máximo um segmento, deslocar o corpo e gravar a cabeça.
6. Atualizar pontuação e crescimento; encerrar em vitória ou sortear comida
   entre as células que agora estão livres.

Um movimento fatal muda a fase e preserva as posições válidas do corpo.
O crescimento acrescenta cinco à dívida, limitada ao espaço restante.
Cada passo consome no máximo uma unidade. Assim todo segmento novo recebe
uma posição concreta antes de ser lido ou desenhado.

O motor aceita tabuleiros de 6 × 2 até 40 × 20, no máximo 800 segmentos.
A interface escolhe 30 × 14 para caber em terminais comuns. O record público
permite estudar e montar fixtures; consumidores normais devem inicializá-lo
pela API e preservar dimensões, continuidade e unicidade do corpo.

## Comida e determinismo

Um bitmap temporário marca o corpo. O gerador Park–Miller, com estado de 31
bits guardado em `TGame`, escolhe o índice de uma célula livre. Uma varredura
finita resolve esse índice. Não há tentativa aleatória repetida até achar
espaço, nem novo sorteio que possa prender o jogo quando resta uma única vaga.
O produto usa `Int64`, evitando overflow mesmo com os checks habilitados.

A seed é normalizada para um estado não nulo. Mesma seed e mesmas intenções
por tick produzem o mesmo estado. Isso não promete que duas pessoas apertando
teclas em tempos diferentes produzam a mesma partida, nem é um RNG criptográfico.

## Tempo e entrada

O motor aceita somente a primeira curva perpendicular válida por tick.
Uma direção repetida ou inversão não consome esse direito; a segunda curva
fica bloqueada até o passo. Isso impede que uma sequência rápida transforme
duas curvas em uma reversão instantânea.

Calmo, Normal e Turbo começam em 180, 110 e 70 ms por passo. Cada alimento
reduz 2 ms, até 45 ms. O terminal consulta um relógio monotônico e não faz
uma sequência de passos atrasados para compensar uma pausa da máquina.
Redimensionar pausa a partida; uma janela pequena mostra instrução e mantém
Q disponível. O usuário retoma explicitamente depois de ampliar a janela.

## Desenho e encerramento

O frame estático contém título, placar, borda e controles. A grade usa duas
colunas por célula para proporções mais naturais; um mapa do frame anterior
evita redesenhar células sem mudança. Limpeza completa ocorre na mudança
de tela ou tamanho, não em cada movimento. Painéis comunicam início, pausa,
derrota e vitória. As etiquetas da UI usam vocabulário ASCII para não depender
dos caracteres DOS do exercício original.

O Crt continua cuidando de cor, coordenadas e teclado. Somente visibilidade
do cursor usa explicitamente o modo ANSI `?25`: o
[Crt 3.2.2 para Unix](https://github.com/fpc/FPCSource/blob/release_3_2_2/packages/rtl-console/src/unix/crt.pp)
implementa `CursorOn/Off` com sequências do console Linux. O `finally` restaura
cores e cursor, e a finalização do Crt restaura o modo de teclado. Os testes
comparam os atributos do PTY antes e depois de Q, Esc e Ctrl-C.

## Compilação reproduzível

O [Dockerfile](../Dockerfile) fixa o índice da imagem oficial Debian por
digest, o snapshot APT `20260901T000000Z` e o compilador
`fp-compiler-3.2.2=3.2.2+dfsg-20`. O pacote RTL correspondente inclui Crt.
APT continua validando assinatura e hashes: apenas a expiração do índice
histórico é desabilitada. O snapshot também fixa a resolução das dependências
transitivas. Consulte o [pacote Debian](https://packages.debian.org/bookworm/fp-compiler-3.2.2)
e a [documentação de snapshots](https://snapshot.debian.org/).

O estágio `toolchain` guarda as ferramentas. `build` compila e testa as regras;
`test` acrescenta a execução do smoke PTY. `game` recebe apenas o executável
e roda como UID/GID 65532. O Makefile e o Compose mantêm execução sem rede,
sem portas, sem volumes e com filesystem somente leitura para o jogo.
Reproduzibilidade aqui significa entradas fixadas e resultados verificáveis;
não foi afirmada identidade byte a byte entre arquiteturas ou toolchains.

Não há backend, som dependente de hardware, arquivo de recordes, comunicação
externa, engine gráfica ou framework de testes. Essas escolhas mantêm o
escopo próximo do exercício que originou o repositório.
