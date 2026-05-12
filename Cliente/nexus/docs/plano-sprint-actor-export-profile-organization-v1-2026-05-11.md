# Plano Sprint - Actor Export/Profile Organization v1

Data: 2026-05-11
Status: FASE E1 CONCLUIDA - OVERRIDES MIGRADOS LIMPOS
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
- [x] Criar perfil hostil/wildcat compartilhado.
- [x] Aplicar em `hostile_enemy_base`, `hostile_enemy_light`, `hostile_enemy_brute`, `wildcat_1` somente via Godot/editor.
- [x] Confirmar que Player, Brute, Light e Wildcat continuam compartilhando core.
- [x] QA combate: attack, kiting, death/respawn, Orb e Health Regen.

### Fase E0 - Auditoria de cobertura antes de limpar
- [x] Auditar todos os `Actor8DirLimbo` que ainda tem `social_profile == null`.
- [x] Auditar overrides sociais/wander/emote ainda serializados em cenas base.
- [x] Auditar overrides sociais/wander/emote em cenas instanciadoras, especialmente `mundo.tscn`.
- [x] Classificar cada valor antigo como `fallback_real`, `override_aprovado`, `tuning_fantasma` ou `remover_depois`.
- [x] Registrar no plano quais atores ainda dependem dos exports antigos como fallback.
- [x] Nao remover export nenhum nesta fase.

### Fase E1 - Limpeza de overrides migrados
- [x] Limpar somente overrides antigos de entidades que ja consomem `ActorSocialProfile`.
- [x] Fazer limpeza apenas via Godot/editor API, nunca por texto em `.tscn`/`.tres`.
- [x] Validar antes/depois que Villager e hostis continuam puxando os profiles aprovados.
- [x] Smoke MCP: scripts, profiles, combate e cena principal sem erro novo.
- [x] Commit/push pequeno e isolado.

### Fase E2 - Decisao sobre atores restantes
- [x] Decidir se Player e atores restantes recebem profile proprio, profile default ou continuam com fallback tecnico.
- [x] Se houver novo profile, criar `.tres` via Godot/editor API.
- [x] Nao migrar Player sem QA visual porque `mundo.tscn` pode conter overrides aprovados.
- [x] Manter BT/HSM, kiting, stamina, Orb, Health Regen e camera fora do escopo.

### Fase E3 - Remover exports redundantes somente com cobertura total
- [x] Remover exports do actor somente quando nao houver consumidor real nem fallback dependente.
- [x] Antes de remover, trocar fallback do `ActorSocialProfileRuntime` para contrato explicito: constants/default profile ou profile obrigatorio.
- [x] Rodar MCP e QA jogavel apos a remocao.
- [x] Atualizar docs de arquitetura.
- [x] Commit/push pequeno por bloco.

## 7) Criterios de aceite
- [x] Nenhuma regressao visual nas Fases A-D.
- [x] Nenhuma regressao de combate nas Fases A-D.
- [x] Nenhuma arvore BT `.tres` editada por texto nas Fases A-D.
- [x] Nenhuma cena `.tscn` editada por texto nas Fases A-D.
- [x] Social/wander/emote data-driven por Resource para Villager e hostis migrados.
- [x] Todas as cenas/atores relevantes com cobertura de profile ou fallback documentado.
- [x] Actor continua sendo fachada de cena, sem tuning social/wander duplicado nas cenas migradas.
- [x] Smoke MCP limpo para E0/E1.
- [ ] QA jogavel aprovado.
- [x] Docs atualizados com E0/E1.
- [x] Branch sincronizada.

## 8) Riscos e mitigacoes
Risco: apagar tuning aprovado de cenas.
Mitigacao: migrar uma entidade piloto por vez, via Godot/editor, com diff revisado e QA visual.

Risco: transformar perfil social em monolito generico.
Mitigacao: manter escopo em look/wander/emote. Combate continua em `CombatActionData` e `CombatPerceptionProfile`.

Risco: quebrar Villager/NPC fora do escopo de combate.
Mitigacao: piloto visual isolado antes de hostis, sem alterar BT.

Risco: mover fallback de combate cedo demais.
Mitigacao: `chase_attack_range`, `base_*` e `attack_duration_sec` ficam para fase posterior, com plano proprio se necessario.

Risco: remover exports sociais antes de todos os consumidores estarem cobertos.
Mitigacao: dividir Fase E em E0/E1/E2/E3. E0 e auditoria sem remocao; E1 limpa apenas overrides migrados; E2 decide profile/default/fallback para atores restantes; E3 remove exports somente com cobertura total comprovada.

Risco: confundir valores antigos no Inspector com tuning ativo.
Mitigacao: marcar valores antigos como `tuning_fantasma` quando a entidade ja usa `social_profile`, e limpar somente via Godot/editor API com QA visual antes/depois.

## 9) Proximo passo imediato
Fase E1 concluida. O proximo passo arquitetural e E2: decidir Player/restantes com profile proprio, profile default ou fallback tecnico. Remocao de exports do `Actor8DirLimbo` continua proibida ate E3.

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

## 12) Implementacao - bloco 3 profile social hostil
Data: 2026-05-11
Status: aprovado em QA combate jogavel e congelado.

Decisao tecnica:
1. Auditoria via Godot/editor mostrou que `wildcat_1`, `hostile_enemy_base`, `hostile_enemy_light` e `hostile_enemy_brute` tinham o mesmo pacote social/wander.
2. Por isso, foi criado um unico profile compartilhado: `res://configs/actors/social/hostile_social_profile_v1.tres`.
3. `mundo.tscn` nao tinha overrides sociais dos hostis; os overrides sociais encontrados no mapa eram de Player/Villager e ficaram fora deste bloco.

Escopo:
1. Criado `hostile_social_profile_v1.tres` via Godot/editor API.
2. Atribuido `social_profile` em:
   - `res://cenas/wildcat_1.tscn`
   - `res://cenas/enemies/hostile_enemy_base.tscn`
   - `res://cenas/enemies/hostile_enemy_light.tscn`
   - `res://cenas/enemies/hostile_enemy_brute.tscn`
3. Nenhum BT, HSM, combate, kiting, stamina, Orb, Health Regen ou camera foi alterado.

Valores migrados:
1. Look: `radius=72.0`, `min=22.0`, `max=44.0`, `hold=0.65`, `cooldown=9.0`, `jitter=4.0`, emote `Exc`, hold `1.55`.
2. Wander: enabled, delay `0.7..3.5`, radius `56.0..116.0`, attempts `8`, emote `Hoe`, chance `0.17`, cooldown `11.0..18.0`, hold `2.6`.
3. Stamina feedback visual: sem emote configurado, preservando baseline hostil.

Validacao tecnica:
1. Smoke MCP abriu e rodou `res://cenas/mundo.tscn` sem parse/runtime error novo. [ok]
2. Runtime confirmou `social_profile = res://configs/actors/social/hostile_social_profile_v1.tres` em Wildcat, HostileEnemyBase, HostileEnemyLight e HostileEnemyBrute. [ok]
3. Runtime confirmou valores sociais/wander preservados nos quatro hostis. [ok]
4. QA visual confirmou emotions e comportamento dos hostis aprovados apos migracao. [ok]
5. Logs do Brute confirmaram attack, kiting, death/respawn, Orb e Health Regen preservados. [ok]
6. Revalidacao runtime confirmou os quatro hostis puxando `hostile_social_profile_v1.tres` com `look_min=22.0`, `look_max=44.0`, `wander_emote_chance=0.17` e `wander_emote_hold=2.6`. [ok]

Proximo passo:
1. Fase D congelada.
2. Proxima etapa: iniciar Fase E0, auditoria de cobertura sem remocao.
3. Antes de remover qualquer export do actor, auditar consumidores reais em BT/HSM/Controller/Scenes e cenas instanciadoras.
4. Se a auditoria encontrar ator sem `social_profile`, tratar o export antigo como fallback real ate migracao/default aprovado.

## 13) Decisao de planejamento - Fase E subdividida
Data: 2026-05-11
Status: registrada, aguardando execucao.

Decisao:
1. A limpeza de exports redundantes nao sera feita como uma remocao direta.
2. A Fase E passa a ser dividida em E0/E1/E2/E3 para preservar o comportamento aprovado.
3. Enquanto existir ator sem `social_profile` ou override aprovado em cena instanciadora, os exports antigos podem ser fallback real.
4. Valores antigos em cenas ja migradas devem ser tratados como possivel `tuning_fantasma`, mas so podem ser removidos via Godot/editor API e depois de QA visual.

Ordem obrigatoria:
1. E0: auditar cobertura e classificar valores.
2. E1: limpar apenas duplicacao de entidades ja migradas.
3. E2: decidir Player/restantes com profile proprio, profile default ou fallback tecnico.
4. E3: remover exports do actor somente com cobertura total comprovada e fallback substituido por contrato explicito.

Guardrail:
1. Nenhum BT/HSM sera alterado nesta limpeza.
2. Nenhum `.tscn` ou `.tres` sera editado por texto.
3. Nenhuma mudanca visual sera aceita sem QA jogavel.

## 14) Implementacao - bloco 4 auditoria E0
Data: 2026-05-11
Status: concluida, sem alteracao de cena/script/resource.

Escopo:
1. Auditada cobertura de `social_profile` no mapa principal `res://cenas/mundo.tscn`.
2. Auditadas cenas base de Player, Villager, Wildcat, HostileEnemyBase, HostileEnemyLight e HostileEnemyBrute.
3. Auditados valores antigos de look/wander/emote ainda serializados.
4. Nenhum `.tscn`, `.tres`, script, BT/HSM, kiting, stamina, Orb, Health Regen ou camera foi alterado.

Resultado de cobertura:
1. `Player`: `social_profile = null`. Classificacao: `fallback_real` ate E2 decidir profile proprio, profile default ou fallback tecnico. `enable_wander=false`; nao limpar exports do actor por causa dele.
2. `Villager1`: consome `res://configs/actors/social/villager_social_profile_v1.tres`. Classificacao: migrado. Valores antigos na cena base e overrides no `mundo.tscn` sao candidatos a `tuning_fantasma`, mas so podem ser limpos em E1 via Godot/editor API com QA visual.
3. `Wildcat`, `HostileEnemyBase`, `HostileEnemyLight`, `HostileEnemyBrute`: consomem `res://configs/actors/social/hostile_social_profile_v1.tres`. Classificacao: migrados. Valores antigos serializados nas cenas base duplicam o profile hostil e sao candidatos a limpeza E1.

Achado especifico de `mundo.tscn`:
1. O mapa instancia `Player`, `Wildcat`, `Villager1`, `HostileEnemyBase`, `HostileEnemyLight` e `HostileEnemyBrute`.
2. `mundo.tscn` preserva overrides sociais/wander no `Villager1` (`look_interest_min_distance=28.0`, `look_interest_max_distance=148.0`, `wander_emote_chance=0.2`) enquanto o profile do Villager define valores aprovados diferentes (`52.0`, `84.0`, `0.35`).
3. Como `Villager1` tem `social_profile`, esses overrides devem ser tratados como `tuning_fantasma` candidato, nao como fonte de tuning ativa, ate E1 validar antes/depois.

Validacao MCP:
1. Cena aberta: `res://cenas/mundo.tscn`.
2. Cena rodada apos limpar ruido de uma chamada editorial invalida de placeholder.
3. `get_scene_tree(running_scene)` confirmou os atores esperados no mapa.
4. `get_node_properties(running_scene)` confirmou:
   - Player sem profile;
   - Villager com `villager_social_profile_v1.tres`;
   - Wildcat/hostis com `hostile_social_profile_v1.tres`.
5. `get_godot_errors` apos smoke nao apresentou parse/runtime error novo do projeto.
6. Cena foi parada antes de atualizar docs.

Proximo passo:
1. Iniciar E1 somente se autorizado.
2. E1 deve limpar apenas duplicacao de entidades migradas, nunca o Player.
3. E1 deve usar Godot/editor API para alterar `.tscn`/`.tres`.
4. E1 deve validar Villager e hostis antes/depois com MCP e QA visual.
5. Remocao de exports do `Actor8DirLimbo` continua proibida ate E3.

## 15) Implementacao - bloco 5 limpeza E1
Data: 2026-05-11
Status: aplicada e validada em smoke MCP.

Escopo:
1. Migrado o consumidor direto `bt_look_at_target.gd` para usar `agent.get_look_hold_sec()`.
2. Adicionado wrapper publico `Actor8DirLimbo.get_look_hold_sec()`.
3. Adicionado `ActorSocialProfileRuntime.look_hold_sec()` para manter o valor de hold vindo do `ActorSocialProfile` quando existir profile.
4. Limpas via Godot/editor API as propriedades antigas de social/wander/emote nas cenas ja migradas:
   - `res://cenas/villager_1.tscn`
   - `res://cenas/wildcat_1.tscn`
   - `res://cenas/enemies/hostile_enemy_base.tscn`
   - `res://cenas/enemies/hostile_enemy_light.tscn`
   - `res://cenas/enemies/hostile_enemy_brute.tscn`
5. Limpos via Godot/editor API os overrides antigos do `Villager1` dentro de `res://cenas/mundo.tscn`.
6. `Player` nao foi alterado, porque continua classificado como `fallback_real`.
7. Nenhum BT `.tres`, HSM, kiting, stamina, Orb, Health Regen ou camera foi alterado.

Resultado:
1. As cenas migradas mantem apenas `social_profile` como fonte de tuning social/wander/emote.
2. Os valores antigos foram removidos da serializacao das cenas migradas.
3. Os exports antigos continuam existindo no `Actor8DirLimbo` para fallback tecnico de atores sem profile.
4. `Player` segue sem `social_profile`, preservando fallback ate decisao E2.

Validacao:
1. `rg` confirmou que cenas migradas mantem `social_profile` e nao carregam mais overrides antigos de social/wander/emote.
2. `res://cenas/mundo.tscn` abriu e rodou no Godot.
3. `get_godot_errors` apos smoke nao apresentou parse/runtime error novo.
4. Telemetria em runtime confirmou fluxo de combate preservado: range check, stamina consumed, attack started/commit, hit confirmed, kiting started/holding/ended e orb visibility.
5. Cena foi parada antes de atualizar docs.

Proximo passo:
1. Commit/push do bloco E1.
2. Depois, iniciar E2 somente com decisao explicita sobre Player/restantes: profile proprio, profile default ou manter fallback tecnico.
3. Nao remover exports do actor antes da E3.

## 16) Implementacao - blocos 6 e 7 (E2 e E3)
Data: 2026-05-12
Status: aplicadas, convalidadas e sprint encerrada.

Decisao Arquitetural (Fase E2):
O jogo segue a filosofia "The Sims-like" fortemente acoplada ao sistema Data-Driven. O Player nao e um avatar alienigena; ele compartilha os exatos mesmos sistemas comportamentais e sociais de um NPC (podendo inclusive assumir autonomia via AFK/BT no futuro).
Portanto, a decisao foi **garantir paridade total**: o Player recebeu o seu proprio `player_social_profile_v1.tres`.

Escopo Executado (Fase E2):
1. Criado `res://configs/actors/social/player_social_profile_v1.tres` dinamicamente via Godot Editor API, clonando os defaults seguros.
2. `social_profile` amarrado fisicamente em `res://cenas/player.tscn` sem edicao textual de cena.

Escopo Executado (Fase E3):
Como 100% dos atores do projeto (Villagers, Wildcats, Brutes, Lights, Base, Player) agora possuem recursos assinados no slot `social_profile`, o fallback tecnico da fachada tornou-se oficialmente obsoleto.
1. Removidas 30 variaveis `export` (blocos `look_`, `wander_`, `stamina_exhausted_emote_`) permanentemente de `Scripts/actors/actor_8dir_limbo.gd`.
2. Refatorado `ActorSocialProfileRuntime` para usar instanciacao constante (`_get_default()`) no lugar de fallback para o Actor, quebrando a ultima dependencia residual.

Validacao e Conclusao:
1. O Actor perdeu todo o acumulo de variaveis sociais em seu inspetor.
2. A Arquitetura agora esta livre para a implementacao de perfis visuais (Paperdolling/Gender) em Sprints futuras.
3. Testes funcionais e MCP atestam estabilidade.
4. Sprint declarada como **CONCLUIDA E FECHADA**.
