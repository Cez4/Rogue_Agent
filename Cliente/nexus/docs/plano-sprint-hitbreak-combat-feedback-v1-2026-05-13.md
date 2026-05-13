# Plano Sprint - Hitbreak Combat Feedback v1

Data: 2026-05-13
Status: EM EXECUCAO - FASE A CONCLUIDA
Baseline obrigatorio: `status-freeze-operacional-v10-combat-core-restored-2026-05-13.md`
Branch: `feat/hitbreak-combat-feedback-v1`

## 1) Objetivo
Criar feedback visual global, modular e data-driven para o ator que causa um **Hitbreak**.

Hitbreak, neste projeto, significa: um ator confirma hit, o alvo recebe dano real, entra em Hit Reaction e tem o ataque em andamento interrompido por `reason = hit_reaction`.

O feedback desejado e um brilho/flash curto no atacante, estilo pixel/action RPG, comunicando que ele foi rapido o suficiente para quebrar o ataque do oponente.

## 2) Decisao De Design
Esta sprint nao cria Parry, Defense, Clash ou bloqueio de dano.

O core aprovado permanece:

1. Hitbox confirma contato.
2. Hurtbox aplica dano/knockback.
3. Health emite `damaged`.
4. Hit Reaction executa Taken Damage no alvo.
5. Se o alvo estava atacando, o ataque e interrompido.
6. O atacante recebe feedback visual de sucesso quando a interrupcao foi causada pelo hit dele.

Regra de game feel:

1. O brilho deve premiar quem causou o hitbreak, nao quem tomou dano.
2. O brilho deve ser curto e legivel, sem esconder animacao de ataque.
3. O efeito deve funcionar em Player, Wildcat, hostis e futuros NPCs sem script por entidade.
4. O efeito deve ser desligavel ou tunavel por profile.

## 3) Nomes Tecnicos
Termos aprovados para a sprint:

1. **Hitbreak:** hit confirmado que interrompe ataque do alvo via Hit Reaction.
2. **Hitbreak Success:** evento emitido para o atacante quando o hitbreak e confirmado.
3. **Combat Feedback:** camada visual de resposta a eventos de combate.
4. **Attacker Flash:** brilho/shader curto no ator que causou o hitbreak.
5. **Feedback Profile:** resource `.tres` que controla cor, duracao, intensidade e cooldown.

## 4) Estado Atual Comprovado
O freeze V10 provou por log:

1. Player ataque `44` confirmou hit no Wildcat.
2. Wildcat ataque `80` estava em `windup`.
3. Wildcat emitiu `attack_interrupted`, `reason = hit_reaction`.
4. Wildcat tocou `TakeDamage_*`.
5. O inverso tambem funciona: Wildcat acerta Player, Player toca `Dagger01_TakeDamage_*`.
6. Combat Clash temporal foi removido do runtime.

Limite atual:

1. O log sabe quando o alvo foi interrompido.
2. O log sabe quem confirmou o hit.
3. A Fase A criou o evento unico `hitbreak_success`, ligando atacante e alvo no mesmo fluxo.
4. O atacante ainda nao possui componente visual universal para reagir a esse sucesso.

## 5) Decisao Arquitetural
O modelo aprovado deve seguir o padrao de `KnockbackComponent`, `HitReactionComponent` e `CombatOrbPresenter`:

1. **Componente universal:** `CombatFeedbackComponent`.
   - Plug-and-play em qualquer ator.
   - Nao depende de input.
   - Nao altera dano, stamina, BT ou HSM.
   - Executa apenas feedback visual.

2. **Resource data-driven:** `CombatFeedbackProfile`.
   - Define se o feedback esta ativo.
   - Define tipo de efeito, cor, duracao, intensidade e cooldown.
   - Permite templates novos sem programacao.

3. **Shader/material isolado:** shader de flash/outline no `AnimatedSprite2D`.
   - Material deve ser duplicado em runtime para evitar alterar todas as entidades que compartilham material.
   - Se nao houver shader configurado, fallback pode usar `modulate` temporario.

4. **Detector de hitbreak:** extensao minima do pipeline atual.
   - O dano precisa carregar o atacante ate o ponto em que o alvo interrompe o ataque por Hit Reaction.
   - Ao confirmar que `attack_interrupted.reason == hit_reaction`, emitir `hitbreak_success` para o atacante.
   - Nao colocar regra dentro de `Actor8DirLimbo`.

5. **BT/HSM preservadas:** a Behavior Tree e a HSM continuam executando combate e Hit Reaction.
   - O feedback visual nao deve bloquear estado.
   - O feedback visual nao deve limpar alvo.
   - O feedback visual nao deve iniciar ataque ou movimento.

## 6) Data-Driven - CombatFeedbackProfile
Resource proposto: `res://Scripts/combat/feedback/combat_feedback_profile.gd`

Campos iniciais:

1. `enabled: bool = true`
2. `hitbreak_flash_enabled: bool = true`
3. `hitbreak_flash_color: Color = Color(1.0, 0.95, 0.45, 1.0)`
4. `hitbreak_flash_duration_sec: float = 0.12`
5. `hitbreak_flash_intensity: float = 1.0`
6. `hitbreak_cooldown_sec: float = 0.08`
7. `use_shader_material: bool = true`
8. `fallback_to_modulate: bool = true`
9. `sprite_path: NodePath = ^"../AnimatedSprite2D"` ou campo equivalente no componente
10. `reset_material_on_exit: bool = true`

Profiles esperados no v1:

1. `res://configs/combat/feedback/default_hitbreak_feedback_profile_v1.tres`
2. Opcional depois: `player_hitbreak_feedback_profile_v1.tres`
3. Opcional depois: `hostile_hitbreak_feedback_profile_v1.tres`

## 7) Componente Universal - CombatFeedbackComponent
Script proposto: `res://Scripts/combat/feedback/combat_feedback_component.gd`

Responsabilidades:

1. Resolver o ator alvo e o `AnimatedSprite2D`.
2. Duplicar material em runtime quando usar shader.
3. Expor metodo publico:
   - `play_hitbreak_success(source_data: Dictionary = {}) -> void`
4. Aplicar flash por tempo curto.
5. Respeitar cooldown para evitar flicker/hitspam visual.
6. Emitir telemetria:
   - `combat_feedback_hitbreak_started`
   - `combat_feedback_hitbreak_finished`
   - `combat_feedback_skipped`

Nao e responsabilidade do componente:

1. Calcular dano.
2. Decidir se houve Hit Reaction.
3. Interromper ataque.
4. Alterar stamina.
5. Resolver Parry/Defense.

## 8) Shader / Material
Shader proposto: `res://Scripts/combat/feedback/hitbreak_flash.gdshader`

Parametros minimos:

1. `flash_amount`
2. `flash_color`
3. `outline_amount` opcional
4. `outline_color` opcional

Regra:

1. O shader deve ser simples e barato, porque pode rodar em muitos atores.
2. Nada de efeito persistente por frame pesado.
3. O componente deve animar apenas `flash_amount` por Tween ou `_process` curto.
4. Se um ator ja tiver material customizado, duplicar antes de alterar parametro.

## 9) Ponto De Integracao Do Hitbreak
Fluxo proposto:

1. `HitboxComponent` confirma hit e passa `source` para `HurtboxComponent`.
2. `HurtboxComponent` registra no alvo a origem do ultimo dano recebido, sem acoplar ao ator.
3. `HitReactionComponent` recebe o dano e sabe o `source_actor` do dano atual.
4. Quando `HitReactionComponent` marcar `attack_interrupt_reason = hit_reaction`, tambem guarda `hitbreak_source_actor`.
5. `state_attack_8dir.gd`, ao emitir `attack_interrupted` por `hit_reaction`, emite/aciona `hitbreak_success` para o atacante.
6. O atacante, se tiver `CombatFeedbackComponent`, toca `play_hitbreak_success(...)`.

Alternativa se a Fase A provar mais simples:

1. `HitReactionComponent` pode detectar se o alvo estava em ataque antes de despachar `hit_reaction!`.
2. Nesse caso, ele mesmo emite `hitbreak_success` para o atacante.
3. Essa alternativa so deve ser usada se nao duplicar semantica de ataque nem inflar o actor.

## 10) Contrato Minimo Sem Inflar Actor8DirLimbo
`Actor8DirLimbo` nao deve receber tuning/export de Combat Feedback.

Wrappers so podem ser aceitos se forem fachada minima:

1. `get_combat_feedback_component() -> Node`
2. `play_combat_feedback(event_name: StringName, data: Dictionary = {}) -> void`

Preferencia:

1. Resolver o componente por nome no ator atacante quando necessario.
2. Manter dados no `CombatFeedbackProfile`.
3. Nao adicionar shader, cor ou duracao no actor.

## 11) Plano De Execucao

### Fase A - Telemetria Sem Mudanca Visual
- [x] Revisar freeze V10 e logs de hitbreak aprovados.
- [ ] Ler docs oficiais Godot sobre `ShaderMaterial`, `CanvasItem`, `AnimatedSprite2D` e `Tween`.
- [x] Mapear como carregar `source_actor` do `HitboxComponent` ate o `HitReactionComponent`.
- [x] Emitir evento `hitbreak_success` sem tocar visual.
- [x] Confirmar por log:
  - atacante;
  - alvo;
  - `source_attack_sequence_id`;
  - `target_attack_sequence_id` quando existir;
  - `reason = hit_reaction`.
- [x] Validar MCP: `open_scene -> play_scene -> get_godot_errors`.

Resultado Fase A:

1. `HitboxComponent` passa `attack_sequence_id` e `hitbox_sequence_id` para a `HurtboxComponent`.
2. `HurtboxComponent` marca temporariamente no ator atingido a fonte do dano atual.
3. `HitReactionComponent` copia essa fonte para metadados de Hitbreak somente se o alvo estava com ataque pendente.
4. `state_attack_8dir.gd` emite `hitbreak_success` quando o ataque sai por `reason = hit_reaction`.
5. Interrupcao por `death` continua separada e nao gera falso `hitbreak_success`.
6. Nao houve mudanca visual, shader, cena, BT, HSM, dano, stamina ou Knockback nesta fase.

Evidencia MCP:

1. `mundo.tscn` abriu e rodou sem parse/runtime error novo.
2. Log comprovado:
   - `attack_interrupted` em `HostileEnemyLight`, `reason = hit_reaction`;
   - `hitbreak_success` com `actor = Player`, `target = HostileEnemyLight`, `source_attack_sequence_id`, `source_hitbox_sequence_id`, `target_attack_sequence_id` e `target_phase`.
3. Log tambem separou `attack_interrupted`, `reason = death`, sem emitir `hitbreak_success`.

### Fase B - Componente Visual Em Um Ator
- [ ] Criar `CombatFeedbackProfile`.
- [ ] Criar `CombatFeedbackComponent`.
- [ ] Criar shader simples `hitbreak_flash.gdshader`.
- [ ] Integrar no Player via Godot/editor API.
- [ ] Tocar brilho somente quando o Player causar hitbreak.
- [ ] Nao alterar dano, stamina, Hit Reaction, Knockback, BT ou HSM.
- [ ] Validar MCP e QA visual.

### Fase C - Propagacao Para NPC Hostil
- [ ] Integrar no Wildcat via Godot/editor API.
- [ ] Confirmar brilho quando Wildcat causar hitbreak no Player.
- [ ] Validar que Player e Wildcat usam o mesmo componente/profile ou profiles compatíveis.
- [ ] Confirmar que nao ha material compartilhado causando flash em todos os atores ao mesmo tempo.

### Fase D - Cobertura Hostis E Tuning
- [ ] Integrar em HostileEnemyBase, HostileEnemyLight e HostileEnemyBrute via Godot/editor API.
- [ ] Se necessario, criar profile diferente para Brute/Light.
- [ ] Ajustar duracao/intensidade pelo `.tres`, nao por codigo.
- [ ] Confirmar performance visual com varios atores.

### Fase E - QA, Docs E Freeze
- [ ] QA visual aprovado pelo diretor.
- [ ] Logs comprovam `hitbreak_success`.
- [ ] Logs comprovam `combat_feedback_hitbreak_started`.
- [ ] Sem regressao em Hit Reaction V7/V8/V9.
- [ ] Sem regressao em Knockback V6.
- [ ] Sem regressao em stamina/kiting/orb/regen.
- [ ] Criar freeze funcional se aprovado.

## 12) Criterios De Aceite
Sprint pronta somente quando:

1. O brilho aparece no atacante que causou hitbreak.
2. O alvo que recebeu dano continua tocando TakeDamage normalmente.
3. O brilho e data-driven via `.tres`.
4. O componente e plug-and-play.
5. Nenhuma logica entra no `Actor8DirLimbo` alem de fachada minima, se inevitavel.
6. Cenas/resources foram editados via Godot/editor API.
7. MCP limpo.
8. Logs distinguem:
   - hit normal;
   - hitbreak;
   - morte (`reason = death`) sem falso hitbreak.

## 13) Riscos E Mitigacoes
1. **Flash em todos os atores por material compartilhado:** duplicar `ShaderMaterial` em runtime.
2. **Hitbreak falso em morte:** separar `reason = death` de `reason = hit_reaction`.
3. **Inflar Actor8DirLimbo:** manter componente dedicado e dados em profile.
4. **Flicker visual por hitspam:** usar cooldown curto no profile.
5. **Efeito esconder TakeDamage do alvo:** aplicar feedback no atacante, nao no alvo.
6. **Performance com muitos NPCs:** shader simples, parametros poucos, sem textura extra no v1.
7. **Confundir com Parry/Defense:** docs devem deixar claro que Hitbreak Feedback e apenas visual; nao cancela dano.

## 14) Fontes Tecnicas A Consultar Antes De Implementar
1. Godot `ShaderMaterial`:
   - https://docs.godotengine.org/en/stable/classes/class_shadermaterial.html
2. Godot `CanvasItem` materials/shaders:
   - https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html
3. Godot `AnimatedSprite2D`:
   - https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html
4. Godot `Tween`:
   - https://docs.godotengine.org/en/stable/classes/class_tween.html

## 15) Definicao De Pronto
1. Plano versionado.
2. Branch propria criada antes da implementacao.
3. Fase A entregue antes de qualquer efeito visual.
4. Primeiro visual aplicado apenas em Player ou Wildcat.
5. Propagacao para hostis somente apos QA visual.
6. Docs/runbooks/skills atualizados.
7. Freeze criado somente apos aprovacao visual e telemetria.
