# Plano Sprint - Actor Export/Profile Organization v1

Data: 2026-05-11
Status: FASE C PILOTO CONGELADA - VILLAGER SOCIAL PROFILE
Branch: `feat/actor-export-profile-organization-v1`
Base obrigatoria: `plano-sprint-actor8dir-facade-slimming-v1-2026-05-11.md` fechado parcialmente e congelado.

## 1) Objetivo
Organizar os exports remanescentes de `Actor8DirLimbo` por responsabilidade, preservando comportamento aprovado e preparando a fachada para novos perfis de ator sem duplicar tuning em cena.

O objetivo nao e remover todos os exports. O objetivo e separar:

1. Identidade/scene wiring que deve continuar no actor.
2. Tuning de design que deve ir para `Resource` data-driven.
3. Fallback tecnico que deve permanecer como default seguro ate migracao validada.
4. Estado runtime que nao deve ser export.

## 2) Estado de partida
1. `Actor8DirLimbo` foi reduzido de 633 para 516 linhas.
2. Stamina/attack resource esta em runtime dedicado.
3. Geometria/range esta em runtime dedicado.
4. Estado social/wander/emote esta em `ActorRuntimeState`.
5. `CombatActionData` ja concentra acao, stamina de ataque, kiting e dano.
6. `CombatPerceptionProfile` ja concentra acquire/lose/memory/reacquire/attack stop buffer.
7. Fase E do slimming foi diferida para esta sprint porque pode mexer em dados de cena/tuning visual.

## 3) Guardrails obrigatorios
1. Nao editar `.tscn`/`.tres` por texto.
2. Nao migrar valores de cena sem QA visual antes/depois.
3. Nao alterar BT/HSM.
4. Nao alterar kiting, stamina, Orb, Health Regen ou camera nesta sprint sem bug comprovado.
5. Nao criar singleton global.
6. Nao criar script especifico por inimigo.
7. Manter wrappers publicos no actor enquanto houver consumidor real.
8. Cada bloco deve ter smoke MCP e, se houver migracao de dados, QA jogavel.

## 4) Auditoria inicial de exports
### Deve permanecer no actor por enquanto
1. Scene wiring:
   - `movement_config`
   - `equipment_loadout`
   - `combat_perception_profile`
2. Identidade/controle:
   - `player_controlled`
   - `is_hostile`
   - `use_bt_brain`
3. Prefixos de animacao, ate existir perfil visual/animation:
   - `idle_prefix`
   - `walk_prefix`
   - `attack_prefix`
   - `die_prefix`
4. Lifecycle:
   - `enable_respawn`
   - `respawn_delay_sec`
   - `respawn_brain_delay_sec`

### Candidatos fortes a novo Resource social/wander
1. Look/social:
   - `look_interest_radius`
   - `look_interest_min_distance`
   - `look_interest_max_distance`
   - `look_hold_sec`
   - `look_cooldown_sec`
   - `look_cooldown_jitter_sec`
   - `look_emote_name`
   - `look_emote_hold_sec`
2. Wander:
   - `enable_wander`
   - `wander_delay_min_sec`
   - `wander_delay_max_sec`
   - `wander_radius_min`
   - `wander_radius_max`
   - `wander_max_attempts`
   - `wander_emote_name`
   - `wander_emote_chance`
   - `wander_emote_min_cooldown_sec`
   - `wander_emote_max_cooldown_sec`
   - `wander_emote_hold_sec`
3. Stamina feedback visual:
   - `stamina_exhausted_emote_name`
   - `stamina_exhausted_emote_hold_sec`
   - `stamina_exhausted_emote_cooldown_sec`

### Candidatos a revisar com cuidado
1. Combat fallback:
   - `chase_attack_range`
   - `base_attack_stop_buffer`
   - `base_attack_range_bonus`
   - `base_attack_range_multiplier`
2. Perception fallback:
   - `base_perception_radius`
   - `base_perception_min_distance`
   - `base_perception_max_distance`
3. Interaction/chase:
   - `interaction_stop_range`
   - `chase_repath_interval_sec`
4. Ataque legado:
   - `attack_duration_sec`

## 5) Evidencia de duplicacao atual
1. `wildcat_1.tscn`, `hostile_enemy_base.tscn`, `hostile_enemy_light.tscn` e `hostile_enemy_brute.tscn` repetem valores de look/wander muito parecidos.
2. `villager_1.tscn` tem pacote proprio de look/wander.
3. `player.tscn` concentra perfil visual/animacao do Player e respawn.
4. `mundo.tscn` possui overrides de look/wander herdados em instancia, o que exige cuidado para nao apagar tuning aprovado.

## 6) Plano de execucao
### Fase A - Auditoria e mapa de propriedade
- [x] Criar branch dedicada.
- [x] Auditar exports do actor.
- [x] Auditar Resources existentes.
- [x] Auditar overrides em cenas.
- [x] Mapear consumidores reais de cada export social/wander/emote.
- [x] Classificar cada export como `scene_wiring`, `identity`, `animation_profile`, `social_profile`, `combat_profile`, `fallback_stat`, `runtime_only`.

### Fase B - Criar perfil social/wander sem migrar cena
- [x] Criar `ActorSocialProfile` ou nome equivalente.
- [x] Incluir apenas look/wander/stamina feedback visual.
- [x] Implementar runtime leitor com fallback para exports atuais.
- [x] Nao remover exports ainda.
- [x] Validar scripts no Godot.

### Fase C - Instanciar perfil em uma entidade de baixo risco
- [x] Escolher entidade piloto, preferencia `Villager1` ou cena isolada.
- [x] Criar `.tres` via Godot/editor, nao por texto.
- [x] Migrar valores apenas pelo editor/API segura.
- [x] QA visual: assobio, exclamacao, wander, inspect.
- [x] Se regressao visual, reverter somente o bloco piloto.

### Fase D - Migrar hostis somente apos piloto aprovado
- [ ] Criar perfil hostil/wildcat compartilhado.
- [ ] Aplicar em `hostile_enemy_base`, `hostile_enemy_light`, `hostile_enemy_brute`, `wildcat_1` somente via Godot/editor.
- [ ] Confirmar que Player, Brute, Light e Wildcat continuam compartilhando core.
- [ ] QA combate: attack, kiting, death/respawn, Orb e Health Regen.

### Fase E - Limpar exports redundantes
- [ ] Remover exports do actor somente quando todas as cenas consumirem profile.
- [ ] Manter compatibilidade se alguma cena ainda nao tiver profile.
- [ ] Atualizar docs de arquitetura.
- [ ] Commit/push pequeno por bloco.

## 7) Criterios de aceite
- [ ] Nenhuma regressao visual.
- [ ] Nenhuma regressao de combate.
- [ ] Nenhuma arvore BT `.tres` editada por texto.
- [ ] Nenhuma cena `.tscn` editada por texto.
- [ ] Social/wander/emote data-driven por Resource.
- [ ] Actor continua sendo fachada de cena, nao deposito de tuning duplicado.
- [ ] Smoke MCP limpo.
- [ ] QA jogavel aprovado.
- [ ] Docs atualizados.
- [ ] Branch sincronizada.

## 8) Riscos e mitigacoes
Risco: apagar tuning aprovado de cenas.
Mitigacao: migrar uma entidade piloto por vez, via Godot/editor, com diff revisado e QA visual.

Risco: transformar perfil social em monolito generico.
Mitigacao: manter escopo em look/wander/emote. Combate continua em `CombatActionData` e `CombatPerceptionProfile`.

Risco: quebrar Villager/NPC fora do escopo de combate.
Mitigacao: piloto visual isolado antes de hostis, sem alterar BT.

Risco: mover fallback de combate cedo demais.
Mitigacao: `chase_attack_range`, `base_*` e `attack_duration_sec` ficam para fase posterior, com plano proprio se necessario.

## 9) Proximo passo imediato
Bloco 1 congelado. O proximo passo e iniciar a Fase C com uma entidade piloto de baixo risco, criando o `.tres` pelo Godot/editor e migrando somente os dados sociais/wander/emote dessa entidade antes de qualquer migracao hostil.

## 10) Implementacao - bloco 1
Data: 2026-05-11
Status: aplicado, validado em QA jogavel e congelado.

Escopo:
1. Criado `Scripts/actors/profiles/actor_social_profile.gd`.
2. Criado `Scripts/actors/services/actor_social_profile_runtime.gd`.
3. Adicionado `social_profile: Resource` em `Actor8DirLimbo`.
4. `ActorSocialRuntime`, `ActorWanderRuntime`, `ActorPerceptionRuntime` e `ActorSetupRuntime` passaram a ler look/wander/stamina feedback pelo runtime de profile.
5. Nenhum `.tscn`, `.tres`, BT, HSM, Orb, Health Regen, stamina, kiting ou camera foi alterado.

Contrato de compatibilidade:
1. Nenhuma cena recebeu `social_profile` ainda.
2. Enquanto `social_profile == null`, os valores continuam vindo dos exports atuais do actor.
3. Para look distance, o fallback preserva o comportamento anterior baseado em `get_perception_min_distance()`, `get_perception_max_distance()` e stat `perception_radius`.
4. Os exports antigos permanecem no actor para evitar regressao e permitir migracao gradual.

Validacao inicial:
1. Scripts abriram no Godot sem parse error. [ok]
2. Smoke MCP abriu e rodou `res://cenas/mundo.tscn` sem parse/runtime error novo. [ok]
3. Cena foi parada antes de atualizar docs. [ok]
4. QA visual confirmou assobio, exclamacao e wander preservados sem `social_profile` atribuido. [ok]
5. Logs de QA preservaram attack/range/kiting/stamina/death/respawn/Orb/Health Regen/move sem erro novo. [ok]

Proximo passo:
1. Iniciar Fase C somente com entidade piloto.
2. Preferencia tecnica: `Villager1` ou cena isolada, porque valida social/wander/inspect com menor risco sobre combate.
3. Criar e atribuir profile via Godot/editor, sem edicao textual de `.tscn` ou `.tres`.
4. Se houver regressao visual, reverter apenas o bloco piloto.

## 11) Implementacao - bloco 2 piloto Villager1
Data: 2026-05-11
Status: aprovado em QA visual jogavel e congelado.

Referencias oficiais consultadas:
1. Godot 4.6 `ResourceSaver`: salvar `Resource` em disco via `ResourceSaver.save()`.
2. Godot 4.6 `ResourceLoader`: carregar `Resource` pelo path reconhecido pela engine.
3. Godot 4.6 `Object`: checagem dinamica de propriedades antes de `get()` em objeto/resource dinamico.

Escopo:
1. Endurecido `ActorSocialProfileRuntime._profile_value()` para cair no fallback se `social_profile` for nulo, invalido ou sem a propriedade solicitada.
2. Criado `res://configs/actors/social/villager_social_profile_v1.tres` via Godot/editor API.
3. Copiados para o `.tres` os valores sociais/wander aprovados do `Villager1`.
4. Atribuido `social_profile` em `res://cenas/villager_1.tscn` via Godot/editor, sem edicao textual manual.
5. Nenhum BT, HSM, combate, kiting, stamina, Orb, Health Regen ou camera foi alterado.

Valores migrados:
1. Look: `radius=148.0`, `min=52.0`, `max=84.0`, `hold=1.1`, `cooldown=8.0`, `jitter=3.0`, emote `Exc`, hold `1.9`.
2. Wander: enabled, delay `1.8..4.5`, radius `24.0..96.0`, attempts `12`, emote `Hoe`, chance `0.35`, cooldown `8.0..14.0`, hold `3.0`.
3. Stamina feedback visual: sem emote configurado, preservando baseline do Villager.

Validacao tecnica:
1. Script abriu no Godot sem parse error. [ok]
2. Primeiro smoke detectou UID de resource ainda nao registrado; corrigido via `ResourceSaver.set_uid()` e revalidado. [ok]
3. Smoke MCP abriu e rodou `res://cenas/mundo.tscn` sem parse/runtime error novo. [ok]
4. `Villager1` em runtime carregou `social_profile = res://configs/actors/social/villager_social_profile_v1.tres`. [ok]
5. QA visual confirmou `Hoe`/assobio, `Exc`/exclamacao, wander e inspect preservados. [ok]
6. Logs de QA registraram `inspect` no `Villager1` e comandos `move`, sem parse/runtime error novo. [ok]

Proximo passo:
1. Fase C congelada.
2. Proxima etapa autorizada: Fase D, migrar hostis somente apos criar perfil compartilhado e validar em QA de combate.
3. Manter guardrail: nenhum hostile deve ser migrado sem smoke MCP e teste de attack/kiting/death/respawn/Orb/Health Regen.
