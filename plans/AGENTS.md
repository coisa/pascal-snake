# Plans

## Purpose

Esta pasta guarda receitas canônicas e revisáveis para mudanças que alteram de forma material o exercício Pascal. Um plano descreve a implementação final; não é diário de execução, checklist vivo, Issue ou autorização para publicar.

## Ownership

O owner do repositório decide o escopo. A implementação local usa o plano antes de mudanças materiais e mantém o Pascal como linguagem da aplicação.

## Local Contracts

- Escreva em português brasileiro.
- Um arquivo cobre uma funcionalidade com objetivo, artefatos, passos, validação e rollback independentes.
- Use o nome `AAAA-MM-DD-descricao.md` quando o repositório não possuir uma convenção mais específica.
- Registre somente decisões confirmadas e lacunas concretas; não invente Issue, Pull Request, URLs, estado de aprovação ou evidência de execução.
- Mantenha o plano alinhado à implementação final. A evolução anterior fica no Git, sem cópias concorrentes do plano.

## Work Guidance

Antes de criar outro plano, procure por uma receita com o mesmo objetivo ou artefatos. Para mudanças não triviais, use uma matriz que associe requisito, passo e prova. Declare claramente ações externas proibidas e o rollback local por commits, sem tratar o plano como autorização de publicação ou alteração remota.

## Verification

Revise caminhos, restrições, dependências, critérios de aceite, matriz de rastreabilidade e comandos de validação antes de iniciar a implementação.

## Child DOX Index

- `2026-09-13-implementation.md`: receita do POC de modernização local do Snake em Pascal.
