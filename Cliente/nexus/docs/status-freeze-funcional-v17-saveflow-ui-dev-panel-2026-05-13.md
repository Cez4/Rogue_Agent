# Status Freeze Funcional V17 - SaveFlow UI Dev Panel

Data: 2026-05-13
Branch: `feat/saveflow-ui-dev-panel-v1`
Status: CONGELADO

## Resumo
V17 conclui o painel dev visual para operar o save/load aprovado em V16.

O painel e intencionalmente uma ferramenta dev, nao a UI final de produto. Ele permite acionar Save, Load e Summary do slot `profile_0` sem quebrar a arquitetura co-op/host-authoritative.

## Contrato Congelado
Fluxo aprovado:
```text
SaveFlowDevPanel -> NexusSaveAuthority -> SaveFlow -> PlayerInventorySource -> NexusInventoryBridgeComponent
```

Regras congeladas:
1. `SaveFlowDevPanel` chama somente `NexusSaveAuthority`.
2. Nenhum botao do painel chama SaveFlow direto.
3. O painel nao muta inventario diretamente.
4. O painel nao altera combate, BT, HSM, kiting, dano, stamina ou adapter.
5. `NexusEquipmentAdapter` continua resolvendo equipamento como `memory_generated`.
6. `SaveFlowDevPanelSmokeRunner` e ferramenta de QA manual; nao fica salvo como node na cena final.

## Arquivos Implementados
1. `res://Scripts/debug/saveflow_dev_panel.gd`
2. `res://Scripts/debug/saveflow_dev_panel_smoke_runner.gd`
3. `res://cenas/debug/saveflow_dev_panel.tscn`
4. `res://cenas/mundo.tscn` com instancia permanente `SaveFlowDevPanel`

## Evidencia MCP
Gate visual/log executado em `res://cenas/mundo.tscn`.

Eventos observados:
1. `saveflow_dev_panel_summary_clicked`
2. `saveflow_dev_panel_status_updated command=summary ok=true`
3. `saveflow_dev_panel_save_clicked`
4. `save_authority_save_requested`
5. `save_authority_save_completed ok=true`
6. `saveflow_dev_panel_load_clicked`
7. `save_authority_load_requested`
8. `save_authority_load_completed ok=true`
9. `saveflow_dev_panel_smoke_result ok=true reason=ok`
10. `inventory_equipment_adapter_resolved resource_path=memory_generated`

Gate final sem runner temporario salvo:
1. `mundo.tscn` abriu pelo Godot MCP.
2. `play_scene` rodou.
3. `get_godot_errors` nao apresentou erro novo de parse/runtime.
4. Painel leu `profile_0` via authority.
5. Inventario/equipamento continuaram usando a ponte V13/V14.

## Anti-Drift
Quando houver conflito:
1. Este freeze V17 vence para UI dev de SaveFlow.
2. Freeze V16 vence para autoridade de save/load.
3. Freeze V15 vence para persistencia do inventario.
4. Freeze V14/V13 vencem para ExpressoBits, `ItemStack.item_id/properties` e adapter em memoria.

## Proximo Passo Recomendado
Proxima sprint segura: criar a UI final/fluxo de produto ou expandir SaveFlow para estado estavel do Player, como posicao/vida/world flags, sempre por sources/authorities especificas e sem salvar estado temporario de BT/HSM.
