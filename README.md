# Rogue Agent - Estado Oficial Atual

Este README aponta a fonte oficial de status tecnico do projeto.

## Fonte oficial de status (freeze atual)
- `Cliente/nexus/docs/status-freeze-funcional-v9-hostile-hit-reaction-2026-05-12.md`

Freezes imediatamente anteriores:
- `Cliente/nexus/docs/status-freeze-funcional-v8-wildcat-hit-reaction-2026-05-12.md`
- `Cliente/nexus/docs/status-freeze-funcional-v7-hit-reaction-2026-05-12.md`

Freeze historico base:
- `Cliente/nexus/docs/status-freeze-total-combate-tatico-2026-05-11.md`

Freeze de game feel fisico:
- `Cliente/nexus/docs/status-freeze-funcional-v6-knockback-2026-05-12.md`

Esse documento manda no estado da fase atual e consolida:
1. Combate tatico BT/LimboAI congelado.
2. Spam de clique de ataque sem cancelar kiting automatico.
3. Baixa stamina baseada em custo real de ataque, sem zona morta.
4. NavMesh/tuning/stamina/walk atuais aprovados como baseline de QA.
5. Orb UI V3, Stamina/Stagger e telemetria continuam preservados como base funcional.
6. Knockback V6 permanece congelado com `knockback_force = 200.0`.
7. Hit Reaction V7 esta aprovado: Player toca `Dagger01_TakeDamage_*` inteiro, olhando para a origem do golpe, sem limpar alvo de combate.
8. Hit Reaction V8 esta aprovado no Wildcat.
9. Hit Reaction V9 esta aprovado nos hostis `HostileEnemyBase`, `HostileEnemyLight` e `HostileEnemyBrute`.

## Sprint atual em execucao
- `Cliente/nexus/docs/plano-sprint-combat-clash-parry-v1-2026-05-12.md`

Escopo atual: Fase D foi auditada e o gameplay de parry/clash esta desabilitado nos profiles para preservar o feel aprovado. `CombatClashProfile` e `CombatClashComponent` existem, candidatos temporais continuam observaveis, mas Player e Wildcat estao em `emit_only_telemetry = true` e `can_parry = false` ate uma Fase D2 mais justa.

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
