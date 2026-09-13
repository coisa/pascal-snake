---
title: "POC de modernização local do Snake em Pascal"
slug: 2026-09-13-implementation
source: solicitação explícita do owner em 2026-09-13
---

## Objetivo

Transformar o exercício Snake em uma referência educacional local, mantendo FreePascal 3.2.2 e `SnakeGame.pas` como entrada. A implementação separará as regras determinísticas da interface de terminal, terá build e testes reproduzíveis em Docker e documentará os limites do POC.

## Resultado Esperado

- Jogo de terminal Pascal jogável em um tabuleiro 30 por 14, legível em terminal de pelo menos 70 por 24.
- Regras testáveis sem `Crt` ou entrada e saída no motor.
- Fluxos de compilação, teste e execução disponíveis localmente e por Docker.
- Documentação que compare o exercício original com a referência sem alegar publicação, unarchive, mudança de visibilidade ou merge.

## Mudanças Planejadas

### Restrições Globais

- Preservar Pascal e FreePascal 3.2.2; `SnakeGame.pas` permanece a entrada na raiz.
- Colocar regras em `src/snake_engine.pas`, sem `Crt`, relógio, terminal ou I/O; `src/snake_terminal.pas` concentra a interface baseada em `Crt`.
- Preservar WASD, paredes e corpo fatais e tamanho inicial cinco. Adicionar pontuação de dez por alimento, setas, pausa, reinício, saída, recorde da sessão e velocidades selecionáveis.
- Aplicar crescimento gradual de cinco segmentos por alimento sem ultrapassar células disponíveis; permitir ocupar a cauda que sairá quando não houver crescimento; encerrar em vitória ao preencher o tabuleiro.
- Usar uma única curva válida por tick, semente local de RNG e seleção finita de alimento apenas entre células livres.
- Usar ASCII portável, cores quando o terminal permitir e atualização de células, sem limpar a tela inteira a cada tick.
- Fixar `debian:bookworm-slim` pelo digest `sha256:88200866dfff7ea7f5cbcb6ec7c8a701889efe6fe859fe64d6990e4b07ea4171`, usar o snapshot APT `20260901T000000Z` e `fp-compiler` 3.2.2+dfsg-20. Instalar somente as units adicionais que a compilação provar necessárias, começando por `fp-units-rtl`; avaliar `fp-units-base` contra a fonte atual. O runtime Docker roda como usuário não root e não expõe portas nem declara volumes.
- Não publicar, desarquivar, mudar visibilidade, criar Issue ou Pull Request, enviar alterações remotas ou fazer merge como parte desta receita.

### Mapa De Artefatos

| Artefato Ou Contrato | Ação | Responsabilidade |
|---|---|---|
| SnakeGame.pas | alterar | Inicializar o jogo e delegar ao terminal sem embutir regras. |
| src/snake_engine.pas | criar | Estado, transições determinísticas, limites, pontuação e RNG local. |
| src/snake_terminal.pas | criar | Entrada `Crt`, temporização, renderização incremental e cores ASCII. |
| tests/test_snake_engine.pas | criar | Fixtures e propriedades das invariantes do motor. |
| tests/smoke_terminal.py | criar | Exercitar o fluxo TUI por PTY sintético somente como teste. |
| Dockerfile | alterar | Toolchain FreePascal fixada e alvos de build, teste e jogo. |
| Makefile | criar | Atalhos para Docker e FPC local, sem mascarar os comandos subjacentes. |
| docker-compose.yml | alterar | Preservar `snake_game` como serviço atualizado, sem publicação. |
| README.md e docs/ | criar | Baseline, arquitetura, uso, diferença educacional e evidência de validação. |
| CHANGELOG.md | criar ou alterar | Registrar a mudança versionada no bloco não publicado. |

### Matriz De Rastreabilidade

| Requisito Ou Decisão | Fonte | Tarefa, Passo, Exclusão Ou Bloqueio | Validação Ou Evidência |
|---|---|---|---|
| Snake foi selecionado: master 15477b37f4d26bc9571228086d40884991633efb, três arquivos, 4.107 bytes em SnakeGame.pas e dois commits | inspeção do implementador | Tarefa 1 | docs/baseline.md registra a referência e `git show` confirma o SHA. |
| O Dockerfile original falha no arm64 porque SnakeGame.pas usa Crt e a imagem frolvlad/alpine-fpc fixada em sha256:91da1f657792b48b3780c1c198d7892e99d25fdb4eb42e6a4167be81ee6e3b52 não fornece a unit | build original executado pelo implementador | Tarefa 3 | docs/validation.md preserva `SnakeGame.pas(3,6) Fatal: Can't find unit crt used by SnakeGame`; build Debian confirma a unit mínima instalada. |
| Chess não é o candidato inicial: master bec5c0cedae44637e2086ba9d6d52eb42a64b945, um arquivo de 6.516 bytes, um commit, arquivado e regras de movimento não validadas | inspeção do implementador | Excluído: outro POC independente | docs/baseline.md preserva a justificativa de seleção. |
| Motor é determinístico, isolado de Crt e preserva regras com os novos limites de crescimento, cauda, alimento e vitória | proposta técnica desta POC | Tarefa 1 | testes unitários e de propriedades exercitam colisão, crescimento, cauda, alimento, tabuleiro cheio, direções, pausa, velocidade e determinismo. |
| Terminal mantém interação educacional com WASD, setas, pausa, reinício, saída e renderização incremental | proposta técnica desta POC | Tarefa 2 | smoke PTY e inspeção manual documentada em docs/validation.md. |
| Toolchain reproduzível, Docker proporcional e alvos build, test e game | proposta técnica desta POC | Tarefa 3 | build Docker, testes Docker e inspeção de usuário, portas e volumes. |
| Documentação explica baseline, arquitetura, validação e diferença do exercício original | proposta técnica desta POC | Tarefa 4 | README, docs/baseline.md, docs/architecture.md e docs/validation.md revisados contra o código e os comandos executados. |
| Não alterar o repositório remoto nem seu estado público | limite explícito do owner | Excluído: publicação e mutações remotas | status Git local e ausência de comandos remotos no registro de validação. |

## Passos De Implementação

### Tarefa 1: Implementação Do Motor

- `Entrega`: Motor determinístico de Snake com interface Pascal testável.
- `Artefatos E Contratos`: `src/snake_engine.pas` e adaptação mínima de `SnakeGame.pas`.
- `Pré-condições`: O plano está versionado antes de mudanças materiais.
- `Consome`: Regras, dimensões e baseline definidos neste plano.
- `Produz`: Estado do jogo, operação de tick, mudança de direção, pausa, reinício, pontuação e resultado terminal.
- `Execução`:
  1. Definir tipos e operações públicas que não dependam de `Crt` nem de I/O.
  2. Implementar movimento, colisão, crescimento gradual, geração finita de comida, vitória e RNG de semente local.
  3. Garantir no contrato do motor uma curva válida por tick e a exceção segura da cauda que sai sem crescimento.
- `Validação`: Compilar o motor com os testes unitários e executar os casos de invariantes e propriedades.
- `Evidência Esperada`: Casos de colisão, alimento, capacidade, pausa, direções, velocidades e determinismo aprovados.
- `Handoff`: A interface pública está pronta para o terminal e para a suíte de testes.

### Tarefa 2: Implementação Do Terminal

- `Entrega`: Interface `Crt` jogável que consome apenas a interface do motor.
- `Artefatos E Contratos`: `src/snake_terminal.pas` e `SnakeGame.pas`.
- `Dependências`: Tarefa 1
- `Pré-condições`: Terminal de 70 por 24 ou maior para a experiência completa.
- `Consome`: Estado, transições e pontuação produzidos pelo motor.
- `Produz`: Entrada WASD e setas, pausa, reinício, saída, temporização, recorde da sessão, cores e renderização incremental ASCII.
- `Execução`:
  1. Mapear as teclas para intenções de entrada sem reimplementar regras no terminal.
  2. Desenhar moldura e células alteradas, atualizando somente a região necessária em cada tick.
  3. Exibir score, recorde de sessão, velocidade e estados de derrota ou vitória.
- `Validação`: Executar smoke de PTY sintético e fazer uma passagem manual com teclado em terminal compatível.
- `Evidência Esperada`: O smoke encerra sem travamento e a passagem manual registra os controles e o redesenho incremental.
- `Handoff`: A aplicação pode ser empacotada nos fluxos de build e teste.

### Tarefa 3: Configuração Da Reprodutibilidade

- `Entrega`: Build, teste e execução reproduzíveis sem alterar infraestrutura externa.
- `Artefatos E Contratos`: `Dockerfile`, `Makefile`, `docker-compose.yml`, testes Pascal e helper PTY.
- `Dependências`: Tarefa 1 e Tarefa 2
- `Pré-condições`: Docker disponível localmente; FPC local é opcional.
- `Consome`: Entrada Pascal, motor, terminal e especificação da imagem Debian fixada.
- `Produz`: Alvos `toolchain`, `test` e `game`; comandos Make equivalentes para Docker e FPC local.
- `Execução`:
  1. Fixar a base Debian e o snapshot definidos neste plano, instalar `fp-compiler` 3.2.2+dfsg-20 e adicionar `fp-units-rtl`, com `fp-units-base` somente se a fonte compilada o exigir, usando estágio de runtime sem root.
  2. Criar alvos de container para toolchain, compilação e testes, além de alvos Make que documentem a alternativa FPC local.
  3. Manter o serviço `snake_game` no Compose atualizado para a imagem local e sem portas ou volumes declarados.
  4. Implementar fixtures Pascal e property loops para crash, crescimento, cauda, comida, tabuleiro cheio, pausa, velocidades, direções e determinismo; limitar Python ao smoke TUI.
- `Validação`: Executar os alvos Docker de build e teste, o smoke PTY e a compilação FPC local quando disponível.
- `Evidência Esperada`: Binário compilado, suíte aprovada, inspeção da imagem com usuário não root e Compose sem portas ou volumes.
- `Handoff`: Comandos e resultados verificáveis seguem para documentação.

### Tarefa 4: Documentação Da Referência

- `Entrega`: Material que torna o POC ensinável e auditável sem depender desta conversa.
- `Artefatos E Contratos`: `README.md`, `docs/baseline.md`, `docs/architecture.md`, `docs/validation.md` e `CHANGELOG.md`.
- `Dependências`: Tarefa 3
- `Pré-condições`: Resultados de validação disponíveis no HEAD local.
- `Consome`: Baseline confirmado, contratos do motor e terminal, comandos de build e evidência de validação.
- `Produz`: Guia de uso, decisões arquiteturais, comparação com o exercício, comandos reproduzíveis e evidência final.
- `Execução`:
  1. Registrar o baseline do Snake e a exclusão inicial do Chess com fatos observados, sem alegar operação remota.
  2. Explicar a separação motor e terminal, invariantes, limites de capacidade, Docker e como rodar build, teste e jogo.
  3. Registrar em docs/validation.md os comandos realmente executados, resultados, ambiente e limites da passagem manual.
  4. Atualizar o bloco não publicado do changelog com uma descrição factual da referência local.
- `Validação`: Conferir que todos os comandos documentados correspondem aos alvos reais e que a matriz acima possui evidência em arquivo ou teste.
- `Evidência Esperada`: Um leitor reproduz a compilação, os testes e a execução, entendendo o que mudou em relação ao exercício original.
- `Handoff`: Review técnico local do HEAD e commits temáticos, sem push, merge ou publicação.

## Skills E Agentes Recomendados

- `plan-authoring`: manter a receita canônica antes da primeira mudança material.
- Implementador Pascal: executar motor, terminal e testes sem trocar a linguagem da aplicação.
- Revisor técnico: conferir o HEAD contra este plano e a evidência em docs/validation.md.

## Validação

### Autoauditoria Do Plan

- A seleção do Snake, o baseline e a exclusão do Chess têm fonte e evidência explícitas.
- Cada requisito material aponta para uma entrega, validação e evidência sem promover hipótese a fato.
- Todos os paths, versões, dimensões, comandos-alvo e limites de segurança local combinam entre as seções.
- O plano não inventa Issue, Pull Request, segredo, estado operacional ou autorização implícita para ação externa.
- Um executor pode aplicar a receita em outro exercício Pascal adaptando nomes e baseline, sem copiar contexto privado.

### Validação Da Implementação

- Rodar os alvos de toolchain, build e teste definidos pelo Makefile e Dockerfile.
- Rodar a suíte Pascal e o smoke PTY sintético; se FPC estiver disponível localmente, compilar e executar a mesma suíte fora do Docker.
- Fazer uma passagem manual no terminal com WASD, setas, pausa, reinício, saída, velocidade, pontuação, derrota e vitória quando reproduzível.
- Registrar somente resultados efetivamente observados em docs/validation.md, junto do SHA local testado.
- Verificar `git status`, diff e histórico de commits para confirmar que a entrega permanece local, temática e revisável.

## Adaptação No Repositório Destino

Ao aplicar esta receita em outro exercício Pascal, mantenha a linguagem e o arquivo de entrada definidos pelo destino, recapture seu baseline e altere somente os valores que o contrato local justificar. Escolha o backend de terminal já aceito pelo repositório, preserve regras educacionais confirmadas e substitua a matriz de testes pelos invariantes reais do jogo. Não copie dados privados, links remotos, estados de repositório ou alegações de validação desta referência.

## Rollback

Reverter localmente os commits temáticos do POC em ordem inversa, começando por documentação e automação e terminando no motor. Não manter caminhos alternativos nem versões paralelas como fallback; o exercício baseline e a evolução do POC permanecem recuperáveis pelo histórico Git.
