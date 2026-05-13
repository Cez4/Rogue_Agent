# Status Freeze Operacional V15: SaveFlow Lite Prep

Data: 2026-05-13
Status: congelado como preparacao operacional, sem runtime de persistencia implementado.
Branch: `feat/dynamic-loot-dex-v1`
Base obrigatoria:
1. `status-freeze-funcional-v14-dynamic-loot-dex-2026-05-13.md`
2. `plano-sprint-saveflow-lite-persistence-v1-2026-05-13.md`
3. `docs/godotmcp/runbook-saveflow-lite-rogue-agent.md`

## Resumo Executivo
O projeto recebeu o **SaveFlow Lite** e congelou a diretriz de integracao antes de alterar runtime de gameplay.

Este freeze nao declara inventario persistente funcional ainda. Ele congela:
1. plugin instalado;
2. autoload `SaveFlow` ativo;
3. plano doc-first da sprint de persistencia;
4. runbook do Rogue Agent para SaveFlow;
5. regra de que SaveFlow orquestra persistencia, mas nao substitui ExpressoBits nem a ponte V13/V14.

## Estado Instalado
Arquivos adicionados pelo plugin:
1. `res://addons/saveflow_core/`
2. `res://addons/saveflow_lite/`

`project.godot` agora possui:
1. autoload `SaveFlow`;
2. plugin `res://addons/saveflow_lite/plugin.cfg` habilitado.

O editor exibiu a aba `SaveFlow Settings`, confirmando a instalacao visual do plugin.

## Contrato Congelado Para A Proxima Sprint
SaveFlow Lite deve ser usado como camada de orquestracao de save/load por dominios.

Ele nao substitui:
1. `NexusInventoryAuthority`;
2. `NexusInventoryBridgeComponent`;
3. `NexusEquipmentAdapter`;
4. ExpressoBits Inventory System;
5. BT/HSM de combate;
6. `ActorCombatProfileRuntime`;
7. `get_equipment_loadout_runtime()`.

## Inventario V13/V14 Preservado
O caminho oficial continua:

`InventoryDatabase -> InventoryBridge -> ItemStack.item_id/properties -> NexusEquipmentAdapter -> EquipmentLoadout/WeaponData/CombatActionData em memoria`.

Regras obrigatorias:
1. Persistir apenas `item_id`, `amount` e `properties`.
2. Nunca salvar `ItemDefinition` dentro do stack.
3. Nunca usar `stack.item`.
4. Nunca inserir stack via `.append()` em `inventory.stacks`.
5. Load valido deve impedir reroll de `starting_items`.
6. Host e o unico autor de save/load de gameplay em co-op.

## Evidencia MCP
Validacao executada via Godot MCP:
1. Godot version: `4.6.2-stable`.
2. Cena aberta: `res://cenas/mundo.tscn`.
3. `project.godot` mostrou `SaveFlow` em `[autoload]`.
4. `project.godot` mostrou `res://addons/saveflow_lite/plugin.cfg` em `[editor_plugins]`.
5. `get_godot_errors` retornou: `Session has no errors`.

Observacao: play/smoke completo de save/load ainda pertence a Fase A final e Fase D/E do plano V15. Nao foi declarado como pronto neste freeze.

## Proximo Passo Seguro
Iniciar a sprint `SaveFlow Lite Persistence v1` pela Fase A final:
1. rodar `open_scene -> play_scene -> get_godot_errors`;
2. criar `NexusInventorySaveSource`;
3. salvar slot local;
4. reiniciar/carregar;
5. provar que a adaga starter mantem o mesmo `rolled_damage` e `rolled_dex_bonus`.

