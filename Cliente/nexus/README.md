# Nexus - README de Projeto

## Status oficial da fase atual
- `docs/status-freeze-funcional-v7-hit-reaction-2026-05-12.md`

Esse documento e a referencia principal para:
1. estado funcional congelado,
2. limites de escopo da fase,
3. proximos passos permitidos sem regressao.

## Resumo rapido
0. Freeze atual: Universal Hit Reaction V7, modular/Data-Driven, com `HitReactionComponent` + `HitReactionProfile` + `HitReactionState`.
1. Combate: BT decide, HSM executa, Motor locomove.
2. Orb UI: V3 contextual congelada.
3. Stamina/Stagger: consolidado e validado com telemetria.
4. Identidade "The Sims-like": Player e NPCs utilizam a mesma fundação de perfis Data-Driven (`ActorSocialProfile` etc). 
5. NavAgent: Filtro anti-spam implementado no PlayerMotor. Kiting livre de travamentos em bordas.
6. Knockback V6 permanece congelado com `knockback_force = 200.0`.
7. Player toca `Dagger01_TakeDamage_*` inteiro ao receber dano e orienta a animacao para a origem do golpe.

## Fluxo obrigatorio
1. MCP gate: `open_scene -> play_scene -> get_godot_errors`.
2. Logs/telemetria obrigatorios para validar logica nova.
3. Atualizar docs de status ao fechar cada bloco.
4. Preservar o baseline atual antes de abrir nova feature.
