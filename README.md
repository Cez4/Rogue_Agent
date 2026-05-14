# Rogue Agent - Estado Oficial Atual

Este README aponta a fonte oficial de status tecnico do projeto.

## Fonte oficial de status (freeze atual)
- `Cliente/nexus/docs/status-freeze-funcional-v17-saveflow-ui-dev-panel-2026-05-13.md`

Freezes imediatamente anteriores:
- `Cliente/nexus/docs/status-freeze-funcional-v16-saveflow-slots-host-authority-2026-05-13.md`
- `Cliente/nexus/docs/status-freeze-funcional-v15-saveflow-lite-persistence-2026-05-13.md`
- `Cliente/nexus/docs/status-freeze-operacional-v15-saveflow-lite-prep-2026-05-13.md`
- `Cliente/nexus/docs/status-freeze-funcional-v14-dynamic-loot-dex-2026-05-13.md`
- `Cliente/nexus/docs/status-freeze-funcional-v13-inventory-datadriven-core-2026-05-13.md`
- `Cliente/nexus/docs/status-freeze-funcional-v12-inventory-expresso-spike-2026-05-13.md`
- `Cliente/nexus/docs/status-freeze-funcional-v11-hitbreak-combat-feedback-2026-05-13.md`
- `Cliente/nexus/docs/status-freeze-operacional-v10-combat-core-restored-2026-05-13.md`
- `Cliente/nexus/docs/status-freeze-funcional-v9-hostile-hit-reaction-2026-05-12.md`
- `Cliente/nexus/docs/status-freeze-funcional-v8-wildcat-hit-reaction-2026-05-12.md`
- `Cliente/nexus/docs/status-freeze-funcional-v7-hit-reaction-2026-05-12.md`

Freeze historico base:
- `Cliente/nexus/docs/status-freeze-total-combate-tatico-2026-05-11.md`

Freeze de game feel fisico:
- `Cliente/nexus/docs/status-freeze-funcional-v6-knockback-2026-05-12.md`

Esse documento manda no estado da fase atual e consolida:
1. SaveFlow UI Dev Panel V17 funcional.
2. `SaveFlowDevPanel` opera Save/Load/Summary de `profile_0` via `NexusSaveAuthority`.
3. SaveFlow Slots & Host Authority V16 funcional.
4. `NexusSaveAuthority` e a entrada oficial para save/load de gameplay.
5. SaveFlow Lite Persistence V15 funcional para inventario do Player.
6. Prova anti-reroll aprovada: save/load preserva `ItemStack.item_id/properties`.
7. SaveFlow nao substitui ExpressoBits, `NexusInventoryAuthority`, `NexusInventoryBridgeComponent` nem `NexusEquipmentAdapter`.
8. Co-op segue host-authoritative: host salva/carrega estado autoritativo.
9. Combate tatico BT/LimboAI congelado.
10. Hit Reaction/Hit Interrupt restaurado como core aprovado.
11. Combat Clash temporal removido do runtime.
12. Parry futuro deve ser `DefenseComponent`/`ParryComponent` por chance/atributo, nao `mutual_clash` global.
13. Knockback V6 permanece congelado com `knockback_force = 200.0`.
14. Hit Reaction V7/V8/V9 seguem aprovados para Player, Wildcat e hostis.
15. Hitbreak Combat Feedback V11 segue aprovado para Player, Wildcat, Base, Light e Brute.
16. ExpressoBits Inventory System V12/V13 e a fonte oficial data-driven de inventario/equipamento.
17. Dynamic Loot & DEX V14 gera `EquipmentLoadout`/`CombatActionData` em memoria para o Player.
18. Orb UI, Health Regen fora de combate, stamina/kiting e telemetria continuam preservados.

## Sprint atual congelada
- `Cliente/nexus/docs/plano-sprint-saveflow-ui-dev-panel-v1-2026-05-13.md`
- Branch: `feat/saveflow-ui-dev-panel-v1`

Escopo atual: SaveFlow UI Dev Panel V17 concluido. `SaveFlowDevPanel` salva, carrega e consulta `profile_0` chamando somente `NexusSaveAuthority`, sem SaveFlow direto e sem mutar inventario diretamente.

## Proxima sprint planejada
- A definir apos V17.

Escopo recomendado: expandir SaveFlow para estado estavel do Player/world flags ou evoluir a UI final de produto, mantendo sources/authorities por dominio.

Sprint anterior:
- `Cliente/nexus/docs/plano-sprint-saveflow-lite-persistence-v1-2026-05-13.md`

Escopo anterior: SaveFlow Lite Persistence V15 concluido para inventario do Player. O Player possui `SaveGraphRoot/PlayerInventorySource`, o source salva/carrega via `NexusInventoryBridgeComponent`, e o load valido preserva as propriedades roladas do `ItemStack`.

Historico imediato: Combat Clash temporal foi auditado e removido do runtime. A prova tecnica de `mutual_clash` fica registrada como pesquisa historica, mas Player/Wildcat nao carregam mais `CombatClashComponent` nem profiles de Clash. O core aprovado continua sendo Hit Reaction/Hit Interrupt. Qualquer Parry futuro deve nascer como `DefenseComponent`/`ParryComponent` simples, modular e data-driven por chance/atributo, consultado antes do dano.

## Regra de operacao
1. Antes de nova feature, revisar o freeze atual.
2. Toda mudanca relevante deve atualizar:
- freeze/status
- evidencia MCP (play + erros + logs)
- telemetria quando aplicavel
3. Nao reverter ajustes de cena/tuning aprovados no freeze sem evidencia de regressao.

## Projeto (nucleus)
- Godot: `Cliente/nexus`
- Docs tecnicos: `Cliente/nexus/docs` e `Docs/`
