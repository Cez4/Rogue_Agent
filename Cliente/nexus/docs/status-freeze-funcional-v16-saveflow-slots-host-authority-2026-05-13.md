# Status Freeze Funcional V16: SaveFlow Slots & Host Authority

Data: 2026-05-13
Status: aprovado em QA MCP/log e congelado.
Branch: `feat/saveflow-slots-host-authority-v1`
Base obrigatoria:
1. `status-freeze-funcional-v15-saveflow-lite-persistence-2026-05-13.md`
2. `plano-sprint-saveflow-slots-host-authority-v1-2026-05-13.md`
3. `docs/godotmcp/runbook-saveflow-lite-rogue-agent.md`

## Resumo Executivo
O Rogue Agent agora possui uma fachada oficial para save/load de gameplay com SaveFlow Lite:

`NexusSaveAuthority`

V15 provou que o inventario do Player salva/carrega. V16 transforma isso em um contrato jogavel: nenhum sistema de UI/dev/gameplay deve chamar SaveFlow direto para estado autoritativo. O fluxo passa pela authority Nexus, que valida host/local, resolve slot e chama `SaveFlow.save_scope()`/`SaveFlow.load_scope()`.

## O Que Foi Implementado
1. `res://Scripts/save/nexus_save_authority.gd`
   - `class_name NexusSaveAuthority`;
   - slot default `profile_0`;
   - `save_player_slot(slot_id := "")`;
   - `load_player_slot(slot_id := "")`;
   - `read_player_slot_summary(slot_id := "")`;
   - `has_player_slot(slot_id := "")`;
   - guard host-authoritative com offline/dev local permitido.

2. `res://cenas/mundo.tscn`
   - adicionou node permanente `NexusSaveAuthority`;
   - `player_path = ../Player`;
   - nao alterou Player, BT, HSM, combate ou inventario V13/V14.

3. `res://Scripts/save/debug/saveflow_authority_smoke_runner.gd`
   - runner de QA runtime;
   - usado para provar save/load via `NexusSaveAuthority`;
   - nao fica anexado na cena final.

## Evidencia MCP / Telemetria
Smoke runtime executado em `res://cenas/mundo.tscn`:
1. Player iniciou com `weapon_dagger_starter`.
2. Adapter confirmou `inventory_equipment_adapter_resolved resource_path=memory_generated`.
3. Authority emitiu `save_authority_save_requested`.
4. SaveFlow emitiu `saveflow_inventory_gathered`.
5. Authority emitiu `save_authority_save_completed ok=true`.
6. Runner removeu a dagger via `request_remove_item`.
7. Authority emitiu `save_authority_load_requested`.
8. SaveFlow emitiu `saveflow_inventory_applied`.
9. Authority emitiu `save_authority_load_completed ok=true` com:
   - `stack_count = 1`;
   - `item_id = weapon_dagger_starter`;
   - `rolled_damage = 5`;
   - `rolled_dex_bonus = 3`.
10. Runner emitiu `save_authority_smoke_result` com:
   - `ok = true`;
   - `payload_restored = true`;
   - `slot_summary_ok = true`;
   - `rarity = rare`.

Gate final depois de remover o runner temporario:
1. `mundo.tscn` abriu e rodou.
2. Nao houve parse/runtime error novo.
3. Player continuou gerando starter item normalmente quando nao ha load chamado.
4. Adapter continuou resolvendo equipamento em memoria.
5. `rg` confirmou que `SaveFlowAuthoritySmokeRunner` nao ficou em cena.

## Contrato Congelado
1. `NexusSaveAuthority` e a unica entrada oficial para save/load de gameplay.
2. UI futura deve chamar `NexusSaveAuthority`, nao SaveFlow direto.
3. Cliente sem autoridade nao deve salvar/carregar estado autoritativo.
4. Offline/dev local e tratado como host.
5. SaveFlow continua sendo orquestrador.
6. `PlayerInventorySource` continua dono da serializacao do inventario.
7. `NexusInventoryBridgeComponent` continua dono da hidratacao do inventario.
8. `NexusEquipmentAdapter` continua traduzindo item persistido para runtime de combate.
9. `ItemStack.item_id` e `ItemStack.properties` continuam sendo o contrato persistido.
10. `stack.item` e `.append()` em stacks continuam proibidos.

## Limites Do Freeze
Concluido:
1. Authority de save/load.
2. Slot default `profile_0`.
3. Smoke de save/load via authority.
4. Consulta runtime de slot summary.

Ainda fora do escopo:
1. UI final de save/load.
2. autosave/checkpoint.
3. quests/world flags.
4. runtime entity collections.
5. sincronizacao completa com SpacetimeDB.
6. save/load de cliente remoto.

## Proxima Sprint Recomendada
`SaveFlow UI Dev Panel v1`:
1. criar painel dev simples para salvar/carregar `profile_0`;
2. listar slot summary via `NexusSaveAuthority`;
3. mostrar status de sucesso/erro;
4. manter UI como cliente de authority, sem chamar SaveFlow direto.
