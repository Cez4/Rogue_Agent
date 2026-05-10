# Plano Estrategico - Gamefeel de Stamina + Action Cast Universal (v1)

Data: 2026-05-10  
Status: em execucao (A concluido, B concluido em codigo, C iniciado)  
Escopo: evolucao de gamefeel sem quebrar arquitetura BT/HSM/Motor

## 1) Resumo do contexto (estado real antes da fase)
1. Arquitetura base estabilizada:
- `InteractionResolver` decide intencao de input.
- BT decide comportamento.
- HSM executa estados/animacao.
- Motor locomove.
2. Combate e stamina ja data-driven:
- custos em `CombatActionData.stamina_cost`.
- baseline stamina v1 fechado por telemetria:
  - Light=14, Wildcat=20, Brute=28.
3. Orb de stamina funcional e global:
- `stamina_orb_profile_v1.tres` unico para todos.
- variacao vem do consumo real (`spent_ratio`), nao de script por inimigo.

## 2) Problema de gamefeel identificado
No estado atual, `stamina_exhausted` pode forcar bloqueio/stagger duro.
Com custos de stamina por ataque ja funcionando, o bloqueio total vira friccao desnecessaria.

Objetivo de UX/gamefeel:
1. nao travar personagem por exaustao;
2. manter inteligencia ativa (player e NPC) em baixa stamina;
3. transformar exaustao em sinal tatico (chain futura, cast, regen ativa).

## 3) Decisao tecnica consolidada
### 3.1 Stamina zero sem hard-lock
1. Remover transicao forcada de exaustao para estado de bloqueio global.
2. Manter gate natural:
- sem stamina suficiente, ataque nao inicia (`request_attack` falha limpo).
3. Substituir lock por feedback:
- emote de exaustao com cooldown anti-spam.

### 3.2 BT low stamina behavior (player e NPC)
Quando sem stamina:
1. entrar em ramo de comportamento de baixa stamina;
2. opcoes iniciais:
- esperar regen curto (wait);
- reposicionar defensivo leve;
- continuar perseguindo sem tentar atacar ate `has_stamina`.

Regra: mesma logica para player e NPC (Sims-like agents).

### 3.3 Action cast universal (futuro imediato)
Criar sistema unico de cast/progresso reutilizavel para:
1. skill;
2. craft;
3. interacao longa;
4. channels e chains.

## 4) Viabilidade tecnica (analise)
Viabilidade: alta.

Motivos:
1. sinais de stamina ja existem (`stamina_changed`, `exhausted`, `recovered`);
2. BT/HSM ja desacoplados e com telemetria ativa;
3. UI procedural de orb ja integrada (pipeline de presenter/shader pronto);
4. tuning por `.tres` ja faz parte do fluxo oficial.

Risco principal:
1. regressao de comportamento por mistura de logica em BT/HSM.
Mitigacao:
1. alterar por microblocos com gate MCP em cada bloco.

## 5) Contratos a adicionar/ajustar (data-driven)

### 5.1 Contrato de exaustao visual (actor/profile)
Campos novos sugeridos:
1. `stamina_exhausted_emote_name`
2. `stamina_exhausted_emote_hold_sec`
3. `stamina_exhausted_emote_cooldown_sec`

### 5.2 Contrato de decisao low stamina (BT)
Condicoes/tasks:
1. `BTCondition_HasStaminaForAction`
2. `BTCondition_IsLowStamina`
3. `BTAction_WaitStaminaRegen`
4. `BTAction_RepositionDefensive`

### 5.3 Contrato de cast universal
`ActionCastData` (`.tres`) com:
1. `action_id`
2. `cast_time_sec`
3. `cooldown_sec`
4. `interruptible`
5. `costs` (stamina/mana/item)
6. `result_payload`
7. `tags` (`combat`, `craft`, `utility`, etc)

`ActionCastComponent` sinais:
1. `cast_started(action_id, duration_sec)`
2. `cast_progress(action_id, t01)`
3. `cast_finished(action_id)`
4. `cast_canceled(action_id, reason)`

## 6) UI de progresso radial (acoes)
Objetivo: barra radial universal para qualquer acao com cast.

Opcao MVP aprovada:
1. shader radial simples como renderer de `progress`.
2. presenter desacoplado (UI so le sinal de cast, nao decide gameplay).

Reuso planejado:
1. skill chain (ex: Second Wind);
2. craft procedural;
3. interacoes longas no mundo.

## 7) Sequencia de implementacao (microblocos)
### Bloco A - remover hard-lock de exaustao
1. retirar transicao forcada para bloqueio global;
2. manter regra de custo de stamina no ataque.

### Bloco B - emote de exaustao
1. conectar `exhausted` ao emote data-driven com cooldown.

### Bloco C - BT low stamina
1. inserir ramo low stamina para player e NPC;
2. behavior inicial: wait/reposition + retry ataque quando houver stamina.

## 7.1) Progresso real desta sprint
1. Bloco A concluido:
- removido lock por `stamina.exhausted` no HSM.
- ataque permanece bloqueado apenas por `stamina_cost` vs stamina atual.
2. Bloco B concluido em codigo:
- sinal `Stamina.exhausted` conectado no setup runtime.
- emote de exaustao data-driven adicionado no actor.
- cooldown anti-spam por actor via runtime bridge.
3. Bloco C iniciado:
- `BTRequestAttack` agora valida stamina antes de tentar iniciar ataque.
- novo motivo de bloqueio: `insufficient_stamina`.

### Bloco D - ActionCast foundation
1. criar `ActionCastData` e `ActionCastComponent`;
2. emitir sinais de cast.

### Bloco E - UI radial de cast
1. presenter radial generico consumindo `cast_progress`.

### Bloco F - primeira acao real (Second Wind)
1. cast curto;
2. restaurar % de stamina por dado/stat;
3. cooldown data-driven.

## 8) Telemetria obrigatoria da fase
Novos eventos:
1. `low_stamina_entered`
2. `low_stamina_exited`
3. `stamina_exhausted_emote_played`
4. `action_cast_started`
5. `action_cast_progress`
6. `action_cast_finished`
7. `action_cast_canceled`

Eventos existentes que continuam obrigatorios:
1. `stamina_consumed`
2. `stamina_exhausted`
3. `stamina_recovered`
4. `orb_stamina_react`
5. `orb_stamina_exhausted_pulse`

## 9) Criterios de aceite (qualidade)
1. stamina zero nao trava personagem (player/NPC).
2. BT continua ativa e coerente em baixa stamina.
3. emote de exaustao sem spam.
4. sem erro novo em:
- `open_scene -> play_scene -> get_godot_errors`
5. logs de telemetria demonstram ciclo completo:
- `consumed -> exhausted -> low_stamina_behavior -> recovered -> attack_resume`.

## 10) Riscos e mitigacoes
1. Drift de comportamento entre player e NPC:
- usar mesmas tasks/contratos.
2. UI acoplar regra de gameplay:
- presenter apenas visual (signal-driven).
3. Regressao por mudanca em estados:
- microcommit por bloco + gate MCP.

## 11) Links e referencias
Interno:
1. `docs/status-freeze-funcional-v2-2026-05-10.md`
2. `docs/combat-tuning-matrix-v1.md`
3. `docs/arquitetura-contratos-estado-atual-2026-05-10.md`
4. `docs/checklist-regressao-pr-actor-bt-hsm.md`

Externo:
1. LimboAI custom tasks:
   - https://limboai.readthedocs.io/en/v1.4.1/behavior-trees/custom-tasks.html
2. LimboAI BehaviorTree:
   - https://limboai.readthedocs.io/en/latest/classes/class_behaviortree.html
3. Godot ProgressBar:
   - https://docs.godotengine.org/en/stable/classes/class_progressbar.html
4. Shader radial referencia:
   - https://godotshaders.com/shader/simple-radial-progress-bar-2/

## 12) Decisao de governanca
Este documento vira referencia da proxima sprint de gamefeel tatico.
Toda alteracao da fase deve atualizar:
1. este plano;
2. `status-freeze-funcional-v2-2026-05-10.md`;
3. `combat-tuning-matrix-v1.md` (se mexer em custo/cadencia).
