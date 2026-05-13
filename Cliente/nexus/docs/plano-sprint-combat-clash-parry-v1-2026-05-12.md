# Plano Sprint - Data-Driven Combat Clash / Parry Window v1

Data: 2026-05-12
Status: EM EXECUCAO - FASE D GAMEPLAY AUDITADA E DESABILITADA, OBSERVER PRESERVADO
Branch de implementacao: `feat/combat-clash-parry-telemetry-v1`
Baseline obrigatorio: `status-freeze-funcional-v9-hostile-hit-reaction-2026-05-12.md`

## 1) Objetivo
Transformar o comportamento emergente atual de interrupcao de ataque em uma mecanica formal, modular e data-driven de Combat Clash / Parry Window.

O sistema deve aproveitar a janela ja observada em combate:

1. Um ator inicia ataque e consome stamina.
2. O oponente acerta antes da janela ativa confirmar o golpe.
3. O ator atingido entra em Hit Reaction.
4. O ataque em andamento e interrompido, a hitbox e desligada e o golpe nao confirma dano.

Isso hoje funciona como um **Attack Interrupt natural**, ainda nao como Parry formal.

## 2) Decisao de Design
O "stamina damage" inicial ja existe no comportamento aprovado: quem iniciou um ataque e foi interrompido ja pagou o custo da acao em stamina.

Portanto, o v1 nao deve adicionar imediatamente mais dano de stamina ao oponente. A primeira versao deve medir e formalizar a janela real antes de criar punicoes extras.

Regra de game feel:

1. O custo de stamina do ataque interrompido e a punicao base.
2. Dano extra de stamina, refund parcial, parry perfeito ou stagger adicional ficam como tuning futuro em `.tres`.
3. Nenhuma regra deve ser hardcoded por Player, Wildcat, Brute ou Light.

## 3) Nomes Tecnicos
Termos aprovados para a sprint:

1. **Attack Interrupt:** ataque cancelado por dano recebido antes de confirmar hit.
2. **Clash Window:** janela em que dois ataques concorrentes podem gerar resolucao especial.
3. **Parry Window:** janela defensiva perfeita, ativa por timing/tuning.
4. **Whiff Paid Cost:** ataque que gastou stamina, mas nao confirmou hit.
5. **Interrupt Advantage:** vantagem do ator que acertou primeiro e forca hit reaction no outro.

## 4) Estado Atual Comprovado
Telemetria atual ja mostra a semente da mecanica:

1. `state_attack_8dir.gd` consome stamina no `_enter()` do ataque.
2. `attack_started` e `attack_commit` sao emitidos antes da janela de hit.
3. `HitboxComponent` confirma dano apenas quando a area ativa toca a `Hurtbox`.
4. `HitReactionState` pode entrar por `ANYSTATE`, interrompendo movimento e ataque.
5. `HitReactionState._interrupt_attack()` desliga `AttackHitbox` e chama `clear_attack_pending()`.
6. O log mostra sequencias em que Player e Hostile iniciam ataques proximos, mas apenas um confirma hit antes do outro entrar em `hit_reaction_started`.

Limite atual:

1. A telemetria ainda nao registra fase precisa do ataque (`windup`, `active`, `recover`).
2. A telemetria ainda nao possui `attack_sequence_id` compartilhado entre stamina, hitbox e interrupcao.
3. Sem esses dados, implementar Parry diretamente seria tuning cego.

## 5) Decisao Arquitetural
O modelo aprovado deve seguir o padrao de engine modular ja usado em Knockback e Hit Reaction:

1. **Componente universal:** `CombatClashComponent` ou `ParryComponent`.
   - Plug-and-play em Player, NPC amigavel ou inimigo.
   - Nao depende de input.
   - Nao contem logica exclusiva de Player.
   - Pode ficar ausente em entidades que nao participam de clash/parry.

2. **Resource data-driven:** `CombatClashProfile`.
   - Define janelas, custo, cooldown, flags e efeitos.
   - Permite copiar template e trocar dados sem programacao.
   - Permite Player, Light, Brute, Wildcat e futuros chefes terem regras diferentes.

3. **Telemetria de ataque:** extensao pequena em `state_attack_8dir.gd` e `HitboxComponent`.
   - Registrar fase e id do ataque.
   - Sem alterar game feel na Fase A.

4. **HSM preservada:** Hit Reaction continua sendo a reacao corporal.
   - Parry/Clash decide a resolucao.
   - Hit Reaction executa a punicao visual quando aplicavel.

5. **BT preservada:** Behavior Tree continua decidindo intencao.
   - Nao mover regra de parry para BT.
   - Nao criar task de dano.

## 6) Data-Driven - CombatClashProfile
Resource proposto: `res://Scripts/combat/combat_clash_profile.gd`

Campos iniciais planejados:

1. `enabled: bool = true`
2. `can_parry: bool = false`
3. `can_be_interrupted: bool = true`
4. `interrupt_on_damage: bool = true`
5. `parry_window_start_sec: float = 0.0`
6. `parry_window_duration_sec: float = 0.0`
7. `clash_window_sec: float = 0.10`
8. `refund_stamina_on_parry: float = 0.0`
9. `extra_stamina_damage_on_parry: float = 0.0`
10. `interrupt_cooldown_sec: float = 0.0`
11. `emit_only_telemetry: bool = true`

Importante:

1. `extra_stamina_damage_on_parry` deve iniciar em `0.0`.
2. A punicao de stamina v1 e o custo ja gasto pelo ataque interrompido.
3. Qualquer dano adicional de stamina precisa de QA separado.

## 7) Componente Universal - CombatClashComponent
Responsabilidades planejadas:

1. Escutar eventos de ataque do ator local.
2. Guardar fase atual: `idle`, `windup`, `active`, `recover`, `interrupted`.
3. Guardar `attack_sequence_id`.
4. Ao receber dano, classificar:
   - dano durante windup;
   - dano durante active;
   - dano durante recover;
   - dano fora de ataque.
5. Emitir telemetria:
   - `attack_phase_started`
   - `attack_window_opened`
   - `attack_window_closed`
   - `attack_interrupted`
   - `combat_clash_candidate`
   - `parry_candidate`
6. No v1 inicial, nao alterar resultado do combate se `emit_only_telemetry = true`.

## 8) Contrato Minimo Sem Inflar Actor8DirLimbo
`Actor8DirLimbo` nao deve receber tuning/export de Clash ou Parry.

Wrappers so podem ser aceitos se forem fachada minima:

1. `get_combat_clash_component() -> Node`
2. `is_attack_active() -> bool`
3. `get_attack_phase() -> StringName`

Preferencia:

1. `state_attack_8dir.gd` emite telemetria e chama componente se existir.
2. `HitReactionState` continua cuidando da interrupcao corporal.
3. `HitboxComponent` continua sendo dono da janela fisica de hit.
4. `CombatClashComponent` observa e classifica, sem virar monolito.

## 9) Plano de Execucao

### Fase A - Telemetria Sem Mudanca de Gameplay
- [x] Revisar freeze V9 e docs de Hit Reaction/Knockback.
- [x] Ler docs oficiais Godot sobre `Area2D`, `Node` signals e `AnimatedSprite2D` se tocar animacao.
- [x] Ler docs oficiais LimboAI sobre `LimboState`/`LimboHSM` se tocar HSM.
- [x] Adicionar eventos de fase em `state_attack_8dir.gd` sem alterar timing.
- [x] Adicionar `attack_sequence_id` local para correlacionar stamina, janela ativa, hit confirm e interrupcao.
- [x] Emitir `attack_interrupted` quando `_exit()` ocorrer antes de `_finish_attack()`.
- [x] Adicionar `reason` em `attack_interrupted` para separar hit reaction, morte e saida generica de estado.
- [x] Validar em MCP: `open_scene -> play_scene -> get_godot_errors`.
- [x] Confirmar no log pelo menos um caso de ataque consumindo stamina e sendo interrompido antes de `hit_confirmed`.
- [ ] Persistir freeze/status apos QA visual do diretor, se aprovado.

### Fase B - Resource e Componente em Modo Observador
- [x] Criar `CombatClashProfile`.
- [x] Criar `CombatClashComponent` em modo `emit_only_telemetry`.
- [x] Integrar em Player e um hostil via Godot/editor API.
- [x] Nao mudar dano, stamina, knockback, hit reaction ou BT.
- [x] Validar que o componente pode ser copiado para outro ator.

### Fase C - Classificacao de Clash
- [x] Classificar ataques concorrentes por timestamp/fase.
- [x] Emitir `combat_clash_candidate` quando dois ataques forem iniciados dentro de `clash_window_sec`.
- [x] Emitir `parry_candidate` somente se existir profile com `can_parry = true`.
- [x] Manter resultado igual ao baseline enquanto `emit_only_telemetry = true`.
- [x] Validar em log dirigido Player versus Wildcat:
  - `combat_clash_candidate`;
  - `combat_clash_interrupt_classified`;
  - `classification = death_filtered`.
  - Observacao: `valid_hit_reaction_candidate` era apenas candidato observacional; antes da Fase D nao havia regra de gameplay para forcar esse resultado.

### Fase D - Gameplay Opcional e Tuning
- [x] So iniciar apos logs provarem janela consistente.
- [x] Decidir Parry/Clash v1:
  - cancela dano recebido quando o alvo tambem esta atacando o agressor dentro de `clash_window_sec`;
  - nao reduz dano parcialmente;
  - nao gera stagger extra;
  - nao gera refund de stamina;
  - nao gera stamina damage extra.
- [x] Comecar com valores conservadores e data-driven.
- [x] Validar visual e telemetria antes de congelar.
- [x] Auditar regressao de feel e desabilitar resolucao gameplay nos profiles.

### Fase E - QA e Freeze
- [ ] QA visual aprovado pelo diretor.
- [ ] Logs comprovam:
  - `attack_phase_started`;
  - `attack_window_opened`;
  - `attack_interrupted`;
  - `combat_clash_candidate`;
  - retomada de combate sem limpar `combat_target`.
- [ ] Sem regressao em Hit Reaction V9.
- [ ] Sem regressao em Knockback V6.
- [ ] Sem regressao em stamina/kiting/orb.
- [ ] Criar freeze V10 se houver mudanca funcional.

## 10) Criterios de Aceite
Fase A so fica pronta quando:

1. A telemetria provar exatamente em qual fase o ataque foi interrompido.
2. O custo de stamina do ataque interrompido estiver correlacionado com o mesmo `attack_sequence_id`.
3. O log diferenciar ataque que confirmou hit de ataque que gastou stamina e foi anulado.
4. Nao houver mudanca visual nem de balance.

Sprint completa so fica pronta quando:

1. O sistema for plug-and-play.
2. O tuning viver em `.tres`.
3. Player e hostis usarem o mesmo contrato.
4. `Actor8DirLimbo` continuar fachada fina.
5. Godot MCP estiver limpo.
6. Telemetria comprovar a mecanica.

## 11) Riscos e Mitigacoes
1. **Tuning cego:** mitigar com Fase A de telemetria antes de gameplay.
2. **Parry virar logica de Player:** mitigar com componente universal e profile `.tres`.
3. **Inflar Actor8DirLimbo:** bloquear exports/tuning no actor.
4. **Quebrar Hit Reaction V9:** preservar `HitReactionComponent`/`HitReactionState` como executor corporal.
5. **Punir stamina duas vezes:** iniciar `extra_stamina_damage_on_parry = 0.0`; custo do ataque interrompido ja conta como punicao.
6. **Multiplayer futuro:** tratar cliente como intencao; resolucao oficial de clash/parry deve migrar para autoridade do host/servidor quando combate for server-authoritative.

## 12) Fontes Tecnicas
1. Godot `Area2D`, base de hitbox/hurtbox por area:
   - https://docs.godotengine.org/en/stable/classes/class_area2d.html
2. Godot `Object`/signals, base para telemetria e componentes desacoplados:
   - https://docs.godotengine.org/en/stable/classes/class_object.html
3. LimboAI `LimboState`, base do ciclo `_enter`, `_update`, `_exit` do ataque e hit reaction:
   - https://limboai.readthedocs.io/en/stable/classes/class_limbostate.html
4. LimboAI `LimboHSM`, base de transicao `ANYSTATE` e eventos:
   - https://limboai.readthedocs.io/en/stable/classes/class_limbohsm.html
5. Godot `Resource`, base para profiles `.tres` data-driven:
   - https://docs.godotengine.org/en/stable/classes/class_resource.html
6. Godot `Node`, base para componentes plug-and-play em cena:
   - https://docs.godotengine.org/en/stable/classes/class_node.html

## 13) Definicao de Pronto
1. Plano atualizado.
2. Docs/runbooks/skills apontando a sprint como proximo passo planejado.
3. Implementacao somente em branch propria.
4. Fase A entregue antes de qualquer mudanca de balance.
5. MCP validado.
6. Telemetria registrada.
7. Freeze novo criado somente apos QA funcional aprovado.

## 14) Registro de Implementacao - Fase A
Data: 2026-05-12
Status: implementada e validada por MCP, sem mudanca de gameplay.

Arquivos alterados:

1. `res://Scripts/actors/state_attack_8dir.gd`
2. `res://Scripts/combat/hitbox_component.gd`

Eventos adicionados:

1. `attack_stamina_cost`
2. `attack_phase_started`
3. `attack_window_opened`
4. `attack_window_closed`
5. `attack_interrupted`

Campos de correlacao adicionados:

1. `attack_sequence_id`
2. `hitbox_sequence_id`
3. `phase`
4. `hits_count`
5. `reason`

Evidencia MCP:

1. `res://cenas/mundo.tscn` abriu e rodou.
2. `get_godot_errors` nao registrou parse/runtime error novo.
3. Logs confirmaram `attack_stamina_cost` com `attack_sequence_id`.
4. Logs confirmaram fases `windup`, `active` e `recover`.
5. Logs confirmaram `attack_window_opened` e `attack_window_closed`.
6. Logs confirmaram `hit_confirmed` com `attack_sequence_id` e `hitbox_sequence_id`.
7. Logs confirmaram caso central da sprint com multiplos atores:
   - o ator interrompido consome stamina;
   - fica em `windup`;
   - o oponente abre janela ativa e confirma hit;
   - o ator interrompido emite `attack_interrupted`;
   - Hit Reaction assume a HSM depois da interrupcao.

Decisao preservada:

1. Nenhum dano extra de stamina foi implementado.
2. Nenhum parry perfeito foi implementado.
3. Nenhum `CombatClashComponent` foi criado ainda.
4. Nenhuma cena ou `.tres` foi alterada.
5. Hit Reaction V9, Knockback V6, kiting, stamina e orb permanecem como baseline funcional.

## 15) Evidencias de QA por Ator - Fase A

### Brute
Status: valido como primeira prova forte de interrupcao.

Evidencias:

1. `HostileEnemyBrute` pagou stamina antes de concluir o ataque.
2. O ataque estava em `windup`.
3. O Player confirmou hit antes da janela ativa do Brute.
4. `HostileEnemyBrute` emitiu `attack_interrupted`.
5. Alguns casos vieram junto de morte, entao devem ser classificados como `death` e nao como Parry/Clash puro.

Leitura tecnica:

1. Brute prova o conceito de ataque pago e interrompido.
2. Brute tambem prova a necessidade de `interrupt_reason`, porque morte e Hit Reaction normal aparecem proximas no log.

### HostileEnemyLight
Status: valido como prova de whiff/custo pago e janela ativa limpa.

Evidencias:

1. `HostileEnemyLight` pagou `14` stamina com `required = 25.2`.
2. Ataques confirmados exibiram `attack_window_opened`, `hit_confirmed` e `attack_window_closed`.
3. `attack_sequence_id = 7` abriu janela ativa e fechou com `hits_count = 0` e `reason = active_elapsed`.

Leitura tecnica:

1. Light prova o caso de `Whiff Paid Cost`: golpe saiu, nao acertou, stamina foi gasta.
2. Light e bom para calibrar diferenca entre erro normal e interrupcao.

### HostileEnemyBase
Status: valido como prova completa de whiff, hit e Player interrompido.

Evidencias:

1. `HostileEnemyBase` pagou `20` stamina com `required = 32.0`.
2. `attack_sequence_id = 8` abriu janela ativa e fechou com `hits_count = 0`, provando whiff pago.
3. `HostileEnemyBase attack_sequence_id = 43` confirmou hit.
4. O Player tinha `attack_sequence_id = 55`, havia pago stamina e estava em `windup`.
5. O Player emitiu `attack_interrupted` em `windup`.
6. `HostileEnemyBase attack_sequence_id = 44` tambem foi interrompido no golpe de morte, junto de `target_died`.

Leitura tecnica:

1. Base prova que Player e NPC usam o mesmo pipeline.
2. Base prova que precisamos separar `hit_reaction` de `death`.

### Wildcat
Status: melhor prova bidirecional de arquitetura universal.

Evidencias:

1. `Wildcat attack_sequence_id = 8` confirmou hit no Player.
2. O Player tinha `attack_sequence_id = 10`, pagou stamina e estava em `windup`.
3. O Player emitiu `attack_interrupted` e entrou em Hit Reaction.
4. Depois, `Player attack_sequence_id = 11` confirmou hit.
5. O Wildcat tinha `attack_sequence_id = 18`, pagou stamina e estava em `windup`.
6. O Wildcat emitiu `attack_interrupted` e entrou em Hit Reaction.
7. O padrao se repetiu em `Wildcat attack_sequence_id = 19` e em `Player attack_sequence_id = 32`.

Leitura tecnica:

1. Wildcat prova simetria: Player interrompe NPC e NPC interrompe Player.
2. A mecanica nao depende de tipo de inimigo.
3. O futuro componente deve ser global/plug-and-play, nao exclusivo de Player.

## 16) Refinamento de Telemetria - Interrupt Reason
Status: implementado e validado no Godot MCP apos analise dos logs Brute/Light/Base/Wildcat.

Motivo:

1. Os logs mostraram interrupcoes por Hit Reaction normal.
2. Os logs tambem mostraram interrupcoes junto de `target_died`.
3. Sem `reason`, a Fase B poderia confundir Parry/Clash real com morte ou saida generica de estado.

Decisao:

1. `attack_interrupted` passa a emitir `reason`.
2. `reason = hit_reaction` quando a interrupcao vem do `HitReactionComponent`.
3. `reason = death` quando a Health do ator ja esta morta no `_exit()` do ataque.
4. `reason = state_exit` fica como fallback para saidas nao classificadas.
5. A marcacao de `hit_reaction` usa metadata transitoria no ator, sem export, sem wrapper e sem inflar `Actor8DirLimbo`.

Validacao MCP:

1. `res://Scripts/actors/state_attack_8dir.gd` abriu sem parse error.
2. `res://Scripts/combat/hit_reaction_component.gd` abriu sem parse error.
3. `res://cenas/mundo.tscn` abriu e rodou.
4. `get_godot_errors` nao registrou runtime/parse error novo.
5. Logs confirmaram:
   - `HostileEnemyBrute attack_sequence_id = 1`, `phase = windup`, `reason = hit_reaction`;
   - `HostileEnemyBrute attack_sequence_id = 2`, `phase = windup`, `reason = hit_reaction`;
   - `HostileEnemyBrute attack_sequence_id = 3`, `phase = windup`, `reason = hit_reaction`.

Observacao:

1. O teste validou `hit_reaction`.
2. `death` ja foi observado nos logs anteriores como classe necessaria, mas deve ser reamostrado depois com o campo `reason` novo se quisermos congelar a taxonomia final antes da Fase B.

## 17) Registro de Implementacao - Fase B
Data: 2026-05-12
Status: implementada e validada por MCP em modo observador, sem mudanca de gameplay.

Arquivos adicionados:

1. `res://Scripts/combat/combat_clash_profile.gd`
2. `res://Scripts/combat/combat_clash_component.gd`
3. `res://configs/combat/clash/player_combat_clash_profile_v1.tres`
4. `res://configs/combat/clash/wildcat_combat_clash_profile_v1.tres`

Arquivos alterados:

1. `res://Scripts/actors/state_attack_8dir.gd`
2. `res://Scripts/combat/hitbox_component.gd`
3. `res://cenas/player.tscn`
4. `res://cenas/wildcat_1.tscn`

Decisao tecnica:

1. `CombatClashComponent` e plug-and-play e fica como filho do ator.
2. `CombatClashProfile` guarda tuning em `.tres`.
3. A integracao inicial cobre Player e Wildcat porque o Wildcat foi a melhor evidencia bidirecional da Fase A.
4. O componente foi tipado contra `Resource`/`Node` nos pontos de integracao para evitar dependencia fragil de ordem de importacao do Godot.
5. `Actor8DirLimbo` nao recebeu export, tuning ou nova responsabilidade.

Eventos novos em modo observador:

1. `combat_clash_attack_started_observed`
2. `combat_clash_phase_observed`
3. `combat_clash_attack_window_observed`
4. `combat_clash_attack_window_result`
5. `combat_clash_hit_observed`
6. `combat_clash_interrupt_observed`

Garantias preservadas:

1. Nenhum dano extra de stamina foi implementado.
2. Nenhum parry perfeito foi implementado.
3. Nenhuma mudanca em dano, stamina, knockback, hit reaction, BT ou timings de ataque.
4. `emit_only_telemetry = true` nos profiles criados.

Validacao MCP:

1. Scripts de `CombatClashProfile`, `CombatClashComponent`, `state_attack_8dir.gd` e `hitbox_component.gd` abriram sem parse error apos a correcao de tipagem desacoplada.
2. `res://cenas/mundo.tscn` abriu e rodou.
3. `get_godot_errors` nao registrou parse/runtime error novo.
4. Busca no runtime confirmou:
   - `Mundo/Player/CombatClashComponent`;
   - `Mundo/Wildcat/CombatClashComponent`.

Proximo passo:

1. Gerar logs de combate com Player versus Wildcat para confirmar os novos eventos observer.
2. So depois dos logs, decidir se a Fase C esta pronta para congelamento ou se precisa ajustar classificacao.

## 18) Registro de Implementacao - Fase C
Data: 2026-05-12
Status: implementada em modo observador, aguardando QA por log dirigido.

Arquivo alterado:

1. `res://Scripts/combat/combat_clash_component.gd`

Eventos adicionados:

1. `combat_clash_candidate`
2. `combat_clash_interrupt_classified`

Decisao tecnica:

1. O componente mantem um registro estatico leve dos ataques recentes por ator.
2. O registro usa TTL curto de 2 segundos para evitar estado preso.
3. Um candidato temporal exige:
   - ator local atacando alvo;
   - alvo tambem atacando o ator local;
   - diferenca entre inicios dentro de `clash_window_sec`;
   - par unico por `attack_sequence_id`.
4. Interrupcoes sao classificadas sem alterar gameplay:
   - `valid_hit_reaction_candidate`: ataque cruzado dentro da janela e interrupcao por `hit_reaction`;
   - `death_filtered`: interrupcao por morte, nao elegivel para parry;
   - `interrupt_outside_clash_window`: interrupcao real, mas fora da janela;
   - `interrupt_without_temporal_match`: interrupcao sem ataque cruzado registrado;
   - `ignored_interrupt_reason`: razao nao elegivel.
5. `parry_candidate` continua bloqueado por `can_parry = true`; nos profiles atuais, permanece `false`.

Garantias preservadas:

1. Nenhum dano extra de stamina foi implementado.
2. Nenhum refund de stamina foi implementado.
3. Nenhum cancelamento de dano foi implementado.
4. Nenhum timing de ataque foi alterado.
5. `emit_only_telemetry = true` continua preservado.

Validacao MCP:

1. `res://Scripts/combat/combat_clash_component.gd` abriu sem parse error.
2. `res://cenas/mundo.tscn` abriu e rodou.
3. `get_godot_errors` nao registrou parse/runtime error novo.
4. O smoke automatico nao gerou combate suficiente para provar `combat_clash_candidate`; validacao funcional depende de novo log dirigido pelo diretor.

## 19) Registro de Implementacao - Fase D
Data: 2026-05-12
Status: gameplay v1 implementado, auditado e desabilitado nos profiles; observer preservado.

Arquivos alterados:

1. `res://Scripts/combat/combat_clash_component.gd`
2. `res://Scripts/combat/hitbox_component.gd`
3. `res://Scripts/combat/hurtbox_component.gd`
4. `res://configs/combat/clash/player_combat_clash_profile_v1.tres`
5. `res://configs/combat/clash/wildcat_combat_clash_profile_v1.tres`

Decisao de gameplay v1:

1. O parry/clash real acontece antes de `Hurtbox` aplicar knockback, dano e Hit Reaction.
2. O alvo so cancela o hit se:
   - tem `CombatClashComponent`;
   - o profile esta `enabled`;
   - `can_parry = true`;
   - `emit_only_telemetry = false`;
   - o alvo esta em `windup`;
   - o agressor tambem iniciou ataque contra esse alvo;
   - a diferenca entre inicios esta dentro de `clash_window_sec`.
3. Quando resolvido, o hit e cancelado:
   - sem dano;
   - sem knockback;
   - sem Hit Reaction;
   - sem refund;
   - sem stamina damage extra.
4. O custo de stamina ja pago continua sendo a punicao base.

Eventos adicionados:

1. `combat_clash_incoming_hit_classified`
2. `combat_parry_resolved`
3. `hit_cancelled_by_parry`

Profiles apos auditoria:

1. `player_combat_clash_profile_v1.tres`
   - `can_parry = false`
   - `emit_only_telemetry = true`
2. `wildcat_combat_clash_profile_v1.tres`
   - `can_parry = false`
   - `emit_only_telemetry = true`

Validacao MCP:

1. Scripts abriram sem parse error.
2. `res://cenas/mundo.tscn` abriu e rodou.
3. `get_godot_errors` nao registrou parse/runtime error novo.
4. O ruido de UID dos profiles foi removido deixando o script do resource referenciado por path estavel.

Auditoria de regressao:

1. O log confirmou que o Wildcat nao estava batendo sem stamina:
   - cada golpe vinha precedido de `stamina_consumed`;
   - exemplos: `attack_sequence_id = 85`, `97`, `109`, `149`.
2. A mudanca de resultado veio de `combat_parry_resolved`:
   - Player `attack_sequence_id = 25`;
   - Wildcat `attack_sequence_id = 97`;
   - diferenca de 100ms dentro de `clash_window_sec`;
   - o golpe do Player foi cancelado por `hit_cancelled_by_parry`;
   - Wildcat completou o ataque e acertou o Player.
3. Leitura: a regra favoreceu demais quem estava em `windup`, permitindo defender e ainda completar o proprio ataque.
4. Decisao: desabilitar gameplay nos profiles e manter a telemetria/estrutura para uma Fase D2 mais justa.

Correcao aplicada:

1. `CombatClashComponent` limpa o registro do ataque ao entrar em `recover`, reduzindo telemetria antiga como `started_delta_ms` alto.
2. Profiles voltaram para observer:
   - `can_parry = false`;
   - `emit_only_telemetry = true`.
3. MCP gate apos a correcao:
   - `res://cenas/mundo.tscn` abriu e rodou;
   - `get_godot_errors` nao registrou parse/runtime error novo;
   - cena parada apos validacao.

Proxima decisao recomendada:

1. Projetar Fase D2 antes de reabilitar gameplay.
2. A regra D2 deve evitar vantagem unilateral:
   - se cancela o hit do atacante, tambem deve cancelar/interromper o ataque do defensor; ou
   - aplicar uma janela menor/mais explicita; ou
   - exigir fase propria futura de parry, nao `windup` de ataque normal.
