# Status Freeze V8: Wildcat Hit Reaction

Data: 2026-05-12
Status: aprovado em QA jogavel e congelado.
Branch: `feat/universal-hit-reaction-component-v1`
Base obrigatoria: `status-freeze-funcional-v7-hit-reaction-2026-05-12.md`

## Resumo Executivo
O sistema Universal Hit Reaction V7 foi propagado para o `Wildcat` sem alterar o contrato do Player, da BT ou do `Actor8DirLimbo`.

O `Wildcat` agora possui reacao visual modular ao receber dano:

1. dano entra via `Hurtbox`/`HealthComponent`;
2. `HitReactionComponent` recebe o sinal de dano;
3. HSM dispara `HitReactionState`;
4. animacao direcional `TakeDamage_*` toca inteira;
5. knockback V6 continua sendo aplicado por `KnockbackComponent`;
6. combate, stamina, kiting, orb e regen seguem funcionais.

## Escopo Congelado
Arquivos principais desta etapa:

1. `res://cenas/wildcat_1.tscn`
2. `res://configs/combat/hit_reaction/wildcat_hit_reaction_profile_v1.tres`
3. `res://docs/plano-sprint-wildcat-hit-reaction-v1-2026-05-12.md`

## Implementacao
`wildcat_1.tscn` recebeu:

1. `HitReactionComponent` no root do `Wildcat`;
2. `LimboHSM/HitReactionState`;
3. profile dedicado `wildcat_hit_reaction_profile_v1.tres`;
4. animacoes existentes `TakeDamage_L`, `TakeDamage_N`, `TakeDamage_NE`, `TakeDamage_NO`, `TakeDamage_O`, `TakeDamage_S`, `TakeDamage_SE`, `TakeDamage_SO`.

Auditoria das animacoes:

1. 8 direcoes presentes;
2. `loop = false`;
3. 15 frames;
4. 15 FPS;
5. duracao real de 1.0s.

## Evidencia de QA
Logs gerados pelo diretor e analisados confirmaram o fluxo completo no `Wildcat`:

1. `hit_confirmed` com `source_owner: Player`;
2. `knockback_applied` em `actor: Wildcat`, `force: 200`, `duration: 0.15`;
3. `hit_reaction_requested` em `actor: Wildcat`;
4. `hit_reaction_started` com `animation_prefix: TakeDamage`;
5. `hit_reaction_animation` com `played: true`;
6. animacoes reais tocadas: `TakeDamage_S`, `TakeDamage_SO`, `TakeDamage_SE`, `TakeDamage_O`;
7. `duration: 1.0`;
8. `hit_reaction_finished`;
9. target/combat/stamina/kiting/orb/regen sem regressao observada.

O golpe final matou o `Wildcat` e nao disparou nova hit reaction. Isso esta correto: entidade morta nao deve entrar em reacao de dano; deve seguir o fluxo de morte/target lost/respawn.

## Contrato Congelado
1. `HitReactionComponent` continua plug-and-play e copiavel.
2. `HitReactionState` continua generico e nao exclusivo do Player.
3. `HitReactionProfile` e a fonte de dados da reacao.
4. BT continua sem regra propria de dano; apenas respeita `is_reacting()`.
5. `Actor8DirLimbo` nao deve receber tuning/export novo para Wildcat Hit Reaction.
6. `.tscn` e `.tres` estruturais devem continuar sendo alterados via Godot/editor API.
7. `HostileEnemyBase`, `HostileEnemyLight` e `HostileEnemyBrute` nao estao incluidos neste freeze.

## Limite Do Freeze
Este freeze cobre somente o `Wildcat` canonical local.

Hostis continuam como cenas independentes e nao herdam automaticamente as animacoes `TakeDamage_*` do `wildcat_1.tscn`. Para hostis, a decisao permanece aberta:

1. copiar animacoes/componentes via Godot/editor API;
2. criar template visual compartilhado;
3. ou manter sem Hit Reaction visual ate a sprint propria.

## Proximo Passo Recomendado
Abrir a Fase C somente em nova etapa controlada:

1. auditar `HostileEnemyBase`, `HostileEnemyLight` e `HostileEnemyBrute`;
2. decidir se recebem assets `TakeDamage_*` agora ou se aguardam template visual;
3. aplicar componente/estado/profile por cena;
4. validar cada hostile com logs `hit_reaction_*` e QA visual.
