# Plano Sprint - Wildcat / Hostile Hit Reaction v1

Data: 2026-05-12
Status: PLANEJADO - AGUARDANDO EXECUCAO
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
- [ ] Confirmar `wildcat_1.tscn` abre no Godot sem erro apos as animacoes adicionadas.
- [ ] Confirmar loops `TakeDamage_* = false`.
- [ ] Medir duracao real das animacoes `TakeDamage_*`.
- [ ] Confirmar se `wildcat_1.tscn` esta sendo usado no mapa atual ou se os inimigos do QA usam `hostile_enemy_*`.
- [ ] Confirmar se `HostileEnemyBase`, `HostileEnemyLight` e `HostileEnemyBrute` possuem `TakeDamage_*`.

### Fase B - Wildcat v1
- [ ] Criar `wildcat_hit_reaction_profile_v1.tres`.
- [ ] Adicionar `HitReactionComponent` em `wildcat_1.tscn` via Godot/editor API.
- [ ] Adicionar `HitReactionState` em `wildcat_1.tscn` via Godot/editor API.
- [ ] Conectar paths iguais ao Player:
  - `HitReactionComponent.profile`;
  - `HitReactionComponent.health_component_path`;
  - `HitReactionComponent.hsm_path`;
  - `HitReactionState.hit_reaction_component_path`.
- [ ] Rodar `mundo.tscn` ou cena-alvo e confirmar telemetria.

### Fase C - Hostile Coverage
- [ ] Decidir se hostis recebem as animacoes agora ou se ficam para sprint de template visual.
- [ ] Se receberem agora:
  - adicionar `TakeDamage.png` e `TakeDamage_*` em cada hostile via Godot/editor API;
  - adicionar `HitReactionComponent`;
  - adicionar `HitReactionState`;
  - usar profile hostile adequado.
- [ ] Se nao receberem agora:
  - documentar que apenas Wildcat visual tem Hit Reaction v1;
  - manter hostis com profiles prontos mas sem componente/estado.

### Fase D - QA
- [ ] Godot MCP: abrir cena-alvo.
- [ ] Rodar combate.
- [ ] Confirmar no log:
  - `hit_confirmed`;
  - `knockback_applied`;
  - `hit_reaction_requested`;
  - `hit_reaction_started`;
  - `hit_reaction_animation played=true`;
  - `duration` coerente com a animacao;
  - `hit_reaction_finished`;
  - alvo de combate preservado.
- [ ] QA visual: Wildcat olha para origem do golpe e toca `TakeDamage_*` inteiro.
- [ ] Confirmar sem regressao de ataque, kiting, stamina, orb e regen.

### Fase E - Freeze
- [ ] Atualizar docs/status.
- [ ] Registrar quais cenas possuem Hit Reaction visual.
- [ ] Registrar quais hostis ainda precisam de asset/componente.
- [ ] Commit e push somente apos QA aprovado.

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
