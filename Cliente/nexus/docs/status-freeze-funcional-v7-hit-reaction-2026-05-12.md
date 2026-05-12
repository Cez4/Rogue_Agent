# Status Freeze V7: Universal Hit Reaction / Hit Stun

Data: 2026-05-12
Status: aprovado em QA jogavel e congelado.
Branch: `feat/universal-hit-reaction-component-v1`
Commits de referencia:
1. `eacd1d2 feat(combat): add universal hit reaction`
2. `52965d1 fix(combat): face hit reaction toward attacker`

## Resumo Executivo
A sprint de Hit Reaction / Hit Stun universal foi concluida e aprovada visualmente.

O projeto agora possui uma reacao corporal modular quando uma entidade recebe dano. No v1, o Player usa animacoes 8-dir `Dagger01_TakeDamage_*`, interrompe movimento/ataque por uma janela punitiva curta, toca a animacao inteira e depois libera a HSM para a BT retomar o combate.

O sistema segue o mesmo contrato arquitetural do Knockback V6: componente plug-and-play, dados em Resource `.tres`, HSM para execucao corporal e BT preservada como decisora de intencao.

## Objetivos Alcançados
1. Criado `HitReactionProfile` em `res://Scripts/combat/hit_reaction_profile.gd`.
2. Criado `HitReactionComponent` em `res://Scripts/combat/hit_reaction_component.gd`.
3. Criado `HitReactionState` em `res://Scripts/actors/states/hit_reaction_state.gd`.
4. Criados profiles data-driven:
   - `res://configs/combat/hit_reaction/player_hit_reaction_profile_v1.tres`;
   - `res://configs/combat/hit_reaction/hostile_light_hit_reaction_profile_v1.tres`;
   - `res://configs/combat/hit_reaction/hostile_brute_hit_reaction_profile_v1.tres`;
   - `res://configs/combat/hit_reaction/no_hit_reaction_profile_v1.tres`.
5. `res://cenas/player.tscn` recebeu:
   - `HitReactionComponent`;
   - `LimboHSM/HitReactionState`;
   - animacoes `Dagger01_TakeDamage_*` sem loop.
6. `Actor8DirLimbo` recebeu apenas wiring minimo:
   - transicao HSM `ANYSTATE -> HitReactionState`;
   - bloqueio de ataque/movimento enquanto `HitReactionComponent.is_reacting()`;
   - sem exports novos e sem tuning de Hit Reaction no actor.
7. BT continuou sem regra de dano:
   - `bt_request_attack.gd` e `bt_move_to_blackboard_pos.gd` apenas respeitam o estado de hit reaction.
8. Runtime visual foi protegido:
   - `ActorRuntimeBridge.play_directional()` nao sobrescreve idle/walk/attack/look genericos durante Hit Reaction.

## Decisoes de Game Feel Aprovadas
1. `use_animation_length = true` no profile do Player significa: tocar a animacao inteira antes de liberar a HSM.
2. As animacoes `Dagger01_TakeDamage_*` atuais possuem 15 frames a 15 FPS, total aproximado de `1.0s`.
3. `max_hit_stun_sec` nao corta animacao real quando `use_animation_length = true`; ele permanece como limite/fallback para duracao base.
4. A orientacao visual do dano usa a direcao oposta ao knockback, fazendo o ator olhar para a origem do golpe em vez de virar de costas.
5. `combat_target` nao e limpo durante Hit Reaction.
6. Knockback V6 continua funcional e preservado; Hit Reaction e camada visual/HSM complementar ao impacto fisico.

## Evidencia MCP e Telemetria
Validacao feita em `res://cenas/mundo.tscn`.

Resultado:
1. Cena abriu e rodou.
2. `get_godot_errors` nao registrou parse/runtime error novo.
3. Logs confirmaram:
   - `hit_confirmed`;
   - `knockback_applied`;
   - `hit_reaction_requested`;
   - `hit_reaction_started`;
   - `hit_reaction_animation` com `played=true`;
   - animacoes reais como `Dagger01_TakeDamage_O`, `Dagger01_TakeDamage_SO` e `Dagger01_TakeDamage_NO`;
   - `duration: 1.0`;
   - `hit_reaction_finished` apos a janela da animacao;
   - retomada de ataque/BT depois da reacao.
4. QA visual do diretor aprovou o comportamento funcional.

## Contrato Congelado
1. Hit Reaction deve permanecer modular e copiavel para outros atores.
2. Novos atores devem habilitar a feature copiando `HitReactionComponent`, adicionando `HitReactionState` na HSM e apontando para um `HitReactionProfile`.
3. A logica nao pode virar regra exclusiva do Player.
4. A BT nao deve receber regra de dano; ela pode apenas respeitar `is_reacting()`.
5. O actor nao deve receber exports/tuning de Hit Reaction.
6. `.tscn` e `.tres` continuam sendo editados via Godot/editor API quando a mudanca for estrutural.
7. Qualquer propagacao para hostis/NPCs deve validar:
   - cena com `HealthComponent`;
   - `Hurtbox`;
   - `LimboHSM`;
   - profile correto;
   - telemetria `hit_reaction_*`.

## Riscos Remanescentes Aceitos
1. Hostis possuem profiles prontos, mas nao receberam componente/estado visual no v1 aprovado; propagacao fica para sprint futura.
2. NPCs sem sprites de dano devem usar fallback/desabilitar feature ate terem assets proprios.
3. Um futuro sistema de FHR pode reduzir tempo de recuperacao, mas nao deve quebrar a regra de tocar animacao inteira quando `use_animation_length = true`, a menos que haja decisao explicita de design.

## Proximo Passo Recomendado
Abrir nova sprint somente depois deste freeze. Opcoes tecnicas seguras:
1. Propagar Hit Reaction para hostis com assets/fallback validado.
2. Voltar ao roadmap estrutural do `Actor8DirLimbo`, respeitando os freezes V5/V6/V7.
3. Avancar sistemas visuais/data-driven futuros, como paperdolling ou skills, sem alterar o baseline de combate aprovado.
