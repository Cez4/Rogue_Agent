# Rogue Agent - Estado Oficial Atual

Este README aponta a fonte oficial de status tecnico do projeto.

## Fonte oficial de status (freeze atual)
- `Cliente/nexus/docs/status-freeze-funcional-v14-dynamic-loot-dex-2026-05-13.md`

Freezes imediatamente anteriores:
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
1. Combate tatico BT/LimboAI congelado.
2. Hit Reaction/Hit Interrupt restaurado como core aprovado.
3. Combat Clash temporal removido do runtime.
4. Parry futuro deve ser `DefenseComponent`/`ParryComponent` por chance/atributo, nao `mutual_clash` global.
5. Knockback V6 permanece congelado com `knockback_force = 200.0`.
6. Hit Reaction V7/V8/V9 seguem aprovados para Player, Wildcat e hostis.
7. Hitbreak Combat Feedback V11 segue aprovado para Player, Wildcat, Base, Light e Brute.
8. ExpressoBits Inventory System V12/V13 e a fonte oficial data-driven de inventario/equipamento.
9. Dynamic Loot & DEX V14 gera `EquipmentLoadout`/`CombatActionData` em memoria para o Player.
10. Orb UI, Health Regen fora de combate, stamina/kiting e telemetria continuam preservados.

## Sprint atual em execucao
- `Cliente/nexus/docs/plano-sprint-dynamic-loot-dex-v1-2026-05-13.md`
- Branch: `feat/dynamic-loot-dex-v1`

Escopo atual: Dynamic Loot & DEX V14 sobre o ExpressoBits Inventory System. O Player resolve equipamento pelo `InventoryBridge`, o `NexusEquipmentAdapter` gera dados de combate em memoria e `ActorCombatProfileRuntime` deve consumir `get_equipment_loadout_runtime()` para dano, stamina, range e kiting.

Sprint anterior:
- `Cliente/nexus/docs/plano-sprint-inventory-datadriven-core-v1-2026-05-13.md`

Escopo anterior: Inventory Data-Driven Core V13 congelado. O ExpressoBits virou fonte unica de dados de equipamento do Player e os `.tres` antigos de item/equipamento foram removidos para evitar drift.

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
