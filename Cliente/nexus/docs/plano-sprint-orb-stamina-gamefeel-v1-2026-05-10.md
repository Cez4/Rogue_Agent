# Plano de Sprint - Orb de Stamina com Gamefeel (v1)

Data: 2026-05-10  
Status: concluido (implementado e validado no MCP)  
Escopo: UI/UX de combate (sem alterar regra de gameplay)

## Objetivo
Adicionar Orb de Stamina com feedback visual vivo, mantendo arquitetura modular, data-driven e segura para evolucao.

## Contexto tecnico atual
1. Orb de vida (V3) funcional e congelada.
2. `StaminaComponent` funcional com sinais:
- `stamina_changed`
- `exhausted`
- `recovered`
3. Combate atual:
- BT decide
- HSM executa
- motor locomove
4. Telemetria de combate ativa e usada para auditoria.

## Decisao de arquitetura
Nao duplicar logica de orb.

Criar um presenter generico para recurso:
1. `CombatResourceOrbPresenter`
2. modo de recurso:
- `health`
- `stamina`
3. reutilizar shader e pipeline visual por configuracao.

## Regra critica de gatilho (stamina)
Para stamina, a interacao visual deve acontecer por **consumo real**, nao por intencao.

Fonte de verdade:
1. evento de `stamina_changed` com delta negativo.
2. intensidade proporcional ao gasto:
- `spent_ratio = abs(delta) / max_stamina`
- `trauma/slosh` escalam por curva configuravel.

Estados especiais:
1. `exhausted`: pulso forte de alerta.
2. `recovered`: retorno suave para estado normal.

## UX alvo da sprint
1. Orb vida:
- continua reagindo a dano recebido.
2. Orb stamina:
- reage ao gasto de stamina (especialmente durante ataque/cadencia).
3. Cores:
- stamina em gama amarelo/ambar (separacao visual da vida).
4. Regras de exibicao:
- player: mostrar em combate.
- hostil: mostrar somente selecionado e em combate.

## Data-driven (obrigatorio)
Criar configuracao da orb stamina em recurso `.tres`:
1. `fill_color`
2. `background_color`
3. `trail_color`
4. `danger_threshold`
5. `shake_gain`
6. `slosh_gain`
7. `decay`
8. `trail_delay`
9. `trail_drop_speed`

Nada hardcoded por ator.

## Plano de implementacao (microblocos)
1. Extrair presenter para modo `health/stamina`.
2. Ligar orb stamina ao `StaminaComponent` por delta de consumo.
3. Criar preset `.tres` stamina.
4. Aplicar no player.
5. Validar no MCP + telemetria.
6. Aplicar em hostis selecionados (mesma regra contextual da orb de vida).

## Entrega realizada
1. Presenter generico com `ResourceType.HEALTH/STAMINA` em `Scripts/ui/orb/combat_orb_presenter.gd`.
2. Perfil data-driven de orb criado:
- `Scripts/ui/orb/orb_resource_profile.gd`
- `configs/ui/orbs/stamina_orb_profile_v1.tres`
3. `StaminaOrb` aplicada em player e hostis:
- `cenas/player.tscn`
- `cenas/wildcat_1.tscn`
- `cenas/enemies/hostile_enemy_base.tscn`
- `cenas/enemies/hostile_enemy_light.tscn`
- `cenas/enemies/hostile_enemy_brute.tscn`
4. Gate MCP validado (`open_scene -> play_scene -> get_godot_errors`) sem erro novo.

## Decisao de tuning (freeze de escopo)
1. Nao criar perfis de orb por archetype nesta fase.
2. Manter `stamina_orb_profile_v1.tres` como perfil visual unico global.
3. Diferenca entre inimigos/jogador vira somente por gameplay data-driven:
- `CombatActionData.stamina_cost`
- cadencia do ataque (windup/active/recover/cooldown)
4. A orb reflete o consumo real (delta negativo de stamina), sem logica especifica por ator.

## Criterios de aceite
1. MCP gate sem erro novo:
- `open_scene -> play_scene -> get_godot_errors`
2. Telemetria nova clara:
- `orb_stamina_react`
- `stamina_spent_ratio`
- `orb_stamina_exhausted_pulse`
3. Regressao zero:
- combate/chase/death/respawn inalterados.
4. Modularidade:
- uma base de presenter, dois recursos (vida/stamina).

## Riscos e mitigacoes
1. Spam visual por regen:
- reagir apenas a delta negativo e limiar minimo.
2. Custo de material:
- preferir parametros por instancia para reuse.
3. Drift entre UI e gameplay:
- UI apenas le estado, nunca decide regra de combate.

## Referencias tecnicas
1. Godot CanvasItem (`set_instance_shader_parameter`):
- https://docs.godotengine.org/en/4.5/classes/class_canvasitem.html
2. Godot ShaderMaterial (`set_shader_parameter`):
- https://docs.godotengine.org/en/4.6/classes/class_shadermaterial.html
3. LimboAI tasks/custom structure:
- https://limboai.readthedocs.io/en/v1.4.1/behavior-trees/custom-tasks.html
4. Referencia visual da orb:
- https://godotshaders.com/shader/healthmana-bar-in-ball-container-ver-2-1/
- https://sites.google.com/view/orbuicontroller/orbuicontroller-class-code-and-example

## Observacao de governanca
Este plano integra a fase congelada atual e deve ser executado sem abrir nova frente de arquitetura.
Status oficial da fase base:
- `docs/status-freeze-funcional-v2-2026-05-10.md`
