# Arquitetura 2026 - Intencao Contextual + LimboAI

Data: 2026-05-08
Escopo: input mouse-first, interacao contextual, combate perseguir-e-atacar, base MMO.

## Objetivo
Substituir o modelo fixo de clique por um modelo de **intencao contextual**:
- Botao nao define acao final.
- Contexto + alvo + regras definem a acao.

## Principios
- Data-driven: regras e acoes configuraveis via recursos.
- Desacoplamento: input, resolucao de intencao, execucao e rede separados.
- Multiplayer-first: cliente envia intencao, servidor autoritativo resolve.
- LimboAI-first: BT decide, HSM executa.

## Modelo de input
- `interact_primary` (clique principal)
- `interact_secondary` (clique secundario)

### Regra geral
1. Capturar evento de input.
2. Resolver alvo sob cursor.
3. Resolver intencao candidata.
4. Validar contexto.
5. Emitir comando de dominio (nao executar acao direto no input).

## Smart Objects (tudo interagivel)
Criar contrato unico de interacao (componente):
- `InteractableComponent` / `SmartObjectComponent`
- Expõe affordances:
  - `Move`, `Inspect`, `Talk`, `Trade`, `Use`, `Attack`, `Loot`...
- Cada affordance declara requisitos:
  - range, LOS, cooldown, permissao/faccao, item/skill.

## Resolver de intencao (core)
Servico central: `InteractionResolver`.

Entradas:
- ator local
- alvo detectado
- botao/intencao primaria ou secundaria
- contexto do ator (arma, estado, cooldowns, faccao)

Saida:
- `IntentCommand` (ex.: `MoveIntent`, `InspectIntent`, `ChaseAndAttackIntent`, `OpenContextMenuIntent`)

## Mapeamento UX (estilo The Sims)
- Esquerdo no chao: mover.
- Esquerdo em inimigo: atacar (ou selecionar e atacar por regra configuravel).
- Esquerdo em NPC/objeto amigavel: selecionar/inspecionar.
- Direito em NPC/objeto: abrir menu contextual (`PopupMenu`).
- Direito em inimigo: travar alvo + perseguir e atacar.

## Perseguir e atacar (pedido core)
Comando: `ChaseAndAttackIntent(target_id)`.

Fluxo:
1. Setar `target_lock`.
2. BT decide:
   - fora do range: `MoveToTarget`.
   - em range e LOS: `ExecuteAttack`.
   - alvo perdido: `Reacquire` ou falha.
3. HSM executa estados locomocao/ataque.

Range por perfil de arma (data-driven):
- melee -> curto.
- ranged -> longo + validacao LOS/projetil.

## LimboAI (distribuicao de responsabilidades)
- BT: decisao de alto nivel (o que fazer).
- HSM: execucao de baixo nivel (como fazer).
- Blackboard: contexto operacional.

### Regra de Ouro V3 (Modularidade Atômica e Composição Visual)
É estritamente proibido criar "God Scripts" estendendo `BTAction` que acumulem funções matemáticas, temporizadores manuais (`now_ms < limit`) e chamadas de motor de locomoção em um só arquivo. 
Scripts `.gd` do LimboAI devem ser **Ações Atômicas** (ex: `bt_get_kite_position.gd`, que apenas calcula o vetor e encerra). Para gerenciamento de cadência, tempo de locomoção e pausas orgânicas (Breathing Room), deve-se obrigatoriamente utilizar a composição visual de decorators nativos da engine (`BTTimeLimit`, `BTRandomWait`, `BTAlwaysSucceed`).

Chaves recomendadas no blackboard:
- `current_target`
- `target_kind`
- `intent_type`
- `desired_action`
- `desired_range`
- `attack_profile_id`
- `cooldown_until`
- `last_known_target_pos`

## Multiplayer autoritativo (MMO)
Cliente:
- envia somente intencao:
  - `InteractRequest`, `AttackRequest`, `MoveRequest`.

Servidor/Host:
- valida regras (range/nav/LOS/cooldown/faccao).
- simula decisao oficial.
- replica estado e eventos.

Replica minima:
- `target_lock`, `move_state`, `combat_state`, `attack_start`, `hit_confirmed`, `damage_applied`.

## Estrutura sugerida de modulos
- `Scripts/input/` -> captura de input e mapeamento de acoes.
- `Scripts/interaction/` -> resolver de intencao + comandos.
- `Scripts/domain/commands/` -> comandos de dominio.
- `Scripts/combat/` -> validacao e execucao de combate.
- `Scripts/ai/tasks/` -> tasks BT reutilizaveis.
- `Scripts/actors/states/` -> estados HSM.

## Ordem de implementacao (MVP seguro)
1. Unificar action map: `interact_primary`/`interact_secondary`.
2. Implementar `InteractionResolver`.
3. Implementar contrato `Interactable`.
4. Ligar `target_lock + chase/attack`.
5. Conectar range por perfil de arma.
6. Menu contextual via `PopupMenu`.
7. Telemetria de intencao e combate.

## Telemetria recomendada
Eventos:
- `intent_resolved`
- `command_dispatched`
- `target_locked`
- `attack_started`
- `hit_confirmed`
- `damage_applied`
- `command_failed`

Campos:
- actor_id, target_id, intent_type, action_id, reason, timestamp, latency_ms.

## Riscos e mitigacoes
- Risco: logica duplicada entre input e AI.
  - Mitigacao: input so emite comando; AI/combate executam.
- Risco: divergencia cliente/servidor.
  - Mitigacao: servidor valida tudo; cliente apenas preve visualmente.
- Risco: explosao de if/else por tipo de alvo.
  - Mitigacao: contrato de affordance + resolver tabelado.

## Referencias
- Godot InputMap:
  https://docs.godotengine.org/en/4.3/tutorials/inputs/input_examples.html
- Godot Ray Casting:
  https://docs.godotengine.org/en/4.5/tutorials/physics/ray-casting.html
- Godot CollisionObject2D input_event:
  https://docs.godotengine.org/en/4.3/classes/class_collisionobject2d.html
- Godot PopupMenu:
  https://docs.godotengine.org/en/latest/classes/class_popupmenu.html
- Godot NavigationAgent2D:
  https://docs.godotengine.org/en/4.5/classes/class_navigationagent2d.html
- LimboAI BehaviorTree:
  https://limboai.readthedocs.io/en/latest/classes/class_behaviortree.html
- LimboAI LimboHSM:
  https://limboai.readthedocs.io/en/latest/classes/class_limbohsm.html
- LimboAI BlackboardPlan:
  https://limboai.readthedocs.io/en/stable/classes/class_blackboardplan.html
