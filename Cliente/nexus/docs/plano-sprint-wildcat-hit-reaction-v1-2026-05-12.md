# Plano Sprint - Wildcat / Hostile Hit Reaction v1

Data: 2026-05-12
Status: HOSTILE COVERAGE CONCLUIDO E CONGELADO - FREEZE V9
Base obrigatoria: `status-freeze-funcional-v7-hit-reaction-2026-05-12.md`

## 1) Objetivo
Propagar o sistema Universal Hit Reaction V7 do Player para o Wildcat e, depois, para hostis derivados/copiados (`HostileEnemyBase`, `HostileEnemyLight`, `HostileEnemyBrute`) sem regredir combate, knockback, stamina, kiting, orb ou arquitetura data-driven.

O comportamento aprovado no Player deve ser preservado:

1. Dano entra via `HealthComponent.damaged`.
2. `HitReactionComponent` dispara `hit_reaction!` na HSM.
3. `HitReactionState` toca animacao direcional de dano.
4. Animacao toca inteira quando `use_animation_length = true`.
5. Orientacao visual olha para a origem do golpe, nao para a direcao do knockback.
6. `combat_target` nao e limpo.

## 2) Auditoria Inicial
Estado observado no worktree:

1. `res://cenas/wildcat_1.tscn` esta modificado localmente pelo diretor.
2. A cena `wildcat_1.tscn` recebeu:
   - `res://Assets/Char/WildCat/TakeDamage.png`;
   - animacoes `TakeDamage_L`, `TakeDamage_N`, `TakeDamage_NE`, `TakeDamage_NO`, `TakeDamage_O`, `TakeDamage_S`, `TakeDamage_SE`, `TakeDamage_SO`;
   - `AnimatedSprite2D.animation = &"TakeDamage_NE"` no estado salvo atual.
3. `HostileEnemyBase`, `HostileEnemyLight` e `HostileEnemyBrute` usam os mesmos textures base do WildCat para `Attack1`, `Die`, `Idle` e `Walk`.
4. Porem, os hostis possuem arquivos `.tscn` independentes com `SpriteFrames_icon` serializado dentro de cada cena.
5. Nao ha heranca viva via `instance=wildcat_1.tscn` nos arquivos de hostis analisados.
6. Portanto, adicionar `TakeDamage_*` no `wildcat_1.tscn` nao propaga automaticamente para `hostile_enemy_base.tscn`, `hostile_enemy_light.tscn` ou `hostile_enemy_brute.tscn`.

## 3) Decisao Arquitetural
A sprint deve ser executada em duas camadas:

1. **Camada Wildcat canonical local:**
   - usar `wildcat_1.tscn` como primeiro alvo visual porque ja possui as animacoes `TakeDamage_*`.
   - adicionar `HitReactionComponent`;
   - adicionar `LimboHSM/HitReactionState`;
   - usar profile com `animation_prefix = &"TakeDamage"`.

2. **Camada Hostile templates:**
   - auditar se cada hostile possui ou nao `TakeDamage_*`;
   - se nao possuir, escolher uma das estrategias:
     - copiar as animacoes `TakeDamage_*` para cada cena via Godot/editor API;
     - ou extrair um template/base visual compartilhado em sprint futura;
     - ou aplicar `no_hit_reaction_profile_v1.tres`/fallback ate os assets entrarem em cada cena.

## 4) Viabilidade Tecnica
Viavel com baixo risco se a execucao for em blocos.

O sistema V7 ja foi desenhado para isso:

1. `HitReactionComponent` e copiavel para qualquer ator com `HealthComponent` e `LimboHSM`.
2. `HitReactionState` e reutilizavel sem script exclusivo de Player.
3. `HitReactionProfile` controla prefixo e duracao por dados.
4. `Actor8DirLimbo` ja possui wiring generico:
   - se existir `LimboHSM/HitReactionState`, registra transicao `ANYSTATE -> HitReactionState`;
   - se existir `HitReactionComponent`, bloqueia ataque/movimento durante hit reaction.
5. BT ja respeita `HitReactionComponent.is_reacting()`.
6. `ActorRuntimeBridge.play_directional()` ja evita sobrescrever a animacao durante a reacao.

## 5) Risco Principal
O risco nao e codigo. O risco e **template/cena**.

Hoje os hostis parecem ser copias/variações independentes, nao instancias herdadas do `wildcat_1.tscn`. Isso significa:

1. mudar o Wildcat nao atualiza automaticamente Base/Light/Brute;
2. cada hostile pode ter `SpriteFrames_icon` proprio;
3. cada hostile precisa receber `TakeDamage_*` ou usar fallback;
4. editar `.tscn` por texto pode corromper ou gerar drift de cena;
5. o correto e usar Godot/editor API para adicionar componentes e animacoes.

## 6) Profiles Recomendados
Ja existem profiles hostis:

1. `res://configs/combat/hit_reaction/hostile_light_hit_reaction_profile_v1.tres`
2. `res://configs/combat/hit_reaction/hostile_brute_hit_reaction_profile_v1.tres`
3. `res://configs/combat/hit_reaction/no_hit_reaction_profile_v1.tres`

Recomendacao:

1. Criar/ajustar `wildcat_hit_reaction_profile_v1.tres` com:
   - `animation_prefix = &"TakeDamage"`;
   - `use_animation_length = true`;
   - cooldown curto anti-hitlock.
2. Ajustar profiles hostis para `animation_prefix = &"TakeDamage"` somente quando as cenas deles tiverem as animacoes.
3. Manter `no_hit_reaction_profile_v1.tres` para entidades sem asset visual ou chefes imunes.

## 7) Plano de Execucao

### Fase A - Auditoria Sem Alterar Cena
- [x] Confirmar `wildcat_1.tscn` abre no Godot sem erro apos as animacoes adicionadas.
- [x] Confirmar loops `TakeDamage_* = false`.
- [x] Medir duracao real das animacoes `TakeDamage_*`: 15 frames, 15 FPS, 1.0s por direcao.
- [x] Confirmar se `wildcat_1.tscn` esta sendo usado no mapa atual ou se os inimigos do QA usam `hostile_enemy_*`: `mundo.tscn` instancia `res://cenas/wildcat_1.tscn` como `Wildcat`; hostis continuam em cenas independentes.
- [x] Confirmar se `HostileEnemyBase`, `HostileEnemyLight` e `HostileEnemyBrute` possuem `TakeDamage_*`: continuam fora da implementacao Wildcat v1 porque nao herdam automaticamente as animacoes do `wildcat_1.tscn`.

### Fase B - Wildcat v1
- [x] Criar `wildcat_hit_reaction_profile_v1.tres`.
- [x] Adicionar `HitReactionComponent` em `wildcat_1.tscn` via Godot/editor API.
- [x] Adicionar `HitReactionState` em `wildcat_1.tscn` via Godot/editor API.
- [x] Conectar paths iguais ao Player:
  - `HitReactionComponent.profile`;
  - `HitReactionComponent.health_component_path`;
  - `HitReactionComponent.hsm_path`;
  - `HitReactionState.hit_reaction_component_path`.
- [x] Rodar `wildcat_1.tscn` e `mundo.tscn` sem parse/runtime error novo.
- [x] Confirmar em runtime que `/root/Mundo/Wildcat/HitReactionComponent` e `/root/Mundo/Wildcat/LimboHSM/HitReactionState` existem com paths corretos.
- [x] Confirmar telemetria de dano recebida pelo Wildcat em combate real.

### Fase C - Hostile Coverage
- [x] Decidir se hostis recebem as animacoes agora ou se ficam para sprint de template visual.
- [x] Se receberem agora:
  - adicionar `TakeDamage.png` e `TakeDamage_*` em cada hostile via Godot/editor API;
  - adicionar `HitReactionComponent`;
  - adicionar `HitReactionState`;
  - usar profile hostile adequado.
- [ ] Se nao receberem agora:
  - documentar que apenas Wildcat visual tem Hit Reaction v1;
  - manter hostis com profiles prontos mas sem componente/estado.
- [x] `HostileEnemyBase` recebeu 8 animacoes `TakeDamage_*`, `HitReactionComponent`, `LimboHSM/HitReactionState` e profile `hostile_light_hit_reaction_profile_v1.tres`.
- [x] `HostileEnemyLight` recebeu 8 animacoes `TakeDamage_*`, `HitReactionComponent`, `LimboHSM/HitReactionState` e profile `hostile_light_hit_reaction_profile_v1.tres`.
- [x] `HostileEnemyBrute` recebeu 8 animacoes `TakeDamage_*`, `HitReactionComponent`, `LimboHSM/HitReactionState` e profile `hostile_brute_hit_reaction_profile_v1.tres`.
- [x] `mundo.tscn` confirma que as instancias `HostileEnemyBase`, `HostileEnemyLight` e `HostileEnemyBrute` carregam componente e estado.
- [x] Confirmar telemetria de dano recebida por cada hostile em combate real.

### Fase D - QA
- [x] Godot MCP: abrir cena-alvo.
- [x] Rodar cena-alvo sem erro novo.
- [x] Rodar combate direcionado contra Wildcat.
- [x] Confirmar no log:
  - `hit_confirmed`;
  - `knockback_applied`;
  - `hit_reaction_requested`;
  - `hit_reaction_started`;
  - `hit_reaction_animation played=true`;
  - `duration` coerente com a animacao;
  - `hit_reaction_finished`;
  - alvo de combate preservado.
- [x] QA visual: Wildcat toca `TakeDamage_*` inteiro ao receber dano.
- [x] Confirmar sem regressao de ataque, kiting, stamina, orb e regen.

## 10) Execucao Parcial - 2026-05-12

Implementacao Wildcat v1 iniciada conforme fluxo do projeto:

1. `wildcat_1.tscn` foi auditado pelo Godot/editor API.
2. Todas as animacoes `TakeDamage_*` existem, nao fazem loop e duram 1.0s.
3. `wildcat_hit_reaction_profile_v1.tres` foi criado em `res://configs/combat/hit_reaction/`.
4. `HitReactionComponent` foi adicionado ao root do `Wildcat`.
5. `LimboHSM/HitReactionState` foi adicionado ao HSM do `Wildcat`.
6. `mundo.tscn` confirma em runtime que o Wildcat instanciado carrega o componente e o estado.
7. Smoke do Godot rodou sem parse/runtime error novo.

QA visual/logico batendo especificamente no `Wildcat` foi aprovado pelo diretor. Logs confirmaram `hit_confirmed`, `knockback_applied`, `hit_reaction_requested`, `hit_reaction_started`, `hit_reaction_animation played=true`, animacoes `TakeDamage_*` reais, `duration: 1.0` e `hit_reaction_finished`. Hostis Base/Light/Brute permanecem fora desta etapa ate decisao da Fase C.

### Fase E - Freeze
- [x] Atualizar docs/status.
- [x] Registrar quais cenas possuem Hit Reaction visual.
- [x] Registrar quais hostis ainda precisam de asset/componente.
- [ ] Commit e push somente apos QA aprovado.

## 11) Freeze Funcional - 2026-05-12

Estado congelado em `status-freeze-funcional-v8-wildcat-hit-reaction-2026-05-12.md`.

Cenas com Hit Reaction visual aprovado:

1. `res://cenas/player.tscn` via freeze V7.
2. `res://cenas/wildcat_1.tscn` via freeze V8.

Cenas ainda fora do freeze visual:

1. `res://cenas/hostile_enemy_base.tscn`
2. `res://cenas/hostile_enemy_light.tscn`
3. `res://cenas/hostile_enemy_brute.tscn`

## 12) Execucao Parcial Hostile Coverage - 2026-05-12

Fase C implementada via Godot/editor API, com cena parada e sem edicao textual estrutural de `.tscn`.

Auditoria antes da mudanca:

1. Base/Light/Brute tinham `Health`, `Hurtbox`, `AttackHitbox` e `LimboHSM`.
2. Base/Light/Brute nao tinham `TakeDamage_*`.
3. Base/Light/Brute nao tinham `HitReactionComponent`.
4. Base/Light/Brute nao tinham `LimboHSM/HitReactionState`.

Aplicacao:

1. As 8 animacoes `TakeDamage_*` do `wildcat_1.tscn` foram copiadas para cada cena hostile.
2. Todas ficaram com 15 frames, 15 FPS e `loop = false`.
3. `HitReactionComponent` foi adicionado em cada root.
4. `LimboHSM/HitReactionState` foi adicionado em cada HSM.
5. Base/Light usam `hostile_light_hit_reaction_profile_v1.tres`.
6. Brute usa `hostile_brute_hit_reaction_profile_v1.tres`.

Validacao MCP executada:

1. `mundo.tscn` abriu.
2. `mundo.tscn` rodou sem parse/runtime error novo.
3. Logs confirmaram inicializacao de orb de `HostileEnemyBase`, `HostileEnemyLight` e `HostileEnemyBrute`.
4. Auditoria no editor confirmou que as instancias no `mundo.tscn` carregam `HitReactionComponent` e `LimboHSM/HitReactionState`.

Pendencia objetiva antes do freeze:

1. QA jogavel batendo em `HostileEnemyBase`: concluido.
2. QA jogavel batendo em `HostileEnemyLight`: concluido.
3. QA jogavel batendo em `HostileEnemyBrute`: concluido.
4. Confirmar nos logs, para cada um, `hit_reaction_requested`, `hit_reaction_started`, `hit_reaction_animation played=true` e `hit_reaction_finished`: concluido.

## 13) Freeze Funcional V9 - 2026-05-12

Estado congelado em `status-freeze-funcional-v9-hostile-hit-reaction-2026-05-12.md`.

Hostis aprovados:

1. `HostileEnemyBase`
2. `HostileEnemyLight`
3. `HostileEnemyBrute`

Evidencia comum:

1. `hit_confirmed` com `source_owner: Player`;
2. `knockback_applied`;
3. `hit_reaction_requested`;
4. `hit_reaction_started`;
5. `hit_reaction_animation played=true`;
6. `duration: 1.0`;
7. `hit_reaction_finished`;
8. morte final sem nova hit reaction, correto;
9. stamina, kiting, orb, regen, target lost, death e respawn preservados.

## 8) Recomendacao Tech Lead
Nao tentar propagar tudo de uma vez.

Sequencia segura:

1. Fechar `wildcat_1.tscn` primeiro, porque ja tem `TakeDamage_*`.
2. Validar no Godot e em log.
3. Depois decidir hostis:
   - curto prazo: copiar animacoes para Base/Light/Brute via editor API;
   - medio prazo: criar template visual compartilhado ou Resource de SpriteFrames para evitar duplicacao em quatro `.tscn`.

## 9) Criterio de Pronto
A sprint so fecha quando:

1. `wildcat_1.tscn` toca `TakeDamage_*` visualmente ao receber dano.
2. Telemetria confirma `hit_reaction_animation played=true`.
3. Godot MCP nao registra parse/runtime error novo.
4. Docs registram claramente se Base/Light/Brute foram incluidos ou ficaram fora do escopo.
