# Combat Tuning Matrix v1 (Archetype/Weapon/Status)

Data: 2026-05-08  
Escopo: tuning de combate (sem nova arquitetura)  
Base técnica: Godot + LimboAI + BT/HSM já implementados

## 1) Objetivo
Padronizar tuning de combate por dados para evitar regressão e acelerar balanceamento.

Regras:
1. Não criar sistema novo nesta fase.
2. Não alterar contrato BT/HSM.
3. Alterar somente parâmetros de archetype, arma e status.

## 2) Fonte única de tuning
Toda calibração deve usar apenas 3 camadas:

1. ArchetypeProfile
- `acquire_radius`
- `lose_radius`
- `target_memory_sec`
- `reacquire_interval_sec`
- `attack_stop_buffer`

2. WeaponProfile
- `attack_range`
- `windup_sec`
- `active_sec`
- `recover_sec`
- `cooldown_sec`
- `stamina_cost`
- `damage`
- `knockback_enabled`
- `knockback_strength`

3. StatBlock
- `hp`
- `move_speed` (quando entrar no motor por stat)
- `attack_speed` (quando aplicado na cadência)
- `perception` derivados:
  - `combat_acquire_radius`
  - `combat_lose_radius`
  - `combat_target_memory_sec`
  - `combat_reacquire_interval_sec`
- `attack_range_bonus`
- `attack_range_multiplier`
- `attack_stop_buffer`

## 3) Fórmulas oficiais (v1)
Implementação alvo para tuning (compatível com código atual):

1. Alcance final:
`final_attack_range = (weapon.attack_range + attack_range_bonus) * (1.0 + attack_range_multiplier)`

2. Distância de parada:
`attack_stop_distance = max(2.0, final_attack_range - attack_stop_buffer)`

3. Percepção final:
- `final_acquire = max(8.0, combat_acquire_radius)`
- `final_lose = max(final_acquire, combat_lose_radius)`
- `final_memory = max(0.0, combat_target_memory_sec)`
- `final_reacquire = max(0.01, combat_reacquire_interval_sec)`

4. Cadência de ataque (fase futura de stat attack_speed):
`phase_time = clamp(base_phase_time / attack_speed_factor, min_phase, max_phase)`

## 4) Pipeline de tuning (ordem obrigatória)
Aplicar em ciclos curtos na ordem:

1. Targeting
- calibrar `acquire/lose/memory/reacquire`

2. Approach/Stop
- calibrar `attack_range` + `attack_stop_buffer`

3. Attack Cadence
- calibrar `windup/active/recover/cooldown`

4. Survivability
- calibrar `damage`, `hp`, `knockback`, TTK

Não pular ordem para evitar falso positivo.

## 5) Métricas e telemetria (v1)
Eventos obrigatórios:
1. `target_acquired`
2. `target_lost`
3. `reacquire`
4. `attack_commit`
5. `attack_blocked_reason`
6. `target_died`
7. `respawned`
8. `chase_canceled` (com `reason` e `manual_lock`)

Sinais de problema:
1. `attack_blocked_reason=out_of_range` excessivo durante chase.
2. `target_lost` frequente em curta distância.
3. `reacquire` muito alto com pouco `attack_commit`.

## 6) Tabela de archetypes (baseline atual + tuning por ciclo)
| Archetype | Acquire | Lose | Memory | Reacquire | Stop Buffer | HP | Notes |
|---|---:|---:|---:|---:|---:|---:|---|
| melee_baseline_current | 120.0 | 148.0 | 1.2 | 0.12 | 2.0 | 10.0 | defaults do actor/combat profile |
| player_melee_baseline_v1 | 120.0 | 156.0 | 1.2 | 0.12 | 2.0 | 10.0 | `configs/combat/profiles/player_melee_baseline_v1.tres` |
| hostile_melee_baseline_v1 | 88.0 | 124.0 | 0.60 | 0.18 | 4.5 | 12.0 | `configs/combat/profiles/hostile_melee_baseline_v1.tres` |
| melee_light_v1 | TBD | TBD | TBD | TBD | TBD | TBD | tuning alvo |
| melee_tank_v1 | TBD | TBD | TBD | TBD | TBD | TBD | tuning alvo |
| ranged_skirmisher_v1 | TBD | TBD | TBD | TBD | TBD | TBD | futuro |

## 7) Tabela de armas (baseline atual + tuning por ciclo)
| Weapon | Range | Windup | Active | Recover | Cooldown | Stamina Cost | Damage | Knockback |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| dagger_starter_current | 46.0 | 0.12 | 0.10 | 0.20 | 0.28 | 20.0 | 1.0 | false / 260 |
| wildcat_claw_v1 | 48.0 | 0.14 | 0.09 | 0.24 | 0.36 | 20.0 | 1.0 | false / 260 |
| hostile_light_attack_v1 | 42.0 | 0.12* | 0.08* | 0.22 | 0.32 | 14.0 | 0.85 | false / 220 |
| hostile_brute_attack_v1 | 50.0 | 0.18 | 0.12 | 0.32 | 0.46 | 28.0 | 1.25 | false / 300 |

`*` usa default do `CombatActionData` quando nao sobrescrito no `.tres`.

## 7.1) Health Regen v1
Sprint: `plano-sprint-health-regen-datadriven-v1-2026-05-11.md`

| Sistema | Valor | Fonte | Notes |
|---|---:|---|---|
| health_regen_per_sec | 3.0 | `HealthRegenComponent.regen_per_sec` | regen passiva fora de combate |
| out_of_combat_delay_sec | 2.0 | `HealthRegenComponent.out_of_combat_delay_sec` | evita cura imediata ao perder alvo |
| tick_interval_sec | 0.2 | `HealthRegenComponent.tick_interval_sec` | reduz ruido de processamento/log |
| regen_when_dead | false | `HealthRegenComponent.regen_when_dead` | heal nao revive entidade nesta sprint |

Contrato:
1. Regen consulta `ActorCombatRuntime.is_actor_in_combat(actor)`.
2. Orb tambem consulta o mesmo contrato.
3. Nao duplicar regra de combate em UI/Regen.

## 8) Checklist de regressão MCP
Cena padrão: `res://cenas/mundo.tscn`

1. `open_scene`
2. `play_scene`
3. Teste de distância curta/média/longa
4. Teste de chase + cancel + reacquire
5. Teste de ataque sequencial e commit
6. Teste de morte + respawn + reset de memória
7. `get_godot_errors` sem erro novo

Critério de aprovação:
1. 0 erro runtime/blackboard.
2. Fluxo BT/HSM estável.
3. Telemetria coerente com o tuning aplicado.

## 9) Guardrails de não regressão
1. BT decide, HSM executa, Motor locomove.
2. Não duplicar chase fora de tasks BT quando `use_bt_brain=true`.
3. Não reintroduzir hardcode de percepção nas tasks.
4. Não alterar input-intent durante tuning.

## 11) Status atual do ciclo
1. Ciclo 1 iniciado com perfis explícitos aplicados em cena:
   - Player -> `player_melee_baseline_v1.tres`
   - Hostile melee baseline -> `hostile_melee_baseline_v1.tres`
2. Validação MCP:
   - `open_scene(mundo.tscn)` + `play_scene` + `get_godot_errors`
   - sem novo erro de parse/runtime
3. Próxima ação do ciclo:
   - coletar telemetria de combate em sessão de teste guiada e ajustar somente variáveis do profile.
4. Ajuste aplicado no Wildcat (passo atual):
   - reduce aggro envelope: `acquire 96->88`, `lose 132->124`
   - reduce memory churn: `memory 0.75->0.60`, `reacquire 0.14->0.18`
   - improve melee stop: `stop_buffer 3.5->4.5` (aproxima mais antes de atacar)
5. Correção de precedência em runtime:
   - `Stats.attack_stop_buffer` estava inicializando com `base_attack_stop_buffer` (2.0), reduzindo efeito do profile.
   - corrigido para inicializar com `combat_perception_profile.attack_stop_buffer` quando profile existe.
   - objetivo: garantir que tuning data-driven do profile seja aplicado de fato no runtime.

## 10) Referências
1. Godot NavigationAgent2D:
https://docs.godotengine.org/en/4.5/classes/class_navigationagent2d.html
2. Godot NavigationAgents:
https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html
3. LimboAI BehaviorTree:
https://limboai.readthedocs.io/en/latest/classes/class_behaviortree.html
4. LimboAI BTAction:
https://limboai.readthedocs.io/en/latest/classes/class_btaction.html
5. LimboAI Blackboard:
https://limboai.readthedocs.io/en/latest/behavior-trees/using-blackboard.html

## 12) Gate operacional da fase (2026-05-09)
1. Seguir runbook: `Docs/godotmcp/runbook-edicao-segura-cenas.md`.
2. Ordem Git obrigatoria: `add -> commit -> status(ahead) -> push -> status(final)`.
3. Proximo ciclo imediato:
   - coletar baseline do Wildcat (30-60s, chase/cancel/chase/death/respawn);
   - ajustar somente `ArchetypeProfile` hostile em um eixo por vez.
4. Protocolo operacional de sessao:
   - `docs/wildcat-tuning-session-protocol-v1.md`
5. Ciclo 2 aplicado (Targeting only):
   - `acquire_radius: 88.0 -> 92.0`
   - `lose_radius: 124.0 -> 132.0`
   - `target_memory_sec: 0.60 -> 0.75`
   - `reacquire_interval_sec: 0.18 -> 0.16`
   - `attack_stop_buffer` mantido em `4.5` (sem mudanca de eixo).
6. Ciclo 3 aplicado (Approach/Stop only):
   - `attack_stop_buffer: 4.5 -> 4.0`
   - targeting mantido do ciclo 2:
     - `acquire_radius: 92.0`
     - `lose_radius: 132.0`
     - `target_memory_sec: 0.75`
     - `reacquire_interval_sec: 0.16`
7. Ciclo 4 aplicado (Cadence only):
   - novo profile de ataque do Wildcat:
     - `configs/combat/wildcat_claw_attack_v1.tres`
   - tempos (antes default state_attack):
     - `windup: 0.12 -> 0.14`
     - `active: 0.08 -> 0.09`
     - `recover: 0.16 -> 0.22`
     - `cooldown: 0.24 -> 0.32`
   - dano mantido em `1.0`.
8. Ciclo 5 aplicado (Survivability only):
   - Wildcat `max_health: 12.0 -> 14.0` (override local na cena).
   - dano mantido em `1.0` (Player e Wildcat), sem alterar eixo de cadence/targeting.
9. Ciclo 6 aplicado (Approach/Stop only):
   - `attack_stop_buffer: 4.0 -> 4.8` (Wildcat).
   - objetivo: reduzir `attack_blocked_reason=out_of_range` em kite, aproximando mais antes do commit.
   - demais eixos mantidos (targeting/cadence/survivability sem mudança).
10. Ciclo 7 aplicado (Cadence only):
   - `recover_sec: 0.22 -> 0.24` (Wildcat claw).
   - `cooldown_sec: 0.32 -> 0.36` (Wildcat claw).
   - objetivo: reduzir cadencia excessiva em lock-step e melhorar janela de reposicionamento entre commits.
11. Proximo ajuste planejado (Player chase persistence):
   - foco no profile do Player (nao Wildcat): reduzir cancelamento de chase em longa distancia/kite.
   - sintomas vistos em telemetria: `manual_lock=true` seguido de repetidos `out_of_range` e depois `target_lost/chase_canceled`.
   - eixo alvo do proximo ciclo: Targeting do Player (`target_memory_sec`, `lose_radius`, `reacquire_interval_sec`).
12. Ciclo 8 aplicado (Player Targeting only):
   - `lose_radius: 156.0 -> 172.0`
   - `target_memory_sec: 1.2 -> 1.6`
   - `reacquire_interval_sec: 0.12 -> 0.10`
   - objetivo: reduzir `target_lost/chase_canceled` precoce no lock manual de longa distancia.
   - leitura inicial de telemetria: comportamento ainda perde lock cedo em longa distancia (`target_lost/chase_canceled` persistente); requer novo ciclo de targeting do Player.
13. Ciclo 9 aplicado (Player Targeting fine-tune):
   - `lose_radius: 172.0 -> 184.0`
   - `target_memory_sec: 1.6 -> 1.9`
   - `reacquire_interval_sec: 0.10` (mantido)
   - objetivo: aumentar persistencia de chase em longa distancia sem alterar regra de cancelamento por input.
14. Ciclo 10 aplicado (Player Targeting final pass):
   - `reacquire_interval_sec: 0.10 -> 0.12`
   - `lose_radius: 184.0` (mantido)
   - `target_memory_sec: 1.9` (mantido)
   - objetivo: reduzir ruido de reacquire/blocked em kite sem afetar lock manual.
15. Producao data-driven de hostis (A/B de personalidade):
   - novos profiles:
     - `configs/combat/profiles/hostile_light_profile_v1.tres`
     - `configs/combat/profiles/hostile_brute_profile_v1.tres`
   - novos actions:
     - `configs/combat/hostile_light_attack_v1.tres` (`max_targets_per_attack=1`)
     - `configs/combat/hostile_brute_attack_v1.tres` (`max_targets_per_attack=2`)
   - novas cenas derivadas do template:
     - `cenas/enemies/hostile_enemy_light.tscn`
     - `cenas/enemies/hostile_enemy_brute.tscn`
   - validacao MCP: `play_scene + get_godot_errors` sem erro novo de parse/runtime.
16. Validacao isolada do Brute (telemetria concreta):
   - engage confirmado: `target_acquired` + `AcquireCombatTargetInGroup SUCCESS`.
   - loop de combate confirmado: `attack_started -> attack_commit -> attack_pending -> attack_finished`.
   - recebeu dano de forma consistente (`hit_confirmed`) e completou ciclo de morte (`target_lost/chase_canceled/target_died`).
   - metricas observadas no runtime:
     - `attack_stop_distance = 21.8`
     - `reacquire interval_sec = 0.2`
   - leitura: comportamento coerente para archetype pesado (cadencia mais lenta e aproximacao mais curta que Light).
17. Validacao isolada do Light (telemetria concreta):
   - engage confirmado: `target_acquired` + `AcquireCombatTargetInGroup SUCCESS`.
   - loop de combate confirmado: `attack_started -> attack_commit -> attack_pending -> attack_finished`.
   - recebeu dano de forma consistente (`hit_confirmed`) e completou ciclo de morte (`target_lost/chase_canceled/target_died`).
   - metricas observadas no runtime:
     - `attack_stop_distance = 24.2`
     - `reacquire interval_sec = 0.14`
   - leitura: comportamento coerente para archetype leve (reacquire mais rapido e alcance efetivo de parada maior que Brute).
18. Nota operacional de coleta:
   - lote mais recente veio misturado (predominancia de eventos do Brute), portanto nao usado para recalibrar Light;
   - baseline Light mantido com base no lote isolado anterior validado.
19. Ciclo Light-T1 aplicado (Targeting only):
   - profile: `configs/combat/profiles/hostile_light_profile_v1.tres`
   - `acquire_radius: 84.0` (mantido)
   - `lose_radius: 120.0 -> 126.0`
   - `target_memory_sec: 0.55 -> 0.65`
   - `reacquire_interval_sec: 0.14 -> 0.16`
   - `attack_stop_buffer: 3.8` (mantido, sem mudanca de eixo)
   - objetivo: reduzir churn de reacquire e perda precoce de alvo sem alterar cadence/approach.
   - gate MCP: `open_scene + play_scene + get_godot_errors` sem erro novo de parse/runtime.
20. Ciclo Light-T2 aplicado (Approach/Stop only):
   - profile: `configs/combat/profiles/hostile_light_profile_v1.tres`
   - `attack_stop_buffer: 3.8 -> 4.2`
   - targeting mantido do T1:
     - `acquire_radius: 84.0`
     - `lose_radius: 126.0`
     - `target_memory_sec: 0.65`
     - `reacquire_interval_sec: 0.16`
   - leitura de telemetria:
     - `attack_stop_distance: 24.2 -> 23.8`
     - ciclo de combate preservado sem erro novo.
21. Ciclo Light-T3 aplicado (Cadence only):
   - action: `configs/combat/hostile_light_attack_v1.tres`
   - `recover_sec: 0.20 -> 0.22`
   - `cooldown_sec: 0.28 -> 0.32`
   - sem mudanca de targeting/approach.
   - leitura de telemetria:
     - ritmo de commits mais limpo (menos pressao entre ataques),
     - loop funcional mantido (`attack_pending/finished` coerentes),
     - sem erro novo de parse/runtime.
22. Ciclo Light-T4 aplicado (Survivability only):
   - cena: `cenas/enemies/hostile_enemy_light.tscn`
   - `max_health: 14.0 -> 13.0`
   - sem mudanca de targeting/approach/cadence.
   - objetivo: reduzir TTK defensivo do Light para reforcar arquétipo leve/agressivo.
   - gate MCP: `open_scene + play_scene + get_godot_errors` sem erro novo de parse/runtime.
23. Light v1 congelado (baseline final aprovado):
   - profile final: `lose_radius=126.0`, `target_memory_sec=0.65`, `reacquire_interval_sec=0.16`, `attack_stop_buffer=4.2`.
   - action final: `recover_sec=0.22`, `cooldown_sec=0.32`, `damage=0.85`.
   - survivability final: `max_health=13.0` na cena `hostile_enemy_light.tscn`.
   - fase concluida e mantida como baseline.
24. Brute v1 congelado (baseline final aprovado):
   - profile final:
     - `acquire_radius=100.0`
     - `lose_radius=146.0`
     - `target_memory_sec=0.95`
     - `reacquire_interval_sec=0.20`
     - `attack_stop_buffer=6.6`
   - action final:
     - `attack_range=50.0`
     - `windup_sec=0.18`
     - `active_sec=0.12`
     - `recover_sec=0.32`
     - `cooldown_sec=0.46`
     - `damage=1.25`
     - `max_targets_per_attack=2`
   - leitura final: archetype pesado mantido com cadencia mais controlada e letalidade ajustada.
25. Proximo passo de producao:
   - criar proximo hostil por dados (sem tocar logica) usando `docs/enemy-profile-checklist-v1.md`.
26. Baseline stamina v1 fechado (telemetria isolada):
   - regra de fase: sem profile de orb por archetype (orb global unica).
   - diferenciacao por `CombatActionData.stamina_cost`.
   - valores aprovados:
     - `hostile_light_attack_v1.stamina_cost = 14.0` (`spent_ratio=0.14`)
     - `wildcat_claw_attack_v1.stamina_cost = 20.0` (`spent_ratio=0.20`)
     - `hostile_brute_attack_v1.stamina_cost = 28.0` (`spent_ratio=0.28`)
   - fluxo validado por logs: `consumed -> exhausted -> orb_pulse -> staggered -> recovered`.

## Freeze total de tuning tatico (2026-05-11)
O baseline aprovado pelo QA inclui ajustes manuais recentes de cena e tuning:

1. NavMesh/NavPolygon da arena de teste ajustado para a batalha atual.
2. Regen de stamina ajustado para favorecer ciclos de reposicionamento.
3. Walk do Player sem loop no estado visual atual aprovado.
4. Brute/Light/Player mantidos como referencia de ritmo tatico.
5. Distancia atual de kiting visualmente aprovada, embora ainda exista divida tecnica para migrar o valor hardcoded para dado.

Regra: qualquer alteracao futura nesses pontos deve registrar eixo de tuning, resultado observado e telemetria antes/depois.

## Kiting Data-Driven v1 (2026-05-11)
Sprint: `plano-sprint-kiting-datadriven-v1-2026-05-11.md`

Mudanca:
1. `bt_get_kite_position.gd` deixou de usar distancia hardcoded.
2. Distancia de kite passa a vir de `CombatActionData.low_stamina_kite_distance`.
3. `bt_is_stamina_low.gd` removeu o export morto `threshold_ratio`.
4. `bt_move_to_blackboard_pos.gd` permaneceu intocado.

Valores implementados:

| Archetype | Action data | Kite Distance |
|---|---|---:|
| Player | `player_light_attack.tres` | 140.0 |
| Brute | `hostile_brute_attack_v1.tres` | 110.0 |
| Light | `hostile_light_attack_v1.tres` | 120.0 |
| Wildcat | `wildcat_claw_attack_v1.tres` | 130.0 |

Validacao tecnica:
1. `open_scene(res://cenas/mundo.tscn)` executado.
2. `play_scene(current)` executado.
3. `get_godot_errors` sem erro novo de parse/runtime.

QA final:
1. spam de clique no Brute aprovado sem quebra de kiting;
2. clique no chao continua cancelando combate;
3. telemetria confirmou ciclo `low_stamina_entered -> kiting_started -> kiting_ended -> attack_commit`;
4. sem regressao visual de passinhos curtos.
