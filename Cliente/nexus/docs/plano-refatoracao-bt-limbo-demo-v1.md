# Plano de Refatoração Arquitetural: BT LimboAI Demo-Style

**Data:** 11-05-2026
**Autor:** Tech Lead (Gemini Agent)
**Status:** [AGUARDANDO INÍCIO]

## Visão Geral
Este documento define o roteiro cirúrgico para refatorar o sistema de Inteligência Artificial e Combate do Rogue Agent. O objetivo é abandonar a "Síndrome de God Script" (scripts massivos e rígidos) e adotar 100% a arquitetura modular baseada em composição visual e *Decorators* nativos, idêntica à Demo Original do LimboAI (`04_agent_skirmisher.tres`).

## Objetivos Arquiteturais
1. **Desacoplamento Extremo:** Nenhuma task deve calcular matemática E mover o motor E gerenciar tempo. Cada task faz **apenas uma coisa**.
2. **Game Feel Orgânico:** Usar `BTTimeLimit` e `BTRandomWait` para gerenciar pausas táticas (Breathing Room) sem precisar hardcodar milissegundos no GDScript.
3. **Blackboard como Ponte:** Todas as coordenadas e intenções devem trafegar pelo Blackboard.

---

## 🗺️ Step-by-Step Executivo (Checklists)

### Fase 1: Criação da Base (Tasks Atômicas)
Nesta fase, criaremos os "tijolos" (scripts minúsculos e reutilizáveis) que formarão a nova árvore. Nenhuma cena será alterada ainda.

- [ ] **Criar `bt_is_stamina_low.gd`:** Condition Task que apenas checa o `StaminaComponent` e retorna SUCCESS se estiver baixo (ex: < 20% ou exausto).
- [ ] **Criar `bt_get_kite_position.gd`:** Action Task que calcula um `Vector2` seguro na direção oposta ao inimigo e salva a coordenada em uma variável do Blackboard (ex: `kite_pos`). Retorna SUCCESS imediato.
- [ ] **Criar `bt_get_approach_position.gd`:** Action Task que atualiza a coordenada de perseguição no Blackboard.
- [ ] **Criar `bt_move_to_blackboard_pos.gd`:** Action Task contínua. Puxa uma coordenada do Blackboard e envia para o `PlayerMotor` / `NavigationAgent2D`. Retorna RUNNING enquanto anda. Retorna SUCCESS ao chegar.
- [ ] **Criar `bt_emit_telemetry.gd`:** Action Task configurável que aceita o nome de um evento via `@export` e o dispara para a classe de telemetria, retornando SUCCESS imediato.

### Fase 2: Construção da Árvore Visual (Player MVP)
Construiremos uma árvore inteiramente nova para validar o Game Feel no Player, sem quebrar os inimigos.

- [ ] **Criar `player_combat_bt_v2.tres`** (Nova árvore isolada).
- [ ] **Montar Ramo de "Tactical Retreat" (Kiting):**
  - Sequence
    - Condition: `bt_is_stamina_low`
    - Action: `bt_emit_telemetry` (Evento: "kiting_started")
    - Action: `bt_get_kite_position`
    - AlwaysSucceed (Pai do movimento)
      - TimeLimit (Ex: 1.5s) -> Action: `bt_move_to_blackboard_pos`
    - Action: `bt_play_animation` (Idle)
    - RandomWait (Ex: 1.0 a 2.0s) -> O "Breathing Room".
    - Action: `bt_emit_telemetry` (Evento: "kiting_ended")
- [ ] **Montar Ramo de Ataque (Melee):**
  - Sequence
    - Condition: Alvo no Range?
    - Cooldown Decorator (Gerencia a cadência da arma nativamente)
      - Ações de Windup -> Active -> Recover.
- [ ] **Montar Ramo de Perseguição (Chase):**
  - Sequence
    - Action: `bt_get_approach_position`
    - TimeLimit (Ex: 1.0s) -> Action: `bt_move_to_blackboard_pos`
- [ ] **Acoplar e Testar:** Substituir a árvore do Player na cena e homologar.

### Fase 3: Propagação para Inimigos (NPCs)
Uma vez que o Game Feel do Player esteja perfeitamente rítmico e fluido:

- [ ] Clonar a estrutura validada para `hostile_enemy_combat_bt_v2.tres`.
- [ ] Substituir a BT das cenas `hostile_enemy_base`, `light` e `brute`.
- [ ] Substituir a BT do `wildcat_1`.

### Fase 4: O "Purge" (Limpeza Final)
Com todos usando a arquitetura Modular, apagaremos os vestígios da arquitetura antiga.

- [ ] Excluir `bt_low_stamina_tactical.gd`.
- [ ] Excluir `bt_chase_combat_target.gd` (A versão monolítica legada).
- [ ] Excluir `bt_wait_stamina_regen.gd` (A lógica agora vive no `BTWait`).
- [ ] Limpar variáveis ociosas no `Actor8DirLimbo` e runtimes que não são mais necessárias.

### Fase 5: Auditoria de Telemetria
- [ ] Rodar combate massivo pelo Godot MCP.
- [ ] Extrair os logs e garantir que os eventos de `attack_started`, `hit_confirmed`, e o novo fluxo de `kiting_started` ocorram com o timing orgânico projetado.

---
**Nota do Tech Lead:** Ao terminar este plano, o código do projeto será 10x mais limpo, fácil de debuggar para os Game Designers, e a árvore será visualmente idêntica aos padrões AAA que a Demo do LimboAI ensina.