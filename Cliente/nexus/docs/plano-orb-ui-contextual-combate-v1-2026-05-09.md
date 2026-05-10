# Plano v1 - Orb UI Contextual de Combate

Data: 2026-05-09  
Branch: `feat/combat-orb-ui-contextual`  
Status atual: Finalizado e congelado como Orb V3

## Resumo da entrega final (V3 congelada)
1. Orb contextual por estado:
- Player: aparece somente em combate.
- Hostil: aparece somente quando selecionado e em combate.

2. Shader e game feel:
- Liquido animado com efeito de slosh.
- Trail de dano (ghost trail) visivel e legivel.
- Alerta de vida baixa no player.
- Target lock visual para alvo selecionado.

3. Robustez de lifecycle:
- Correcao de sync no respawn/heal com snap do trail.
- Orb nao interfere em gameplay, apenas apresenta estado.

## Regras de arquitetura
1. UI nao decide gameplay.
2. UI apenas le estado de:
- `HealthComponent`
- contexto de combate/alvo selecionado
3. Sem RPC de gameplay pela UI.

## Fonte de implementacao
- Presenter: `Scripts/ui/orb/combat_orb_presenter.gd`
- Shader: `Scripts/ui/orb/orb_health_shader.gdshader`
- Cena: `cenas/components/ui/combat_orb_presenter.tscn`

## Validacao de aceite
1. `open_scene -> play_scene -> get_godot_errors` sem erro novo.
2. Telemetria de orb (`orb_visibility`) coerente com estados.
3. Regressao zero no combate/chase/death/respawn.

## Observacao de status
Este plano foi executado e congelado.  
O estado funcional oficial da fase atual esta em:
- `docs/status-freeze-funcional-v2-2026-05-10.md`

## Referencias
1. Orb shader (referencia):
- https://godotshaders.com/shader/healthmana-bar-in-ball-container-ver-2-1/
2. Orb UI controller (referencia):
- https://sites.google.com/view/orbuicontroller/orbuicontroller-class-code-and-example
3. Godot CanvasItem shader:
- https://docs.godotengine.org/en/4.4/tutorials/shaders/shader_reference/canvas_item_shader.html
