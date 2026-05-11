# Rogue Agent - Estado Oficial Atual

Este README aponta a fonte oficial de status tecnico do projeto.

## Fonte oficial de status (freeze atual)
- `Cliente/nexus/docs/status-freeze-total-combate-tatico-2026-05-11.md`

Esse documento manda no estado da fase atual e consolida:
1. Combate tatico BT/LimboAI congelado.
2. Spam de clique de ataque sem cancelar kiting automatico.
3. Baixa stamina baseada em custo real de ataque, sem zona morta.
4. NavMesh/tuning/stamina/walk atuais aprovados como baseline de QA.
5. Orb UI V3, Stamina/Stagger e telemetria continuam preservados como base funcional.

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
