# Rogue Agent - Estado Oficial Atual

Este README aponta a fonte oficial de status tecnico do projeto.

## Fonte oficial de status (freeze atual)
- `Cliente/nexus/docs/status-freeze-funcional-v16-saveflow-slots-host-authority-2026-05-13.md`

Freezes imediatamente anteriores:
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
1. SaveFlow Slots & Host Authority V16 funcional.
2. `NexusSaveAuthority` e a entrada oficial para save/load de gameplay.
3. SaveFlow Lite Persistence V15 funcional para inventario do Player.
4. Prova anti-reroll aprovada: save/load preserva `ItemStack.item_id/properties`.
5. SaveFlow nao substitui ExpressoBits, `NexusInventoryAuthority`, `NexusInventoryBridgeComponent` nem `NexusEquipmentAdapter`.
6. Co-op segue host-authoritative: host salva/carrega estado autoritativo.
7. Combate tatico BT/LimboAI congelado.
8. Hit Reaction/Hit Interrupt restaurado como core aprovado.
9. Combat Clash temporal removido do runtime.
10. Parry futuro deve ser `DefenseComponent`/`ParryComponent` por chance/atributo, nao `mutual_clash` global.
11. Knockback V6 permanece congelado com `knockback_force = 200.0`.
12. Hit Reaction V7/V8/V9 seguem aprovados para Player, Wildcat e hostis.
13. Hitbreak Combat Feedback V11 segue aprovado para Player, Wildcat, Base, Light e Brute.
14. ExpressoBits Inventory System V12/V13 e a fonte oficial data-driven de inventario/equipamento.
15. Dynamic Loot & DEX V14 gera `EquipmentLoadout`/`CombatActionData` em memoria para o Player.
16. Orb UI, Health Regen fora de combate, stamina/kiting e telemetria continuam preservados.

## Sprint atual congelada
- `Cliente/nexus/docs/plano-sprint-saveflow-slots-host-authority-v1-2026-05-13.md`
- Branch: `feat/saveflow-slots-host-authority-v1`

Escopo atual: SaveFlow Slots & Host Authority V16 concluido. `NexusSaveAuthority` salva/carrega o slot `profile_0`, preserva a dagger entre save/load e bloqueia a regra arquitetural: gameplay chama authority, nao SaveFlow direto.

## Proxima sprint planejada
- `SaveFlow UI Dev Panel v1`

Escopo planejado: painel dev simples para salvar/carregar `profile_0`, listar slot summary e exibir sucesso/erro sem chamar SaveFlow direto.

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
