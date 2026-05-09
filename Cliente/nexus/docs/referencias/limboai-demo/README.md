# Referencia: LimboAI Demo -> Rogue Agent

Este diretório consolida o estudo da demo oficial do LimboAI e como aplicar no Rogue Agent sem quebrar a arquitetura atual.

## Arquivos
- `limboai-demo-combate-referencia.md`
  - análise técnica dos padrões da demo
  - o que reaproveitar agora
  - o que não importar agora
  - plano incremental para combate inteligente

## Objetivo
Usar a demo como referência prática para elevar a inteligência dos agentes (player agents e NPCs do mundo) no padrão do projeto Rogue Agent, mantendo:
- modularidade
- data-driven
- estabilidade de produção
- evolução incremental

## Regra do projeto
- LimboAI é o core da inteligência.
- Sem refactor total arriscado.
- Cada avanço entra por vertical slice testável.

## Links oficiais
- LimboAI docs: https://limboai.readthedocs.io/en/stable/
- LimboAI BT: https://limboai.readthedocs.io/en/stable/behavior-trees/introduction.html
- LimboAI HSM: https://limboai.readthedocs.io/en/stable/hierarchical-state-machines/create-hsm.html
- Godot NavigationAgent2D: https://docs.godotengine.org/en/stable/classes/class_navigationagent2d.html

## Estado atual (prova aplicada no projeto)
1. Prova de conceito concluida com 2 hostis reais (`Light` e `Brute`).
2. Mesmo core de logica (BT/HSM/actor), variacao por `profile/action` data-driven.
3. Telemetria de combate validou diferenca de comportamento sem hardcode por inimigo.
