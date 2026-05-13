# Plano Sprint - Kite Distance Fine Tuning V14.2

Data: 2026-05-13
Status: CONCLUIDA - MICRO FREEZE V14.2
Branch: `feat/dynamic-loot-dex-v1`
Base obrigatoria: `status-freeze-funcional-v14-dynamic-loot-dex-2026-05-13.md`

## 1) Objetivo
Reduzir a distancia de kiting de baixa stamina porque o recuo aprovado em V14.1 ficou longo demais para a escala atual da arena e do combate.

Esta sprint nao altera BT, HSM, scripts de combat, scripts de stamina, scripts de pathfinding nem `Actor8DirLimbo`.

## 2) Diagnostico
Valores anteriores:

1. Player: `140.0`.
2. Wildcat: `130.0`.
3. HostileEnemyBase: `130.0`.
4. HostileEnemyLight: `120.0`.
5. HostileEnemyBrute: `110.0`.

Com `attack_stop_distance` real entre aproximadamente `23.0` e `34.0`, os atores estavam recuando perto de 3x-5x a distancia de reengajamento, criando uma luta mais elastica que o desejado.

## 3) Decisao Tecnica
Aplicar ajuste conservador somente em dados:

1. Player: `95.0`.
2. Wildcat: `80.0`.
3. HostileEnemyBase: `85.0`.
4. HostileEnemyLight: `80.0`.
5. HostileEnemyBrute: `70.0`.

Fontes de dados:

1. Player:
   - `res://configs/items/inventory/nexus_inventory_database_v1.tres`;
   - item `weapon_dagger_starter`;
   - propriedade `combat_low_stamina_kite_distance = 95.0`.
2. Hostis:
   - `wildcat_claw_attack_v1.tres`;
   - `hostile_base_attack_v1.tres`;
   - `hostile_light_attack_v1.tres`;
   - `hostile_brute_attack_v1.tres`.

## 4) Criterios De Aceite
1. `mundo.tscn` abre e roda sem parse/runtime error novo.
2. Player continua usando ExpressoBits -> `NexusEquipmentAdapter` -> `CombatActionData` em memoria.
3. Hostis continuam usando `CombatActionData` `.tres`.
4. Logs continuam mostrando:
   - `attack_stamina_cost`;
   - `hit_confirmed`;
   - `hit_reaction_requested`;
   - `kiting_started` / `kiting_holding` / `kiting_ended` quando baixa stamina ocorrer.
5. `out_of_range` pode aparecer durante reengajamento, mas deve ser curto e seguido de novo `status = success`.

## 5) Resultado
Concluido em 2026-05-13.

Alteracoes aplicadas via Godot MCP/editor API:

1. `weapon_dagger_starter`
   - `combat_low_stamina_kite_distance: 140.0 -> 95.0`.
2. `wildcat_claw_attack_v1.tres`
   - `low_stamina_kite_distance: 130.0 -> 80.0`.
3. `hostile_base_attack_v1.tres`
   - `low_stamina_kite_distance: 130.0 -> 85.0`.
4. `hostile_light_attack_v1.tres`
   - `low_stamina_kite_distance: 120.0 -> 80.0`.
5. `hostile_brute_attack_v1.tres`
   - `low_stamina_kite_distance: 110.0 -> 70.0`.

Limpeza anti-drift:

1. `res://configs/combat/player_light_attack.tres` foi auditado como recurso legado morto.
2. Nenhuma cena, script ou resource ativo referencia `player_light_attack.tres`.
3. O Player atual consome a database ExpressoBits (`weapon_dagger_starter`) e gera `CombatActionData` em memoria pelo `NexusEquipmentAdapter`.
4. O arquivo legado foi removido para evitar tuning fantasma.
5. O fallback de `NexusEquipmentAdapter` para `combat_low_stamina_kite_distance` foi alinhado de `140.0` para `95.0`.

Validacao:

1. `res://cenas/mundo.tscn` abriu e rodou.
2. `get_godot_errors` nao reportou parse/runtime error novo.
3. Script de validacao confirmou:
   - Player: `95.0`;
   - Wildcat: `80.0`;
   - HostileEnemyBase: `85.0`;
   - HostileEnemyLight: `80.0`;
   - HostileEnemyBrute: `70.0`.
4. Telemetria confirmou ponte V14 do Player:
   - `inventory_add_requested`;
   - `inventory_item_added`;
   - `inventory_equipment_adapter_resolved` com `resource_path = "memory_generated"`.
5. Logs de combate confirmaram `hit_confirmed`, `hit_reaction_requested`, stamina e reengajamento sem erro novo.
6. Auditoria `rg` confirmou que `player_light_attack.tres` nao era usado por cena/script/resource ativo antes da remocao.

## 6) Proxima Validacao Visual
O diretor deve testar duelos contra Wildcat, Base, Light e Brute. Se ainda parecer longo:

1. reduzir mais `10 px` por arquétipo;
2. nao alterar BT/HSM;
3. preservar a diferenca relativa:
   - Brute recua menos;
   - Wildcat/Light recuam curto;
   - Player recua um pouco mais por leitura visual.
