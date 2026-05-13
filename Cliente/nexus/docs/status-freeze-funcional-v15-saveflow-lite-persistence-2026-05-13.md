# Status Freeze Funcional V15: SaveFlow Lite Persistence

Data: 2026-05-13
Status: aprovado em QA MCP/log e congelado.
Branch: `feat/saveflow-lite-persistence-v1`
Base obrigatoria:
1. `status-freeze-operacional-v15-saveflow-lite-prep-2026-05-13.md`
2. `status-freeze-funcional-v14-dynamic-loot-dex-2026-05-13.md`
3. `status-freeze-funcional-v13-inventory-datadriven-core-2026-05-13.md`

## Resumo Executivo
O Rogue Agent agora possui a primeira persistencia funcional com **SaveFlow Lite** para o inventario do Player.

O objetivo aprovado foi restrito e seguro:
1. salvar inventario runtime do Player;
2. carregar o mesmo inventario pelo grafo SaveFlow;
3. preservar `ItemStack.item_id` e `ItemStack.properties`;
4. impedir drift/reroll quando um save valido e aplicado;
5. manter a ponte V13/V14 intacta.

## O Que Foi Implementado
1. `res://Scripts/save/nexus_inventory_save_source.gd`
   - `@tool`;
   - `extends SaveFlowDataSource`;
   - usa `NexusInventoryBridgeComponent.serialize_inventory()`;
   - usa `NexusInventoryBridgeComponent.apply_loaded_inventory(data)`;
   - emite `saveflow_inventory_gathered`, `saveflow_inventory_applied` e `saveflow_inventory_rejected`.

2. `res://cenas/player.tscn`
   - adicionou `SaveGraphRoot` com script `SaveFlowScope`;
   - adicionou `PlayerInventorySource` com script `NexusInventorySaveSource`;
   - `PlayerInventorySource.bridge_path = ../../InventoryBridge`;
   - nao varre o Player inteiro com `NodeSource`.

3. `NexusInventoryBridgeComponent`
   - adicionou `apply_loaded_inventory(data)`;
   - adicionou `apply_starting_items_if_empty()`;
   - invalida o runtime de equipamento apos add/remove/transfer/load;
   - preserva `NexusInventoryAuthority` como rota de mutacao em gameplay.

4. `Actor8DirLimbo`
   - adicionou fachada minima `invalidate_equipment_loadout_runtime()`;
   - nao alterou BT/HSM/combat core.

5. `res://Scripts/save/debug/saveflow_inventory_smoke_runner.gd`
   - runner de QA runtime, nao anexado em cena final;
   - usado para provar save/load por `SaveFlow.save_scope()` e `SaveFlow.load_scope()`.

## Evidencia MCP / Telemetria
Smoke runtime executado em `res://cenas/mundo.tscn`:
1. Player iniciou com `inventory_item_added` para `weapon_dagger_starter`.
2. `inventory_equipment_adapter_resolved` confirmou `resource_path = memory_generated`.
3. `saveflow_inventory_gathered` confirmou:
   - `source = player_inventory_source`;
   - `stack_count = 1`;
   - `payload_keys = ["items"]`.
4. Runner removeu a adaga via `request_remove_item`.
5. `saveflow_inventory_applied` confirmou restore com `stack_count = 1`.
6. `saveflow_inventory_smoke_result` confirmou:
   - `ok = true`;
   - `reason = ok`;
   - `payload_restored = true`;
   - `item_id = weapon_dagger_starter`;
   - `rolled_damage = 5`;
   - `rolled_dex_bonus = 0`;
   - `rarity = normal`;
   - `removed_count = 0`;
   - `stack_count = 1`.

Gate final depois de remover o runner temporario:
1. `mundo.tscn` abriu e rodou.
2. Nao houve parse/runtime error novo.
3. Player continuou gerando starter item normalmente quando nao ha save aplicado.
4. Adapter continuou resolvendo equipamento em memoria.

## Contrato Congelado
1. SaveFlow e orquestrador de persistencia, nao fonte de verdade de item.
2. ExpressoBits continua sendo fonte oficial de moldes (`ItemDefinition`).
3. `ItemStack.properties` continua sendo fonte oficial de rolagens unicas.
4. `NexusEquipmentAdapter` continua sendo tradutor oficial para `EquipmentLoadout`/`WeaponData`/`CombatActionData`.
5. Em co-op, apenas host deve executar save/load autoritativo.
6. Cliente nao deve gravar inventario, quests ou mundo autoritativo.
7. Nao usar `stack.item`.
8. Nao inserir em `inventory.stacks` via `.append()`.
9. Nao salvar estado transiente de BT/HSM/hit reaction/knockback.

## Limites Do Freeze
Concluido:
1. Persistencia funcional do inventario do Player.
2. Prova anti-reroll por payload restaurado.
3. Grafo SaveFlow inicial no Player.

Ainda fora do escopo:
1. UI de save/load.
2. multiplos slots jogaveis.
3. autosave/checkpoint.
4. quest persistence.
5. world flags.
6. runtime entity collections.
7. sync multiplayer de save/load entre host e clientes.

## Proxima Sprint Recomendada
`SaveFlow Slots & Host Authority v1`:
1. criar `NexusSaveAuthority`;
2. criar active slot controlado pelo host;
3. adicionar UI/dev command para save/load manual;
4. impedir chamadas de save/load em cliente sem autoridade;
5. preparar `QuestStateSource` como proximo dominio.
