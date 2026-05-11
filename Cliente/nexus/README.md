# Nexus - README de Projeto

## Status oficial da fase atual
- `docs/status-freeze-total-combate-tatico-2026-05-11.md`

Esse documento e a referencia principal para:
1. estado funcional congelado,
2. limites de escopo da fase,
3. proximos passos permitidos sem regressao.

## Resumo rapido
1. Combate: BT decide, HSM executa, Motor locomove.
2. Orb UI: V3 contextual congelada.
3. Stamina/Stagger: consolidado e validado com telemetria.
4. Combate tatico: freeze total aprovado em 2026-05-11.
5. Spam de ataque atualiza alvo sem cancelar kiting; clique no chao cancela combate manualmente.

## Fluxo obrigatorio
1. MCP gate: `open_scene -> play_scene -> get_godot_errors`.
2. Logs/telemetria obrigatorios para validar logica nova.
3. Atualizar docs de status ao fechar cada bloco.
4. Preservar o baseline atual antes de abrir nova feature.
