# Plano Sprint - Universal Hit Reaction Component v1

Data: 2026-05-12
Status: CONCLUIDA - CONGELADA NO FREEZE V7
Branch executada: `feat/universal-hit-reaction-component-v1`
Freeze: `status-freeze-funcional-v7-hit-reaction-2026-05-12.md`

## 1) Objetivo
Criar um sistema universal de Hit Reaction / Hit Stun para elevar o game feel quando uma entidade recebe dano.

O sistema deve fazer o ator reagir visualmente ao dano recebido, tocando animacoes 8-direcoes de `TakeDamage` e aplicando uma janela curta de recuperacao antes de voltar ao combate.

Regra principal: isto nao e um sistema exclusivo do Player. Deve ser um componente plug-and-play de engine, copiavel para qualquer template de Player, NPC amigavel ou inimigo.

## 2) Decisao Arquitetural
O modelo aprovado e igual ao padrao do `KnockbackComponent`:

1. **Componente universal receptor:** `HitReactionComponent`.
   - Pode ser adicionado a qualquer cena de ator.
   - Escuta dano via `HealthComponent.damaged`.
   - Nao deve conter logica especifica de Player.
   - Nao deve depender de input.
   - Nao deve limpar `combat_target`.

2. **Estado HSM punitivo curto:** `HitReactionState` ou `DamageTakenState`.
   - Entra por evento do `LimboHSM`, exemplo: `hit_reaction!`.
   - Usa transicao `ANYSTATE -> HitReactionState`.
   - Para movimento e ataque no inicio da reacao.
   - Toca animacao direcional de dano.
   - Finaliza por tempo configurado ou fim da animacao.
   - Retorna para `IdleState`, permitindo a BT retomar combate naturalmente.

3. **Dados por Resource:** `HitReactionProfile`.
   - Define se a entidade reage.
   - Define prefixo de animacao.
   - Define duracao, cooldown e regras de interrupcao.
   - Permite templates novos sem programacao: copiar cena, trocar sprites e trocar profile.

4. **BT preservada:** a Behavior Tree nao deve carregar a logica de dano.
   - A BT continua decidindo intencoes: atacar, perseguir, fugir, vagar.
   - A HSM executa reacoes corporais imediatas.
   - Tasks BT devem respeitar `agent.is_hit_reacting()` para nao iniciar acao durante hit stun.

## 3) Glossario de Design
1. **Hit Reaction:** feedback visual ao receber dano.
2. **Hit Stun:** pequena janela em que o ator nao age apos receber hit.
3. **FHR (Faster Hit Recovery):** atributo futuro que reduz a duracao do hit stun.
4. **Stagger:** reacao mais longa/forte; fora do escopo do v1, mas a arquitetura deve permitir evolucao.
5. **Hitlock:** risco de ficar permanentemente travado por golpes rapidos; deve ser evitado com cooldown/resistencia.

## 4) Estado Atual Comprovado
1. `HealthComponent` ja emite `damaged(amount, knockback)`.
2. `HurtboxComponent` ja e o ponto de entrada do dano.
3. `KnockbackComponent` ja aplica impacto fisico modular.
4. `Actor8DirLimbo` ja possui `LimboHSM`.
5. O Player ja possui animacoes 8-direcoes:
   - `Dagger01_TakeDamage_L`
   - `Dagger01_TakeDamage_N`
   - `Dagger01_TakeDamage_NE`
   - `Dagger01_TakeDamage_NO`
   - `Dagger01_TakeDamage_O`
   - `Dagger01_TakeDamage_S`
   - `Dagger01_TakeDamage_SE`
   - `Dagger01_TakeDamage_SO`
6. Ja existe `StaggerState` para exaustao de stamina. Ele e referencia tecnica, mas nao deve ser misturado diretamente com dano comum sem plano.

## 5) Guardrails Obrigatorios
1. Nao criar logica exclusiva para Player.
2. Nao colocar regra de dano dentro da BT.
3. Nao limpar `combat_target` ao entrar em Hit Reaction.
4. Nao remover nem reescrever `StaggerState` atual.
5. Nao editar `.tscn` ou `.tres` estruturalmente por texto; usar Godot/editor API.
6. Nao mexer no tuning congelado de Knockback V6.
7. Nao fazer a BT recalcular movimento durante Hit Reaction.
8. Nao deixar ataque pendente travado se o Hit Reaction interromper ataque.
9. Nao permitir hitlock infinito no v1; usar cooldown minimo ou resistencia temporal.
10. Nao criar dependencia em nomes de sprite do Player. Prefixo deve vir de profile/export.
11. Nao inflar `Actor8DirLimbo`: apos o slimming, o actor esta com cerca de 308 linhas e deve continuar sendo fachada fina.
12. Qualquer nova regra de dominio deve entrar em `HitReactionComponent`, `HitReactionProfile`, `HitReactionState` ou service dedicado, nunca como bloco de logica dentro do actor.
13. Wrappers no actor so sao permitidos quando forem contrato publico necessario para BT/HSM/Controller, e devem ser pequenos, delegando imediatamente para component/service.

## 6) Data-Driven - HitReactionProfile
Resource proposto: `Scripts/combat/hit_reaction_profile.gd`

Campos iniciais:

1. `enabled: bool = true`
2. `animation_prefix: StringName = &"TakeDamage"`
3. `base_hit_stun_sec: float = 0.18`
4. `min_hit_stun_sec: float = 0.08`
5. `max_hit_stun_sec: float = 0.35`
6. `reaction_cooldown_sec: float = 0.12`
7. `interrupt_attack: bool = true`
8. `interrupt_movement: bool = true`
9. `require_alive: bool = true`
10. `use_animation_length: bool = true`
11. `fallback_to_idle_if_missing_animation: bool = true`
12. `fhr_stat_id: StringName = &"hit_recovery"`
13. `fhr_reduction_per_point: float = 0.0`

Profiles esperados no v1:

1. `res://configs/combat/hit_reaction/player_hit_reaction_profile_v1.tres`
2. `res://configs/combat/hit_reaction/hostile_light_hit_reaction_profile_v1.tres`
3. `res://configs/combat/hit_reaction/hostile_brute_hit_reaction_profile_v1.tres`
4. `res://configs/combat/hit_reaction/no_hit_reaction_profile_v1.tres` para chefes/imunes ou testes.

## 7) Componente Universal - HitReactionComponent
Script proposto: `Scripts/combat/hit_reaction_component.gd`

Responsabilidades:

1. Exportar:
   - `target_actor: NodePath`
   - `health_path: NodePath = ^"../Health"`
   - `profile: HitReactionProfile`
2. Resolver automaticamente o ator pai quando possivel.
3. Conectar em `HealthComponent.damaged`.
4. Aplicar cooldown anti-hitlock.
5. Chamar API publica do ator, exemplo:
   - `actor.request_hit_reaction(profile, amount, knockback)`
6. Emitir telemetria:
   - `hit_reaction_requested`
   - `hit_reaction_started`
   - `hit_reaction_finished`
   - `hit_reaction_skipped`

O componente deve funcionar copiando o node para outro ator com `HealthComponent` + `LimboHSM`, desde que o ator implemente a API minima.

## 8) Contrato Minimo Sem Reengordar o Actor
Prioridade de implementacao:

1. Primeiro tentar resolver por componente plug-and-play usando `get_parent()`, `HealthComponent.damaged`, `LimboHSM.dispatch()` e estado HSM.
2. Se o componente conseguir coordenar tudo sem novo metodo publico no actor, nao adicionar wrapper nenhum.
3. Se wrapper for inevitavel, adicionar apenas fachada fina em `Actor8DirLimbo`, mantendo o ator sem regra de dominio.

Wrappers candidatos, somente se comprovadamente necessarios:

1. `request_hit_reaction(profile: HitReactionProfile, damage: float, knockback: Vector2) -> bool`
2. `is_hit_reacting() -> bool`
3. `play_hit_reaction_animation(prefix: StringName, direction: Vector2) -> bool`
4. `finish_hit_reaction() -> void`

Regra: o calculo e orquestracao ficam em services/component/state. O actor so expoe contrato para BT/HSM/Controller quando nao houver alternativa limpa.

Limite tecnico da sprint:

1. Nao adicionar exports novos no `Actor8DirLimbo`.
2. Nao adicionar variaveis de tuning no `Actor8DirLimbo`.
3. Nao adicionar mais que um bloco minimo de delegacao no actor sem nova aprovacao.
4. Se a implementacao exigir muito codigo no actor, a sprint deve parar e criar um `ActorHitReactionRuntime` ou mover mais responsabilidade para o componente.

## 9) Estado HSM - HitReactionState
Script proposto: `Scripts/actors/states/hit_reaction_state.gd`

Comportamento:

1. `_enter()`:
   - marca ator como em Hit Reaction;
   - para motor se profile permitir;
   - cancela ataque pendente com seguranca se profile permitir;
   - toca animacao direcional `animation_prefix + "_" + suffix`;
   - calcula duracao final com profile/FHR/animacao.
2. `_update(delta)`:
   - aguarda duracao ou fim de animacao;
   - dispara `EVENT_FINISHED`.
3. `_exit()`:
   - limpa flag de Hit Reaction;
   - garante `AttackHitbox` desligada se ataque foi interrompido;
   - nao limpa alvo de combate.

Transicoes:

1. `hsm.add_transition(hsm.ANYSTATE, hit_reaction_state, &"hit_reaction!")`
2. `hsm.add_transition(hit_reaction_state, idle_state, hit_reaction_state.EVENT_FINISHED)`

## 10) Integracao com BT
Nao editar arvore `.tres` na primeira passada se nao for necessario.

Mudancas provaveis em tasks/scripts:

1. `bt_request_attack.gd`:
   - se `agent.is_hit_reacting()`, retornar `RUNNING` ou `FAILURE` conforme teste de fluxo.
   - preferencia inicial: `RUNNING`, para segurar tentativa durante hit stun sem limpar alvo.
2. `bt_move_to_blackboard_pos.gd`:
   - se `agent.is_hit_reacting()`, retornar `RUNNING` e nao mandar movimento.
3. `Actor8DirLimbo.request_attack()`:
   - rejeitar ataque se `is_hit_reacting()`.
4. `Actor8DirLimbo.request_move_runtime()`:
   - ignorar movimento durante hit reaction, preservando alvo.

## 11) Integracao Visual
1. Validar que animacoes `TakeDamage` nao estao em loop.
2. Para Player atual, usar prefixo:
   - `Dagger01_TakeDamage`
3. Para NPCs que ainda nao tem animacao propria:
   - profile pode desabilitar reacao visual;
   - ou usar fallback para idle com hit stun curto;
   - nunca forcar nome de animacao inexistente.

## 12) Plano de Execucao

### Fase A - Auditoria Sem Alteracao
- [x] Confirmar worktree e branch.
- [x] Confirmar cenas/templates com `Health`, `Hurtbox`, `AttackHitbox`, `KnockbackComponent` e `LimboHSM`.
- [x] Confirmar animacoes `Dagger01_TakeDamage_*` no Player e se estao sem loop.
- [x] Confirmar se hostis possuem sprites de dano ou se entram no v1 com fallback/desabilitado.
- [x] Registrar resultado no plano antes de codar.

### Fase B - Dados
- [x] Criar `HitReactionProfile`.
- [x] Criar profiles `.tres` via Godot/editor API.
- [x] Definir baseline inicial seguro:
  - Player: `0.16s` a `0.22s`;
  - Hostile Light/Wildcat: `0.12s` a `0.18s`;
  - Brute: `0.08s` a `0.14s` ou resistencia maior.

### Fase C - Componente Plug-and-Play
- [x] Criar `HitReactionComponent`.
- [x] Conectar no `HealthComponent.damaged`.
- [x] Implementar cooldown anti-hitlock.
- [x] Emitir telemetria.
- [x] Testar componente isolado em cena sem alterar BT.

### Fase D - HSM e Actor Contract
- [x] Criar `hit_reaction_state.gd`.
- [x] Primeiro tentar integrar sem novo wrapper no `Actor8DirLimbo`.
- [x] Se inevitavel, adicionar apenas wrappers pequenos em `Actor8DirLimbo`, com delegacao imediata e sem tuning/export.
- [x] Medir linhas do actor antes/depois; nao aceitar re-inflar a fachada.
- [x] Adicionar transicao HSM `hit_reaction!`.
- [x] Garantir interrupcao limpa de ataque e movimento.
- [x] Garantir que `combat_target` permanece.

### Fase E - Integracao em Templates
- [x] Adicionar `HitReactionComponent` no Player via Godot/editor API.
- [x] Adicionar `HitReactionState` no HSM do Player via Godot/editor API.
- [x] Decidir hostis v1: com profile real, fallback curto ou desabilitado.
- [x] Nao propagar para todos os templates antes de QA visual do Player.

### Fase F - QA Godot/MCP
- [x] Parar cena antes de editar.
- [x] `open_scene res://cenas/mundo.tscn`
- [x] `play_scene current`
- [x] `get_godot_errors`
- [x] Confirmar logs:
  - `hit_confirmed`
  - `damaged`
  - `hit_reaction_requested`
  - `hit_reaction_started`
  - `hit_reaction_finished`
  - combate retomando depois.
- [x] Confirmar visualmente Player recebendo hit e tocando `Dagger01_TakeDamage_*`.
- [x] Confirmar que spam de hits nao gera hitlock permanente.
- [x] Confirmar que kiting/stamina/knockback/orb continuam funcionais.

### Fase G - Freeze
- [x] Atualizar docs/status.
- [x] Registrar valores finais de tuning.
- [x] Commit e push somente apos QA aprovado.

## 12.1) Implementacao tecnica v1 - 2026-05-12
Status: implementacao validada e encerrada no freeze V7.

O que foi implementado:

1. `HitReactionProfile` em `res://Scripts/combat/hit_reaction_profile.gd`.
2. `HitReactionComponent` em `res://Scripts/combat/hit_reaction_component.gd`.
3. `HitReactionState` em `res://Scripts/actors/states/hit_reaction_state.gd`.
4. Profiles criados via Godot/editor API:
   - `res://configs/combat/hit_reaction/player_hit_reaction_profile_v1.tres`;
   - `res://configs/combat/hit_reaction/hostile_light_hit_reaction_profile_v1.tres`;
   - `res://configs/combat/hit_reaction/hostile_brute_hit_reaction_profile_v1.tres`;
   - `res://configs/combat/hit_reaction/no_hit_reaction_profile_v1.tres`.
5. `res://cenas/player.tscn` recebeu:
   - `HitReactionComponent`;
   - `LimboHSM/HitReactionState`;
   - loops `Dagger01_TakeDamage_*` desligados.

Decisoes tecnicas:

1. Hostis ainda nao receberam o componente no v1 visual; eles ficam com profiles prontos para proxima propagacao apos QA do Player.
2. `Actor8DirLimbo` nao recebeu exports nem tuning novo.
3. `Actor8DirLimbo` ficou com cerca de 323 linhas apos o wiring minimo, preservando a fachada fina.
4. A BT nao recebeu regra de dano; apenas respeita `HitReactionComponent.is_reacting()` para nao iniciar ataque/movimento durante hit stun.

Validacao MCP:

1. `res://cenas/mundo.tscn` abriu e rodou.
2. `get_godot_errors` nao registrou parse/runtime error novo apos limpar logs e registrar UID do profile.
3. Logs confirmaram:
   - `hit_confirmed`;
   - `knockback_applied`;
   - `hit_reaction_requested`;
   - `hit_reaction_started`;
   - `hit_reaction_finished`;
   - retomada de ataque/kiting/stamina depois da reacao.

QA visual apos teste do diretor:

1. O teste visual inicial nao exibiu claramente a animacao de dano.
2. A auditoria de logs comprovou que a logica estava entrando:
   - `hit_reaction_requested`;
   - `hit_reaction_started`;
   - `hit_reaction_animation` com `played=true`;
   - animacoes reais como `Dagger01_TakeDamage_S`, `Dagger01_TakeDamage_N`, `Dagger01_TakeDamage_SO`, `Dagger01_TakeDamage_NE`, `Dagger01_TakeDamage_O` e `Dagger01_TakeDamage_L`;
   - duracao visual calculada em `0.28s`.
3. O problema encontrado foi disputa visual: eventos de BT/kiting ainda podiam chamar animacoes genericas dentro da janela de hit stun e sobrescrever o sprite.
4. Correcao aplicada sem inflar o `Actor8DirLimbo`: `ActorRuntimeBridge.play_directional()` agora respeita `HitReactionComponent.is_reacting()` e bloqueia idle/walk/attack/look genericos durante a reacao.
5. `HitReactionState` continua sendo a unica fonte autorizada para tocar a animacao de dano durante o hit stun.

QA de duracao apos novo teste do diretor:

1. Logs novos mostraram que o fluxo estava correto, mas o game feel ainda ficava curto:
   - `hit_reaction_animation` tocava `played=true`;
   - `duration` ficava em `0.28s`;
   - `hit_reaction_finished` liberava logo depois.
2. Auditoria da cena mostrou que cada `Dagger01_TakeDamage_*` tem 15 frames a 15 FPS, ou seja, cerca de `1.0s`.
3. Causa: `HitReactionState` estava usando `use_animation_length=true`, mas ainda clampava a duracao pelo `max_hit_stun_sec` do profile.
4. Decisao corrigida: quando `use_animation_length=true`, a animacao e autoritativa e deve tocar inteira antes de liberar a HSM, igual ao fluxo aprovado do ataque.
5. `max_hit_stun_sec` continua relevante para duracao base/fallback; nao deve cortar animacao real quando o profile pede para usar o comprimento da animacao.

## 12.2) Fechamento e Freeze V7 - 2026-05-12
Status: aprovado, commitado, enviado e congelado.

Commits:

1. `eacd1d2 feat(combat): add universal hit reaction`
2. `52965d1 fix(combat): face hit reaction toward attacker`

Freeze oficial:

1. `res://docs/status-freeze-funcional-v7-hit-reaction-2026-05-12.md`

Aceite final:

1. QA visual aprovado pelo diretor.
2. Player toca `Dagger01_TakeDamage_*` ao receber dano.
3. Animacao toca inteira (`duration: 1.0`) antes de liberar a HSM.
4. Orientacao da animacao foi corrigida para olhar para a origem do golpe.
5. Knockback V6, stamina, kiting, orb e retomada de combate permaneceram funcionais.
6. Branch `feat/universal-hit-reaction-component-v1` sincronizada com o remoto no commit `52965d1`.

## 13) Criterios de Aceite
1. O Player toca animacao direcional de dano ao receber hit.
2. O Player fica em hit stun curto e perceptivel.
3. O Player retoma combate apos a recuperacao.
4. `combat_target` nao e limpo.
5. Knockback V6 continua funcional.
6. Stamina/kiting/orb continuam funcionais.
7. Sistema e plug-and-play: copiar `HitReactionComponent` + profile para outro ator habilita a feature.
8. Valores de duracao e prefixo vivem em `.tres`, nao hardcoded no estado.
9. Sem parse/runtime error novo no Godot MCP.
10. Logs comprovam fluxo de hit reaction.

## 14) Riscos e Mitigacoes
1. **Hitlock infinito:** usar `reaction_cooldown_sec` e limites min/max.
2. **BT brigando com HSM:** `is_hit_reacting()` deve bloquear ataque/move temporariamente.
3. **Ataque interrompido deixando hitbox ligada:** `_exit()` do estado/ataque deve desligar hitbox.
4. **Animação loopando e nunca terminando:** usar timer como fonte de verdade e validar `animation_finished` apenas quando aplicavel.
5. **NPC sem animacao de dano:** profile usa fallback para idle ou feature desabilitada.
6. **Acoplamento no Actor8DirLimbo:** manter wrappers pequenos e mover logica para component/state/service.
7. **Regressao do slimming:** medir o actor antes/depois e bloquear qualquer implementacao que transforme o actor novamente em monolito.

## 15) Fontes Tecnicas
1. Godot `AnimatedSprite2D`: `animation_finished` nao e emitido por animacoes em loop; por isso o v1 deve validar loop e ter timer de seguranca.
   - https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html
2. LimboAI `LimboHSM`: transicoes por evento, `ANYSTATE`, `add_transition` e estado ativo.
   - https://limboai.readthedocs.io/en/stable/classes/class_limbohsm.html
3. LimboAI HSM guide: eventos desacoplam transicoes e `EVENT_FINISHED` e o padrao para sair de um estado.
   - https://limboai.readthedocs.io/en/stable/hierarchical-state-machines/create-hsm.html

## 16) Definicao de Pronto
Sprint so sera considerada concluida quando:

1. Plano e docs atualizados.
2. Implementacao feita em branch propria.
3. Godot MCP limpo.
4. QA visual aprovado pelo diretor.
5. Telemetria registrada.
6. Estado congelado em novo status doc.
7. Commit e push realizados.
