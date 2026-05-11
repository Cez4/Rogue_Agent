# Plano Sprint - Actor Export/Profile Organization v1

Data: 2026-05-11
Status: INICIADA - AUDITORIA SEM MIGRACAO DE DADOS
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
- [ ] Mapear consumidores reais de cada export.
- [ ] Classificar cada export como `scene_wiring`, `identity`, `animation_profile`, `social_profile`, `combat_profile`, `fallback_stat`, `runtime_only`.

### Fase B - Criar perfil social/wander sem migrar cena
- [ ] Criar `ActorSocialProfile` ou nome equivalente.
- [ ] Incluir apenas look/wander/stamina feedback visual.
- [ ] Implementar runtime leitor com fallback para exports atuais.
- [ ] Nao remover exports ainda.
- [ ] Validar scripts no Godot.

### Fase C - Instanciar perfil em uma entidade de baixo risco
- [ ] Escolher entidade piloto, preferencia `Villager1` ou cena isolada.
- [ ] Criar `.tres` via Godot/editor, nao por texto.
- [ ] Migrar valores apenas pelo editor/API segura.
- [ ] QA visual: assobio, exclamacao, wander, inspect.
- [ ] Se regressao visual, reverter somente o bloco piloto.

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
Mapear consumidores reais dos exports sociais e criar `ActorSocialProfile` com fallback sem migrar cenas. Esse bloco deve alterar apenas scripts e docs; dados de cena ficam para fase piloto.
