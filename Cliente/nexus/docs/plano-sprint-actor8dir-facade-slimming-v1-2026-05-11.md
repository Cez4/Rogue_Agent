# Plano Sprint - Actor8Dir Facade Slimming v1

Data: 2026-05-11
Status: ATIVA - BASELINE LIMPO
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
- [ ] Validar kiting/attack no MCP.

### Fase C - Extrair spatial/combat geometry
- [ ] Criar `actor_spatial_runtime.gd` ou equivalente.
- [ ] Mover `get_min_separation_distance_to()`.
- [ ] Mover `compute_approach_position()`.
- [ ] Mover `get_attack_engage_distance()`.
- [ ] Validar chase, range e sem "air attack".

### Fase D - Reduzir bridge ruidoso
- [ ] Auditar `_bridge_get_float_state/_set_float_state`.
- [ ] Auditar `_bridge_get_int_state/_set_int_state`.
- [ ] Avaliar `ActorRuntimeState` como Resource/RefCounted interno.
- [ ] Migrar somente se reduzir acoplamento sem quebrar assinatura dos runtimes.
- [ ] Nao trocar tudo de uma vez.

### Fase E - Organizar exports por perfil
- [ ] Identificar exports que sao tuning de design.
- [ ] Identificar exports que deveriam viver em `CombatPerceptionProfile`, `CombatActionData` ou futuro profile social/wander.
- [ ] Nao migrar dados de cena sem QA visual.
- [ ] Criar plano separado se a migracao de dados for grande.

### Fase F - Validacao MCP e telemetria
- [x] `open_scene(res://cenas/mundo.tscn)`.
- [x] `play_scene(current)`.
- [ ] Testar Player vs Brute com spam de ataque.
- [ ] Testar clique no chao cancelando combate.
- [ ] Testar baixa stamina/kiting.
- [ ] Testar death/respawn.
- [x] `get_godot_errors` sem erro novo.
- [ ] Logs esperados preservados: `attack_commit`, `hit_confirmed`, `kiting_started`, `kiting_ended`, `target_died`, `respawned`.

### Fase G - Documentacao e Git
- [ ] Atualizar docs de arquitetura.
- [ ] Atualizar checklist se algum contrato mudar.
- [ ] Atualizar freeze somente se baseline funcional mudar.
- [ ] Commit pequeno por bloco.
- [ ] Push e sync confirmado.

## 9) Criterios de aceite
- [x] Health Regen ja esta concluido antes desta sprint iniciar.
- [x] `actor_8dir_limbo.gd` ficou menor sem perder contrato publico usado por BT/HSM/Controller.
- [ ] Nenhum comportamento aprovado do combate mudou.
- [ ] Nenhuma arvore `.tres` foi editada por texto.
- [ ] Player, Brute, Light e Wildcat continuam compartilhando core.
- [ ] Kiting data-driven continua consumindo `CombatActionData`.
- [ ] Orb continua funcional.
- [ ] Sem parse/runtime error novo no Godot.
- [ ] Docs atualizados na mesma entrega.

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
- [ ] Sprint concluida
- [ ] QA aprovou sem regressao visual
- [ ] MCP limpo
- [ ] Docs atualizados
- [ ] Commit/push sincronizado

## 13) Implementacao - bloco 1
Data: 2026-05-11

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
