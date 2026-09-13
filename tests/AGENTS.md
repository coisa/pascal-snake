# AGENTS.md

## Purpose

Provar regras e interação sem depender de uma partida humana ou de dados reais.

## Ownership

A suíte Pascal governa as regras; o smoke Python opera somente PTYs sintéticos.

## Local Contracts

Fixtures podem montar estados válidos diretamente para alcançar casos raros.
Use seeds fixas, limites de tempo e asserts de comportamento. Não instale
pacotes Python, escreva no HOME, monte socket Docker ou exponha portas.

## Work Guidance

Uma regressão deve produzir falha observável. O helper de terminal pode chamar
o binário local ou o Docker por argumentos estruturados, sempre com cleanup.

## Verification

make test executa testes Pascal e PTY dentro do container. make smoke verifica
a imagem de jogo por um PTY do host; Python é infraestrutura de teste.

## Child DOX Index

- test_snake_engine.pas: colisão, crescimento, comida, direção e invariantes.
- smoke_terminal.py: CLI, estados, controles, tamanho e restauração do terminal.
