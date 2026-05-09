# Plano v1 - Orb UI Contextual de Combate

Data: 2026-05-09  
Branch: `feat/combat-orb-ui-contextual`  
Status: implementado e validado (commit ef5b8fe)

## Resultados da Implementação
1. **Shader Avançado:** Integrado com suporte a `trail_level` e `vibration`.
2. **Presenter Robusto:** Uso de Tweens para animações de impacto (vibration) e trail (ghost bar).
3. **Feedback de Vida Baixa:** Alerta visual automático via shader quando HP < 25%.
4. **Contexto:** Validado em Player e Hostiles (Light/Brute).
5. **Anti-Overlap (Dynamic Side-Offset):** Orbs agora usam `top_level = true` e se separam lateralmente (Player -> Esquerda, Target -> Direita) para evitar sobreposição em combate próximo.

## Eixos de Tuning (Ajustados)
- `trail_delay`: 0.4s.
- `trail_duration`: 0.6s.
- `vibration_duration`: 0.3s.
- `side_separation`: 35.0px (espaçamento lateral para evitar overlap).
- `interpolation_weight`: 12.0 (suavidade do movimento da orb).

## Objetivo
Adicionar UI de vida em formato orb (shader) com visibilidade contextual, sem impactar lógica de combate/rede.

## Regras de UX (definidas)
1. Sem target selecionado: nao exibir informacao de NPC/inimigo.
2. Player orb:
   - exibir somente quando o player estiver em combate;
   - esconder fora de combate.
3. NPC/inimigo orb:
   - exibir somente quando estiver selecionado;
   - e somente quando estiver em combate.
4. Posicionamento da orb do player:
   - flutuante, seguindo o player;
   - alinhada ao lado esquerdo do personagem (offset fixo, ajustavel).

## Resposta tecnica (seguranca coop/multiplayer)
1. `OrbUIController` nao e nativo do Godot (script third-party).
2. Uso e seguro no coop se ficar estritamente na camada de apresentacao local.
3. Regras obrigatorias:
   - orb nao decide gameplay;
   - orb apenas le estado (HP atual/max, estado de combate, selecao);
   - sem RPC de gameplay dependente da orb.

## Arquitetura recomendada (robusta)
1. Criar wrapper interno:
   - `CombatOrbPresenter` (script do projeto);
   - encapsula chamada para shader/OrbUIController.
2. Separar contexto de exibicao:
   - `in_combat` (estado do ator);
   - `is_selected_target` (alvo atual selecionado pelo player).
3. Fonte de dados:
   - `HealthComponent` (`current_health`, `max_health`);
   - estado de combate ja existente no actor/BT/HSM.
4. Evitar acoplamento:
   - UI nao altera HP nem estado;
   - UI recebe eventos e atualiza visual.

## Escopo da fase
1. Integrar orb no player (contextual em combate).
2. Integrar orb em inimigo selecionado (contextual + selecionado).
3. Exibir somente 1 orb contextual de alvo por vez.
4. Nao alterar sistema de combate core.

## Fora de escopo (nesta fase)
1. Refator de rede.
2. Novas mecanicas de dano.
3. HUD completo de atributos/status.

## Critérios de aceite
1. MCP gate:
   - `open_scene -> play_scene -> get_godot_errors` sem erro novo.
2. Visual:
   - orb do player aparece/desaparece corretamente conforme combate;
   - orb de inimigo so aparece quando selecionado e em combate.
3. Telemetria:
   - logs de estado claros (`orb_show`, `orb_hide`, `actor`, `reason`).
4. Regressao zero:
   - combate, chase, death/respawn continuam identicos.

## Sequencia de implementacao (microblocos)
1. Bloco A: criar `CombatOrbPresenter` + cena base da orb.
2. Bloco B: ligar orb do player a estado de combate.
3. Bloco C: ligar orb de alvo selecionado (hostile).
4. Bloco D: telemetria minima da UI contextual.
5. Bloco E: tuning visual (offset/escala/duracao transicao) sem tocar gameplay.

## Riscos e mitigacoes
1. Risco: orb third-party acoplar em gameplay.
   - Mitigacao: wrapper interno + leitura somente.
2. Risco: poluicao visual/perf em massa.
   - Mitigacao: orb contextual (player + alvo selecionado), nao global.
3. Risco: drift entre selecao e alvo real.
   - Mitigacao: fonte unica do target lock/intencao atual.

## Referencias
1. Orb shader:
   - https://godotshaders.com/shader/healthmana-bar-in-ball-container-ver-2-1/
2. OrbUIController:
   - https://sites.google.com/view/orbuicontroller/orbuicontroller-class-code-and-example
3. Godot CanvasItem shaders:
   - https://docs.godotengine.org/en/4.4/tutorials/shaders/shader_reference/canvas_item_shader.html
4. Godot ShaderMaterial parameters:
   - https://docs.godotengine.org/en/4.5/classes/class_shadermaterial.html
