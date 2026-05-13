# Status Freeze Operacional V10 - Combat Core Restored

Data: 2026-05-13
Branch: `feat/combat-clash-parry-telemetry-v1`
Status: APROVADO PELO DIRETOR APOS TESTE VISUAL E LOGS

## 1) Escopo Do Freeze
Este freeze congela o estado apos a remocao do Combat Clash temporal do runtime.

Importante: este nao e um freeze de Parry funcional. A decisao aprovada e manter o core de combate atual e arquivar o Combat Clash temporal como pesquisa historica.

## 2) Estado Funcional Aprovado
O core aprovado do combate volta a ser:

1. Hitbox confirma contato.
2. Hurtbox aplica knockback/dano.
3. Health emite dano.
4. Hit Reaction toca animacao `TakeDamage_*`.
5. Se o alvo estava atacando, o ataque e interrompido por `hit_reaction`.
6. A stamina ja gasta pelo ataque interrompido permanece como custo real da decisao ruim.

Esse estado preserva o game feel aprovado:

1. Player e NPCs continuam consumindo stamina antes do golpe.
2. Quem acerta primeiro aplica dano real.
3. O alvo entra em Taken Damage/Hit Stun.
4. Knockback `200.0` continua como baseline aprovado.
5. Kiting/stamina/orbs/regen continuam operando.

## 3) Combat Clash Temporal
Removido do runtime:

1. `res://Scripts/combat/combat_clash_component.gd`
2. `res://Scripts/combat/combat_clash_profile.gd`
3. `res://configs/combat/clash/player_combat_clash_profile_v1.tres`
4. `res://configs/combat/clash/wildcat_combat_clash_profile_v1.tres`
5. Nodo `CombatClashComponent` de `player.tscn`
6. Nodo `CombatClashComponent` de `wildcat_1.tscn`

Motivo:

1. A D/D2 provou viabilidade tecnica de `mutual_clash`.
2. Como regra global, o sistema ficou complexo e alterou demais o duelo Player x Wildcat.
3. O design desejado para Parry futuro e mais simples: componente de defesa por chance/atributo, data-driven e consultado antes do dano.

## 4) Evidencia De Log Aprovada
Logs do teste do diretor confirmaram:

1. Nao aparecem eventos `combat_clash_*`.
2. Nao aparecem `hit_cancelled_by_clash`.
3. Nao aparecem `parried_count` ou `clashed_count`.
4. Player ataque `44` consumiu stamina, abriu janela ativa e confirmou hit no Wildcat.
5. Wildcat ataque `80` estava em `windup` e foi interrompido por `reason = hit_reaction`.
6. Wildcat ataques `81`, `82`, `94`, `95`, `96` confirmaram hit no Player.
7. Player tocou `Dagger01_TakeDamage_*` com `played = true`.
8. Wildcat tocou `TakeDamage_*` com `played = true`.
9. Player ataque `56` matou o Wildcat; interrupcao do ataque `108` veio como `reason = death`, correto.
10. Apos fim de combate, Player perdeu alvo e regen fora de combate voltou a emitir `health_regen_tick` e `orb_health_heal_react`.

## 5) Regra Para Proximas Sprints
Nao reintroduzir Combat Clash temporal como regra global.

Parry futuro deve ser sprint nova:

1. Nome recomendado: `Data-Driven Defense / Parry Component v1`.
2. Componente recomendado: `DefenseComponent` ou `ParryComponent`.
3. Resource recomendado: `DefenseProfile.tres` ou `ParryProfile.tres`.
4. Campos iniciais recomendados:
   - `parry_chance`;
   - `parry_cooldown_sec`;
   - `parry_stamina_cost`;
   - `requires_facing`;
   - `cancel_knockback`;
   - `cancel_hit_reaction`.
5. Ponto de integracao recomendado: antes de `HurtboxComponent.take_hit_with_knockback_duration(...)` aplicar dano.

## 6) Anti-Drift
1. `Actor8DirLimbo` nao deve receber exports/tuning de Parry/Defense.
2. Parry nao deve depender de dois ataques cruzando no mesmo frame/janela temporal.
3. A mecanica aprovada de stamina continua sendo: ataque iniciado paga custo; se for interrompido depois, nao recebe refund automatico.
4. Qualquer defesa por chance deve ser modular, plug-and-play e validada por logs antes de ativacao em inimigos ou Player.

