# AGENTS.md

## Purpose

Exercício de Snake em Pascal, modernizado como referência pequena e estudável.
O jogo, suas regras e os testes de regras permanecem em Pascal.

## Ownership

O histórico de `coisa/pascal-snake` é a origem do exercício. A prova de conceito
é local: seu escopo não inclui push, Issue/PR remoto, publicação de imagens,
merge, alteração de visibilidade ou arquivamento.

## Local Contracts

- Preserve `SnakeGame.pas` como entrada da aplicação.
- Separe regras determinísticas de terminal, relógio e teclado.
- Documentação em PT-BR; identificadores em inglês. A interface usa palavras
  que cabem em ASCII para não depender da codificação de caracteres do Crt.
- O Git preserva o original. Não crie cópias paralelas de fontes antigas.
- `tmp/` e `build/` são saídas locais ignoradas. Nunca monte HOME ou o socket
  Docker nos containers. O jogo não usa rede, arquivos pessoais ou serviços.
- A implementação tem um plano anterior ao código em `plans/` e evidência
  factual em `docs/`. Não invente licença, Issue, aprovação ou validação.

## Work Guidance

Leia o contrato da pasta antes de editar. Mantenha commits temáticos, faça
testes com dados sintéticos e registre mudanças observáveis no changelog.
O fluxo Docker é a referência reproduzível; FPC local é uma conveniência.

## Verification

Execute `make test`, `make image`, `make smoke` e `git diff --check`.
Valide o terminal por PTY e confira a renderização. Faça review independente
do diff final antes de apresentar a implementação como revisada.

## Child DOX Index

- [plans/AGENTS.md](plans/AGENTS.md): receita de implementação e aceite.
- [src/AGENTS.md](src/AGENTS.md): regras e apresentação em Pascal.
- [tests/AGENTS.md](tests/AGENTS.md): testes determinísticos e PTY sintético.
- [docs/AGENTS.md](docs/AGENTS.md): origem, arquitetura e evidência.
- [README.md](README.md): como compilar, testar, jogar e estudar.
- [CHANGELOG.md](CHANGELOG.md): mudanças observáveis nesta prova de conceito.
