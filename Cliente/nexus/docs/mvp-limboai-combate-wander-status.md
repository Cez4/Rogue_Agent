# MVP LimboAI + Combate + Wander - Status Tecnico

Data: 2026-05-10
Branch historica: `feat/mvp-combate-fase1`
Estado atual consolidado: `feat/combat-orb-ui-contextual`

Freeze funcional oficial da fase atual:
- `docs/status-freeze-funcional-v2-2026-05-10.md`
- Este arquivo centraliza Orb V3 (congelada), Stamina/Stagger consolidado e hardenings recentes.

Atualizacao de estado:
- Plano final de desacoplamento do actor concluido (Cortes 1-4).
- Checklist padrao de regressao para PR criado:
  - `docs/checklist-regressao-pr-actor-bt-hsm.md`

## Objetivo atual
- Base jogavel com:
  - Player controlado por clique.
  - Ataque 8 direcoes com janela de hit.
  - NPCs com vida (wander/look/emotes) via LimboAI.
- Estrutura pronta para evolucao multiplayer autoritativa (cliente envia intencao, servidor valida/simula).

## Decisoes de arquitetura
- Actor base compartilhado: `Scripts/actors/actor_8dir_limbo.gd`.
- Separacao por responsabilidade:
  - Input/controlador (`PlayerController`).
  - Movimento/nav (`PlayerMotor` + `NavigationAgent2D`).
  - Estado/comportamento (`LimboHSM` e BT para NPC).
  - Combate modular (Health/Hurtbox/Hitbox + `CombatActionData`).
- Configuracao data-driven:
  - Acoes de combate em `.tres` (dano, windup, active, recover, cooldown).
  - Percepcao/chase em profiles `.tres`.

## Estado tecnico consolidado
1. BT decide, HSM executa, Motor locomove.
2. Chase/attack por intencao funcional e estavel.
3. Telemetria de combate + decisao BT operavel (painel debug e filtros).
4. Boundary/bridge do actor estabilizado (desacoplamento concluido na fase atual).
5. Paridade de combate 8dir concluida (hostis com Health + Hurtbox + AttackHitbox).

## Correcoes criticas recentes (runtime/lifecycle)
1. Hitbox seguro em callback de fisica:
   - `hitbox_component.gd` passou a usar `set_deferred("monitoring", ...)` e `set_deferred("monitorable", ...)`.
   - remove erro: `Function blocked during in/out signal`.
2. Fluxo de morte do player confirmado por log:
   - `target_died` -> `chase_canceled(reason=death)` -> `respawned`.
3. Causa raiz de "travar em pe" encontrada em override de cena instanciada:
   - `mundo.tscn` sobrescrevia `die_prefix/enable_respawn/respawn_delay_sec` do player.
   - regra oficial: auditar override no mapa principal sempre que `player.tscn` parecer "ignorado".

## Tuning v1 consolidado
1. Wildcat v1: concluido.
2. Player targeting: estabilizado para chase manual com cancelamento por motivo.
3. Light v1: concluido e congelado:
   - profile: `res://configs/combat/profiles/hostile_light_profile_v1.tres`
   - action: `res://configs/combat/hostile_light_attack_v1.tres`
   - scene: `res://cenas/enemies/hostile_enemy_light.tscn`
   - baseline final:
     - `lose_radius=126.0`
     - `target_memory_sec=0.65`
     - `reacquire_interval_sec=0.16`
     - `attack_stop_buffer=4.2`
     - `recover_sec=0.22`
     - `cooldown_sec=0.32`
     - `max_health=13.0`
4. Brute v1: concluido e congelado:
   - profile: `res://configs/combat/profiles/hostile_brute_profile_v1.tres`
   - action: `res://configs/combat/hostile_brute_attack_v1.tres`
   - scene: `res://cenas/enemies/hostile_enemy_brute.tscn`
   - baseline final:
     - `acquire_radius=100.0`
     - `lose_radius=146.0`
     - `target_memory_sec=0.95`
     - `reacquire_interval_sec=0.20`
     - `attack_stop_buffer=6.6`
     - `recover_sec=0.32`
     - `cooldown_sec=0.46`
     - `damage=1.25`

## Proximos passos tecnicos
1. Brute v1 congelado; iniciar proximo hostil por dados usando `enemy-profile-checklist-v1.md`.
2. Seguir checklist unico por novo inimigo:
   - `docs/enemy-profile-checklist-v1.md`
3. Atualizar matriz de tuning por ciclo:
   - `docs/combat-tuning-matrix-v1.md`
4. Evolucoes apos freeze do Brute:
   - telemetria BT enter/exit opcional por task;
   - feedback visual de hit;
   - validacao multiplayer futura (range/LOS/cooldown no host).

## Arquivos-chave
- Actor base:
  - `Scripts/actors/actor_8dir_limbo.gd`
- Runtime bridge/servicos:
  - `Scripts/actors/services/actor_runtime_bridge.gd`
  - `Scripts/actors/services/actor_combat_profile_runtime.gd`
  - `Scripts/actors/services/actor_targeting_runtime.gd`
- Estado de ataque:
  - `Scripts/actors/state_attack_8dir.gd`
- Componentes de combate:
  - `Scripts/combat/health_component.gd`
  - `Scripts/combat/hurtbox_component.gd`
  - `Scripts/combat/hitbox_component.gd`
  - `Scripts/combat/combat_action_data.gd`
- Cenas de hostis:
  - `cenas/enemies/hostile_enemy_base.tscn`
  - `cenas/enemies/hostile_enemy_light.tscn`
  - `cenas/enemies/hostile_enemy_brute.tscn`

## Referencias
- LimboAI docs:
  - https://limboai.readthedocs.io/en/latest/
- Godot NavigationAgent2D:
  - https://docs.godotengine.org/en/4.1/classes/class_navigationagent2d.html
- Godot Navigation guide:
  - https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html

## Prova de conceito data-driven (confirmada)
1. Validada com 2 inimigos reais em producao: `HostileEnemyLight` e `HostileEnemyBrute`.
2. Ambos compartilham a mesma logica core (BT/HSM/actor).
3. Variacao de comportamento vem apenas de dados (`combat_perception_profile` e `combat_action_data`).
4. Telemetria comprovou diferenca por dados (range efetivo de parada, cadence e dano) sem script dedicado por inimigo.
