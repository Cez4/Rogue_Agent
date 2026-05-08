# LimboAI Demo - Referencia de Combate e IA para Rogue Agent

## Contexto
Este documento registra o estudo da demo do LimboAI presente em `res://demo` e define como reutilizar os padrões com baixo risco no Rogue Agent.

Escopo: aumentar inteligência de combate e comportamento de agentes sem danificar o projeto.

---

## 1) O que a demo prova na prática

### 1.1 Pipeline modular de combate
A demo separa claramente as responsabilidades:
- `Health` (`demo/agents/scripts/health.gd`)
- `Hitbox` (`demo/agents/scripts/hitbox.gd`)
- `Hurtbox` (`demo/agents/scripts/hurtbox.gd`)

Isso evita lógica monolítica e permite evolução independente de:
- dano
- knockback
- morte
- reação

### 1.2 IA com BT + Blackboard por agente
Cada agente pode ter:
- BT própria
- Blackboard own config

Exemplo:
- `demo/agents/01_agent_melee_simple.tscn`
- `demo/ai/trees/*.tres`

Isso encaixa no nosso objetivo de agentes inteligentes e distintos.

### 1.3 Tasks táticas reutilizáveis
Tasks que representam bom padrão para nosso combate:
- `in_range.gd` -> decisão por janela de distância
- `pursue.gd` -> aproximação progressiva/inteligente
- `select_flanking_pos.gd` -> reposicionamento lateral

### 1.4 Estado de ataque com janela temporal
`demo/agents/player/states/attack_state.gd` mostra:
- entrada controlada
- combo/cooldown
- evento de finalização

Esse padrão é superior a apenas "tocar animação de ataque".

---

## 2) O que devemos reaproveitar agora

### 2.1 Sim (baixo risco)
1. Componentes de combate separados:
   - HealthComponent
   - HitboxComponent
   - HurtboxComponent
2. Estrutura BT orientada a decisão tática:
   - acquire target
   - in range
   - pursue/reposition
   - attack
3. HSM para execução da ação:
   - Windup -> Active -> Recover

### 2.2 Não agora (risco alto / fora do MVP)
1. Copiar `agent_base.gd` completo da demo para virar base global.
2. Importar sistema completo de summons/projéteis/FX da demo.
3. Refactor geral para arquitetura da demo inteira.

---

## 3) Como aplicar no Rogue Agent sem quebrar

### Fase 1 (MVP combate)
- Implementar `HealthComponent`, `HitboxComponent`, `HurtboxComponent` no nosso projeto.
- Integrar primeiro no player e 1 alvo de teste.
- Manter LimboAI para decisão e estado de execução.

### Fase 2 (NPC combate inteligente)
- Criar BTs específicas por classe de NPC.
- Adicionar táticas:
  - manter distância ideal
  - reposicionar
  - escolher janela de ataque

### Fase 3 (expansão)
- defesa/guard
- stagger
- prioridade de skill
- suporte em grupo (assist/focus)

---

## 4) Relação com a visão do projeto (Rogue Agent)

Nosso alvo não é action arcade, nem RTS estático.
Nosso alvo é agent-sim com combate vivo:
- atacar
- defender
- reposicionar
- trocar comportamento

A demo do LimboAI confirma que esse caminho é viável com:
- BT + Blackboard para decisão
- HSM para execução
- componentes separados para resolução de combate

---

## 5) Decisão técnica atual

- Não migrar para ECS framework completo agora.
- Sim, modularizar combate desde já (core do jogo).
- Avançar por vertical slices estáveis e testáveis.

Resumo:
A demo oferece padrões prontos e sólidos. Devemos absorver os padrões, não clonar a demo.

---

## 6) Fontes oficiais de suporte

- LimboAI stable docs:
  https://limboai.readthedocs.io/en/stable/
- LimboAI Behavior Trees:
  https://limboai.readthedocs.io/en/stable/behavior-trees/introduction.html
- LimboAI Blackboard:
  https://limboai.readthedocs.io/en/stable/behavior-trees/using-blackboard.html
- LimboAI HSM:
  https://limboai.readthedocs.io/en/stable/hierarchical-state-machines/create-hsm.html
- Godot NavigationAgent2D:
  https://docs.godotengine.org/en/stable/classes/class_navigationagent2d.html
