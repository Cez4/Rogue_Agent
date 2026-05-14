# Runbook: SaveFlow Lite no Rogue Agent

## Objetivo
Orientar integracoes com o SaveFlow Lite sem quebrar os contratos congelados do Rogue Agent.

Este runbook vale para a sprint:
- `Cliente/nexus/docs/plano-sprint-saveflow-lite-persistence-v1-2026-05-13.md`
- `Cliente/nexus/docs/plano-sprint-saveflow-slots-host-authority-v1-2026-05-13.md`
- `Cliente/nexus/docs/plano-sprint-saveflow-ui-dev-panel-v1-2026-05-13.md`
- `Cliente/nexus/docs/status-freeze-funcional-v17-saveflow-ui-dev-panel-2026-05-13.md`
- `Cliente/nexus/docs/status-freeze-funcional-v16-saveflow-slots-host-authority-2026-05-13.md`
- `Cliente/nexus/docs/status-freeze-funcional-v15-saveflow-lite-persistence-2026-05-13.md`

## Regra Principal
SaveFlow Lite e orquestrador de persistencia. Ele nao substitui:
1. ExpressoBits Inventory System;
2. NexusInventoryAuthority;
3. NexusInventoryBridgeComponent;
4. NexusEquipmentAdapter;
5. BT/HSM de combate.

## Contrato Do Inventario V13/V14
O inventario persistido deve preservar exatamente este caminho:

`InventoryDatabase -> InventoryBridge -> ItemStack.item_id/properties -> NexusEquipmentAdapter -> EquipmentLoadout/WeaponData/CombatActionData em memoria`.

Regras obrigatorias:
1. Nao salvar `ItemDefinition` dentro do stack.
2. Nao ler nem escrever `stack.item`.
3. Salvar somente dados serializaveis e estaveis:
   - `item_id`;
   - `amount`;
   - `properties`.
4. Dados rolados de item vivem em `ItemStack.properties`.
5. O load precisa restaurar o stack antes do adapter resolver equipamento.

## Autoridade Co-op
O Rogue Agent e co-op com autoridade no host.

Regras:
1. Apenas host salva/carrega estado autoritativo de gameplay.
2. Cliente nao deve chamar save/load autoritativo de inventario, quests ou mundo.
3. Em modo offline/dev, a instancia local e tratada como host.
4. Qualquer UI de save deve chamar uma fachada/authority do Nexus, nao manipular SaveFlow diretamente em gameplay multiplayer.

Fachada congelada em V16:
1. `NexusSaveAuthority` deve ser a unica entrada de save/load de gameplay.
2. UI/dev commands chamam `NexusSaveAuthority`.
3. `NexusSaveAuthority` chama SaveFlow depois de validar autoridade.
4. Sources continuam donos da serializacao por dominio.
5. Slot default aprovado: `profile_0`.
6. Smoke aprovado: `save_authority_smoke_result ok=true payload_restored=true slot_summary_ok=true`.

UI dev congelada em V17:
1. `SaveFlowDevPanel` chama `NexusSaveAuthority`, nunca SaveFlow direto.
2. O painel salva, carrega e consulta `profile_0`.
3. O painel nao e UI final e nao mexe em inventario diretamente.
4. Qualquer botao emite telemetria propria e preserva eventos da authority.
5. Smoke aprovado: `saveflow_dev_panel_smoke_result ok=true`.
6. Runner de smoke do painel nao deve ficar como node salvo na cena final.

## Escolha De Fonte SaveFlow
Use:
1. `SaveFlowDataSource` para inventario, quest manager, world flags e registries.
2. `SaveFlowTypedDataSource` para modelos simples com campos exportados.
3. `SaveFlowEntityCollectionSource` para drops no chao, inimigos persistentes e entidades runtime.
4. `SaveFlowNodeSource` apenas quando um objeto de cena e claramente dono do proprio estado.

Evite:
1. varrer o Player inteiro com `NodeSource` para salvar inventario;
2. salvar a mesma subtree por duas fontes;
3. salvar containers runtime tambem possuidos por `EntityCollectionSource`;
4. salvar UI que pode ser reconstruida por dados de gameplay.

## Ordem Segura De Load
Para inventario do Player:
1. Instanciar/criar o bridge.
2. Carregar payload salvo no bridge.
3. Marcar que starting items nao devem rerollar se save valido foi aplicado.
4. Resolver `get_equipment_loadout_runtime()`.
5. Atualizar HUD/orbs se necessario.

Nunca aplicar `starting_items` antes de tentar carregar um save valido.

## O Que Nao Persistir
Nao persistir:
1. estado atual de BT;
2. estado atual de HSM;
3. frames de animacao;
4. hit reaction ativo;
5. knockback ativo;
6. alvo de combate temporario;
7. telemetria/debug temporario;
8. caches de adapter que podem ser reconstruidos.

## Gate MCP Obrigatorio
Antes de commitar qualquer integracao SaveFlow:
1. `open_scene res://cenas/mundo.tscn`;
2. `play_scene`;
3. `get_godot_errors`;
4. validar telemetria de inventario;
5. salvar slot;
6. reiniciar/load;
7. provar que o item rolado nao rerollou.

## Smoke Runner
O projeto possui um runner de QA runtime:
- `res://Scripts/save/debug/saveflow_inventory_smoke_runner.gd`
- `res://Scripts/debug/saveflow_dev_panel_smoke_runner.gd`

Uso:
1. Anexar temporariamente em `mundo.tscn`.
2. Rodar a cena.
3. Conferir `saveflow_inventory_smoke_result`.
4. Remover o node temporario antes de salvar/congelar a cena final.

Resultado aprovado no V15:
1. `ok = true`.
2. `payload_restored = true`.
3. `stack_count = 1`.
4. `item_id = weapon_dagger_starter`.
5. `rolled_damage` e `rolled_dex_bonus` preservados.

Resultado aprovado no V17:
1. `saveflow_dev_panel_smoke_result ok=true`.
2. `saveflow_dev_panel_save_clicked`.
3. `save_authority_save_completed ok=true`.
4. `saveflow_dev_panel_load_clicked`.
5. `save_authority_load_completed ok=true`.
6. `saveflow_dev_panel_summary_clicked`.
7. `inventory_equipment_adapter_resolved resource_path=memory_generated`.

## Criterio Anti-Drift
Quando houver conflito:
1. Freeze V17 vence para SaveFlow UI Dev Panel.
2. Freeze V16 vence para SaveFlow Slots & Host Authority.
3. Freeze V14 vence para Dynamic Loot/DEX.
4. Freeze V13 vence para ponte ExpressoBits/Adapter.
5. Freeze funcional V15 vence para persistencia de inventario com SaveFlow.
6. Este runbook vence para persistencia SaveFlow no Rogue Agent.
