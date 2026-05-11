# Plano Sprint - Actor8Dir Facade Slimming v1

Data: 2026-05-11
Status: FECHAMENTO PARCIAL CONGELADO - FASE E DIFERIDA
Versao: v1
Ordem obrigatoria cumprida: `plano-sprint-health-regen-datadriven-v1-2026-05-11.md` esta implementado, validado em MCP, aprovado em QA, documentado e congelado.

## 1) Decisao de sequenciamento
Esta sprint e a frente estrutural ativa.

A ordem oficial e:

1. `Health Regen Data-Driven v1` - concluida/congelada.
2. `Actor8Dir Facade Slimming v1` - ativa.

Motivo: o Health Regen consolidou contratos importantes de combate/vida, especialmente `ActorCombatRuntime.is_actor_in_combat(actor)`. O slimming agora deve preservar esses contratos e nao introduzir feature nova.

## 2) Objetivo
Reduzir `Scripts/actors/actor_8dir_limbo.gd` de fachada inchada para ator fino, mantendo API publica estavel para BT, HSM, Controller, Orb e cenas.

O alvo nao e "mexer por estetica". O alvo e reduzir risco de manutencao antes de adicionar sistemas maiores como buffs, regen autoritativo, aggro, threat, multiplayer sync e novos inimigos.

## 3) Diagnostico atual
Estado auditado em 2026-05-11:

1. `actor_8dir_limbo.gd` tem 633 linhas.
2. O arquivo nao e mais um god script puro; boa parte da logica ja esta em `Scripts/actors/services`.
3. O problema atual e uma fachada grande demais: muitos exports, muitos estados privados, muitos wrappers, muitos metodos `_bridge_*`, calculos de stamina/ataque ainda locais e calculos espaciais ainda locais.

## 4) Principio tecnico
Preservar comportamento primeiro, reduzir superficie depois.

Regras:

1. Sem mudanca visual de combate.
2. Sem alterar BT/HSM estruturalmente.
3. Sem alterar `bt_move_to_blackboard_pos.gd` nesta sprint, salvo bug comprovado.
4. Sem mover logica para singleton global.
5. Sem criar script especifico por inimigo.
6. Sem duplicar regra de combate entre UI, regen e actor.
7. Manter dados em `.tres`/exports quando forem tuning de design.

## 5) Fora de escopo
1. Implementar Health Regen.
2. Alterar Orb de vida.
3. Alterar stamina/kiting aprovado.
4. Alterar NavMesh/NavPolygon.
5. Refatorar arvores `.tres` do LimboAI.
6. Migrar combate para SpacetimeDB/server-authoritative.
7. Trocar arquitetura de cena do Player/NPCs.

## 6) Dependencias obrigatorias
Estado antes de iniciar esta sprint:

- [x] Health Regen Data-Driven v1 concluida.
- [x] `ActorCombatRuntime.is_actor_in_combat(actor)` implementado e usado por Orb/Regen.
- [x] `HealthComponent` com contrato de cura/dano estabilizado.
- [x] Godot MCP limpo depois do Health Regen.
- [x] Freeze/status atualizado com baseline visual aprovado.
- [x] Branch sincronizada antes de abrir refactor.

## 7) Arquivos provaveis
Scripts:

1. `Scripts/actors/actor_8dir_limbo.gd`
2. `Scripts/actors/services/actor_combat_runtime.gd`
3. `Scripts/actors/services/actor_combat_profile_runtime.gd`
4. `Scripts/actors/services/actor_action_runtime.gd`
5. `Scripts/actors/services/actor_navigation_runtime.gd`
6. `Scripts/actors/services/actor_runtime_bridge.gd`
7. `Scripts/actors/services/actor_setup_runtime.gd`

Docs:

1. `checklist-regressao-pr-actor-bt-hsm.md`
2. `auditoria-estado-atual-bt-hsm-combate.md`
3. `arquitetura-contratos-estado-atual-2026-05-10.md`
4. `status-freeze-total-combate-tatico-2026-05-11.md`, se baseline mudar

## 8) Plano de execucao
### Fase A - Baseline e contrato
- [x] Medir linhas/metodos atuais de `actor_8dir_limbo.gd`.
- [x] Listar consumidores reais da API publica.
- [x] Classificar metodos em: gameplay API, bridge tecnico, lifecycle, combat resource, spatial, animation/social.
- [x] Marcar o que nao pode mudar por contrato BT/HSM/Controller.
- [x] Rodar MCP baseline antes de qualquer patch.

### Fase B - Extrair stamina/attack resource
- [x] Criar ou ampliar runtime dedicado para custo/viabilidade de ataque.
- [x] Mover `has_stamina_for_attack()`.
- [x] Mover `get_required_stamina_for_attack()`.
- [x] Mover `get_low_stamina_kite_probability()`.
- [x] Mover `get_low_stamina_kite_distance()`.
- [x] Mover `get_low_stamina_kite_cooldown_ms()`.
- [x] Manter wrappers publicos no actor, se BT/tasks ainda dependem deles.
- [x] Validar kiting/attack no MCP.

### Fase C - Extrair spatial/combat geometry
- [x] Liberada apos QA confirmar reducao do spam de telemetria `kiting_started`.
- [x] Criar `actor_spatial_runtime.gd` ou equivalente.
- [x] Mover `get_min_separation_distance_to()`.
- [x] Mover `compute_approach_position()`.
- [x] Mover `get_attack_engage_distance()`.
- [x] Validar chase, range e sem "air attack".

### Fase D - Reduzir bridge ruidoso
- [x] Auditar `_bridge_get_float_state/_set_float_state`.
- [x] Auditar `_bridge_get_int_state/_set_int_state`.
- [x] Avaliar `ActorRuntimeState` como Resource/RefCounted interno.
- [x] Migrar somente se reduzir acoplamento sem quebrar assinatura dos runtimes.
- [x] Nao trocar tudo de uma vez.

### Fase E - Organizar exports por perfil
- [ ] Identificar exports que sao tuning de design.
- [ ] Identificar exports que deveriam viver em `CombatPerceptionProfile`, `CombatActionData` ou futuro profile social/wander.
- [ ] Nao migrar dados de cena sem QA visual.
- [ ] Criar plano separado se a migracao de dados for grande.

Decisao: Fase E diferida para sprint/branch separada. Motivo: migracao de exports pode alterar dados de cena/tuning visual e nao deve ser misturada ao slimming ja aprovado.

### Fase F - Validacao MCP e telemetria
- [x] `open_scene(res://cenas/mundo.tscn)`.
- [x] `play_scene(current)`.
- [x] Testar Player vs Brute com spam de ataque.
- [x] Testar clique no chao cancelando combate.
- [x] Testar baixa stamina/kiting.
- [x] Testar death/respawn.
- [x] `get_godot_errors` sem erro novo.
- [x] Logs esperados preservados: `attack_commit`, `hit_confirmed`, `kiting_started`, `kiting_ended`, `target_died`, `respawned`.
- [x] QA confirmou que `kiting_started` nao emite mais em spam antes de `kiting_holding`.

### Fase G - Documentacao e Git
- [ ] Atualizar docs de arquitetura.
- [ ] Atualizar checklist se algum contrato mudar.
- [ ] Atualizar freeze somente se baseline funcional mudar.
- [x] Commit pequeno por bloco.
- [x] Push e sync confirmado.

## 9) Criterios de aceite
- [x] Health Regen ja esta concluido antes desta sprint iniciar.
- [x] `actor_8dir_limbo.gd` ficou menor sem perder contrato publico usado por BT/HSM/Controller.
- [x] Nenhum comportamento aprovado do combate mudou.
- [x] Nenhuma arvore `.tres` foi editada por texto.
- [x] Player, Brute, Light e Wildcat continuam compartilhando core.
- [x] Kiting data-driven continua consumindo `CombatActionData`.
- [x] Orb continua funcional.
- [x] Sem parse/runtime error novo no Godot.
- [x] Docs atualizados na mesma entrega.

## 10) Riscos e mitigacoes
Risco: quebrar contrato de BT/tasks por remover wrapper publico cedo demais.
Mitigacao: manter wrappers no actor ate migrar consumidores com MCP limpo.

Risco: refactor mascarar regressao visual pequena.
Mitigacao: validar cena principal depois de cada bloco e conferir telemetria.

Risco: misturar feature nova com refactor.
Mitigacao: esta sprint so inicia depois do Health Regen fechado; nao implementar feature nova aqui.

Risco: excesso de abstracao.
Mitigacao: extrair apenas responsabilidades reais que ja existem no arquivo.

## 11) Resultado esperado
O ator deve continuar sendo o ponto de integracao de cena do Godot, mas nao deve carregar regras de dominio que pertencem a runtimes/componentes.

Meta qualitativa: `Actor8DirLimbo` vira uma fachada fina e previsivel, nao um arquivo onde toda feature nova tende a ser encaixada.

## 12) Tick final da sprint
- [x] Sprint iniciada somente apos Health Regen
- [x] Sprint concluida em fechamento parcial
- [x] QA aprovou sem regressao visual
- [x] MCP limpo
- [x] Docs atualizados
- [x] Commit/push sincronizado

## 13) Implementacao - bloco 1
Data: 2026-05-11
Status: congelado.

Escopo:
1. Criado `Scripts/actors/services/actor_combat_resource_runtime.gd`.
2. Movida a regra de stamina/attack resource para runtime dedicado.
3. Wrappers publicos preservados em `Actor8DirLimbo`:
   - `has_stamina_for_attack()`
   - `get_required_stamina_for_attack()`
   - `get_low_stamina_kite_probability()`
   - `get_low_stamina_kite_distance()`
   - `get_low_stamina_kite_cooldown_ms()`
4. `actor_8dir_limbo.gd` reduziu de 633 para 601 linhas.

Contrato preservado:
1. BT tasks continuam chamando os mesmos metodos publicos.
2. HSM de ataque continua chamando `get_required_stamina_for_attack()`.
3. Kiting continua consumindo `CombatActionData`.
4. Nenhuma cena, BT `.tres`, HSM, Orb ou Health Regen foi alterado.
5. Smoke MCP abriu `mundo.tscn`, rodou a cena e nao apontou erro novo.

QA/logs gerados pelo usuario:
1. Sem parse/runtime error novo.
2. Player e Brute continuam emitindo `attack_started`, `attack_commit` e `hit_confirmed`.
3. Stamina continua consumida por dados: Player `20.0`, Brute `28.0`.
4. Kiting continua funcional com `kiting_started`, `kiting_holding` e `kiting_ended`.
5. Death/respawn preservados: `target_lost`, `chase_canceled(reason=death)`, `target_died`, `respawned`.
6. Health Regen preservado: Orb aparece por `reason=\"healed\"` e Player regenera ate `20.0`.

Ponto congelado:
1. `kiting_started` aparece em spam quase por frame antes de `kiting_holding`.
2. A origem provavel e a composicao da BT com `bt_emit_telemetry` no ramo de kiting, nao o runtime extraido.
3. Decisao aplicada: filtrar eventos repetidos consecutivos no script atomico `bt_emit_telemetry.gd`, sem editar `.tres`.
4. QA aprovou o ajuste: Fase C pode seguir, mantendo guardrails de nao alterar kiting, movimento, stamina ou BT `.tres`.

## 14) Ajuste de telemetria - kiting spam
Data: 2026-05-11
Status: aplicado e aprovado em QA jogavel.

Mudanca:
1. `bt_emit_telemetry.gd` agora guarda o ultimo evento emitido por ator.
2. Se o mesmo ator tentar emitir o mesmo evento consecutivo, a task retorna `SUCCESS` sem reenviar telemetria.
3. Quando o evento muda (`kiting_started` -> `kiting_holding` -> `kiting_ended`), a telemetria volta a emitir normalmente.

Motivo:
1. O log mostrava `kiting_started` quase por frame.
2. A BT nao foi alterada.
3. O comportamento de kiting/movimento nao foi alterado.

Validacao feita:
1. Script abriu no Godot sem parse error.
2. Smoke `mundo.tscn` rodou sem runtime error novo.

Validacao final:
1. QA jogavel Player vs Brute aprovado.
2. `kiting_started` aparece por transicao de kiting, nao em spam por frame.
3. `kiting_holding`, `kiting_ended`, `attack_commit`, `hit_confirmed`, `target_died`, `respawned` continuam aparecendo.
4. Stamina, Health Regen e Orb continuam preservados.

## 15) Implementacao - bloco 2
Data: 2026-05-11
Status: aplicado e aprovado em QA jogavel.

Escopo:
1. Criado `Scripts/actors/services/actor_spatial_runtime.gd`.
2. Movida a geometria de combate para runtime dedicado:
   - `get_attack_engage_distance()`
   - `get_min_separation_distance_to()`
   - `compute_approach_position()`
3. Wrappers publicos preservados em `Actor8DirLimbo`.
4. `actor_8dir_limbo.gd` reduziu de 601 para 566 linhas.

Contrato preservado:
1. `bt_is_combat_target_in_attack_range.gd` continua chamando `agent.get_attack_engage_distance()` e `agent.get_min_separation_distance_to(target)`.
2. `actor_navigation_runtime.gd` continua chamando `actor.compute_approach_position(...)`.
3. Nenhuma cena, BT `.tres`, HSM, Orb, Health Regen, stamina tuning ou kiting foi alterado.

Validacao final:
1. Smoke MCP sem parse/runtime error. [ok]
2. QA jogavel de chase/range sem "air attack". [ok]
3. Player vs Brute preservou `attack_commit`, `hit_confirmed`, `kiting_started`, `kiting_holding`, `kiting_ended`. [ok]
4. Logs mostram checks de range falhando quando longe e confirmando ataque apenas no range esperado. [ok]
5. Health Regen, Orb, death/respawn, stamina e kiting permaneceram preservados. [ok]

## 16) Implementacao - bloco 3
Data: 2026-05-11
Status: aplicado e aprovado em QA jogavel.

Escopo:
1. Criado `Scripts/actors/services/actor_runtime_state.gd`.
2. Movido para estado tipado somente o bloco social/wander/emote:
   - `idle_elapsed_sec`
   - `next_wander_delay_sec`
   - `next_look_allowed_sec`
   - `next_wander_emote_allowed_sec`
   - `next_stamina_exhausted_emote_allowed_sec`
   - `emote_request_id`
   - `current_emote_priority`
3. Removidos `_bridge_get_float_state/_bridge_set_float_state`.
4. Removidos `_bridge_get_int_state/_bridge_set_int_state`.
5. `actor_8dir_limbo.gd` reduziu de 566 para 516 linhas.

Contrato preservado:
1. `ActorRuntimeBridge` manteve os mesmos metodos publicos usados por `ActorWanderRuntime`, `ActorSocialRuntime` e `ActorPerceptionRuntime`.
2. Nenhuma cena, BT `.tres`, HSM, Orb, Health Regen, stamina, kiting, targeting, combat target ou navigation foi alterado.
3. `_combat_target`, `_interaction_target`, `_is_dead`, `_stats` e `_next_chase_repath_sec` ficaram fora deste bloco por serem estado sensivel de combate/lifecycle/navegacao.

Validacao inicial:
1. Scripts abriram no Godot sem parse error. [ok]
2. Smoke MCP abriu `mundo.tscn`, rodou a cena e nao apontou runtime error novo. [ok]
3. Logs de QA preservaram ataque, range, kiting, stamina, death/respawn, Health Regen, Orb, move e inspect. [ok]
4. QA visual confirmou emotion de assobio e emotion de exclamacao aparecendo corretamente. [ok]

## 17) Fechamento parcial da sprint
Data: 2026-05-11
Status: congelado.

Resumo:
1. `actor_8dir_limbo.gd` reduziu de 633 para 516 linhas sem remover API publica usada por BT/HSM/Controller/Orb.
2. Bloco de stamina/attack resource extraido.
3. Bloco espacial/range extraido.
4. Bloco social/wander/emote state tipado.
5. Telemetria de kiting ajustada sem editar BT `.tres`.
6. Camera do Player ajustada para `Camera2D.zoom = Vector2(3, 3)` em commit separado de tuning visual.

Validacao:
1. Logs de QA confirmaram ataque, range, kiting, stamina, death/respawn, Health Regen, Orb, move e inspect.
2. Clique no chao preservado: `InteractionResolver.resolve_primary()` retorna `move` quando nao ha alvo, `PlayerController` chama `_cancel_all_intents()`, e `ActorTargetingRuntime.cancel_all_intents()` limpa interacao e chama `cancel_chase_attack(reason)`.
3. QA visual confirmou sem regressao, incluindo emotions de assobio e exclamacao.
4. Smoke final MCP abriu e rodou `res://cenas/mundo.tscn` sem parse/runtime error novo. [ok]
5. Branch estava limpa e sincronizada antes deste fechamento.

Proxima sprint recomendada:
1. Abrir branch nova para `Actor Export/Profile Organization v1`.
2. Antes de migrar qualquer export, classificar tuning visual/design versus runtime state.
3. Nao mover dados de cena sem QA visual e sem plano de rollback.
