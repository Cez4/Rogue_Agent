# Plano Sprint - Balance Scale V14.1

Data: 2026-05-13
Status: CONCLUIDA - MICRO FREEZE V14.1
Branch: `feat/dynamic-loot-dex-v1`
Base obrigatoria: `status-freeze-funcional-v14-dynamic-loot-dex-2026-05-13.md`

## 1) Objetivo
Alinhar os combatentes restantes ao novo padrao numerico de RPG aprovado apos V14, preservando o mesmo sentimento de hits-to-kill do combate tatico.

Esta sprint nao muda arquitetura. Hostis continuam usando `CombatActionData` `.tres`; Player continua usando ExpressoBits -> `NexusEquipmentAdapter` -> `CombatActionData` em memoria.

## 2) Contexto
O balance V14 escalou numeros para evitar casas decimais pequenas:

1. Player: `max_health = 70`.
2. Brute: `max_health = 75`, `damage = 6`.
3. Light: `max_health = 50`, `damage = 4`.
4. Dagger level 1: rolagem `4-6` pela database ExpressoBits.

Pontos fora de escala:

1. Wildcat ainda estava com `max_health = 14`.
2. HostileEnemyBase ainda estava com `max_health = 14`.
3. HostileEnemyBase ainda apontava para `wildcat_claw_attack_v1.tres`, que nao define `damage` e cai no default `1.0`.
4. Wildcat tambem nao tinha `damage` explicito em `wildcat_claw_attack_v1.tres`, entao continuava causando `1.0` apesar do HP ja estar na escala nova.

Com dagger level 1 causando em media `5`, esses atores morrem em poucos hits e quebram a nova escala.

## 3) Decisao Tecnica
Alterar HP e corrigir o tuning data-driven do Base:

1. Wildcat: `max_health = 50`.
2. HostileEnemyBase: `max_health = 50`.
3. HostileEnemyBase: criar `hostile_base_attack_v1.tres` e apontar `AttackState.action_data` para ele.
4. Wildcat: manter o mesmo `wildcat_claw_attack_v1.tres`, mas explicitar `damage = 4.0`.

Nao alterar agora:

1. BT/HSM;
2. scripts de stamina;
3. scripts de kiting;
4. hit reaction;
5. knockback component;
6. ExpressoBits adapter.

Decisao de tuning do Base:

1. `hostile_base_attack_v1.tres` preserva o ritmo que o Base herdava do Wildcat:
   - `windup_sec = 0.14`;
   - `active_sec = 0.09`;
   - `recover_sec = 0.24`;
   - `cooldown_sec = 0.36`;
   - `stamina_cost = 20.0`;
   - `low_stamina_kite_distance = 130.0`;
   - `knockback_force = 200.0`.
2. O dano foi alinhado para `damage = 5.0`, entre Light (`4.0`) e Brute (`6.0`).
3. A correcao e data-driven: nenhum script de combate foi alterado.

Decisao de tuning do Wildcat:

1. `wildcat_claw_attack_v1.tres` preserva a cadencia agressiva ja aprovada:
   - `windup_sec = 0.14`;
   - `active_sec = 0.09`;
   - `recover_sec = 0.24`;
   - `cooldown_sec = 0.36`;
   - `stamina_cost = 20.0`;
   - `low_stamina_kite_distance = 130.0`;
   - `knockback_force = 200.0`.
2. O dano foi alinhado para `damage = 4.0`, igual ao Light, para manter o Wildcat como ameaca agil sem superar o Base.
3. A correcao e data-driven: nenhum script de combate foi alterado.

## 4) Criterios De Aceite
1. Cenas abrem no Godot sem erro.
2. `mundo.tscn` roda sem parse/runtime novo.
3. Player segue emitindo dano pela ponte V14.
4. Hostis seguem usando `.tres`.
5. Logs continuam exibindo combate, hit reaction, kiting/stamina e hitbreak quando aplicavel.

## 5) Resultado
Concluido em 2026-05-13.

Alteracoes aplicadas via Godot MCP/editor API:

1. `res://cenas/wildcat_1.tscn`
   - `Health.max_health = 50.0`.
2. `res://configs/combat/wildcat_claw_attack_v1.tres`
   - `damage = 4.0`;
   - `stamina_cost = 20.0`;
   - `knockback_force = 200.0`;
   - `low_stamina_kite_distance = 130.0`.
3. `res://cenas/enemies/hostile_enemy_base.tscn`
   - `Health.max_health = 50.0`.
   - `LimboHSM/AttackState.action_data = res://configs/combat/hostile_base_attack_v1.tres`.
4. `res://configs/combat/hostile_base_attack_v1.tres`
   - novo `CombatActionData` dedicado do Base;
   - `damage = 5.0`;
   - `stamina_cost = 20.0`;
   - `knockback_force = 200.0`;
   - `low_stamina_kite_distance = 130.0`.
5. `res://cenas/player.tscn`
   - `Health.max_health = 70.0`.

Validacao:

1. `res://cenas/mundo.tscn` abriu e rodou.
2. `get_godot_errors` nao reportou parse/runtime error novo.
3. Telemetria confirmou ponte V14 do Player:
   - `inventory_add_requested`;
   - `inventory_item_added`;
   - `inventory_equipment_adapter_resolved` com `resource_path = "memory_generated"`.
4. Propriedades em runtime confirmadas:
   - Player: `max_health = 70.0`;
   - Wildcat: `max_health = 50.0`;
   - HostileEnemyBase: `max_health = 50.0`;
   - HostileEnemyLight: `max_health = 50.0`;
   - HostileEnemyBrute: `max_health = 75.0`.
5. Runtime confirmou que `HostileEnemyBase/LimboHSM/AttackState.action_data` carrega `res://configs/combat/hostile_base_attack_v1.tres`.
6. Recurso carregado via Godot MCP confirmou:
   - `damage = 5.0`;
   - `stamina_cost = 20.0`;
   - `attack_range = 48.0`;
   - `low_stamina_kite_distance = 130.0`;
   - `knockback_force = 200.0`.
7. QA log posterior confirmou `HostileEnemyBase` acertando Player com `damage = 5.0` e Player sobrevivendo com margem menor, alinhado ao objetivo de disputa mais tensa.
8. Runtime confirmou que `Wildcat/LimboHSM/AttackState.action_data` carrega `res://configs/combat/wildcat_claw_attack_v1.tres`.
9. Recurso carregado via Godot MCP confirmou:
   - `damage = 4.0`;
   - `stamina_cost = 20.0`;
   - `attack_range = 48.0`;
   - `low_stamina_kite_distance = 130.0`;
   - `knockback_force = 200.0`.

Contrato preservado:

1. Hostis continuam usando `CombatActionData` `.tres`.
2. Player continua usando ExpressoBits via adapter runtime.
3. Nenhum script de BT/HSM/stamina/kiting/dano foi alterado.
