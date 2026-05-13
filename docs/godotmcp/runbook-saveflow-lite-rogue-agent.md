# Runbook: SaveFlow Lite no Rogue Agent

## Objetivo
Orientar integracoes com o SaveFlow Lite sem quebrar os contratos congelados do Rogue Agent.

Este runbook vale para a sprint:
- `Cliente/nexus/docs/plano-sprint-saveflow-lite-persistence-v1-2026-05-13.md`

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

## Criterio Anti-Drift
Quando houver conflito:
1. Freeze V14 vence para Dynamic Loot/DEX.
2. Freeze V13 vence para ponte ExpressoBits/Adapter.
3. Este runbook vence para persistencia SaveFlow no Rogue Agent.

