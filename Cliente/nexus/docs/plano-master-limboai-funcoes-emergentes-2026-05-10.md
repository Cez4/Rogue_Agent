# Plano Master LimboAI - Funcoes para Agentes Emergentes

Data: 2026-05-10  
Escopo: consolidar o uso do LimboAI como cerebro principal de player e NPCs no Nexus, com variacao por dados e sem hardcode por inimigo.

## 1. Objetivo tecnico
1. Usar LimboAI no maximo para decisao de comportamento.
2. Manter HSM para execucao (animacao, ataque, locomocao).
3. Transformar variacao de archetype/personality em dados (BlackboardPlan + profiles + action data).
4. Evitar drift de logica entre player/NPC: mesmo core, diferenca por configuracao.

## 2. Fontes oficiais e referencias usadas
1. LimboAI README local:
   - `res://addons/limboai/README.md`
2. Demo local do LimboAI:
   - `res://demo/ai/tasks/*`
   - `res://demo/ai/trees/*`
3. Referencia interna do projeto:
   - `docs/referencias/limboai-demo/limboai-demo-combate-referencia.md`
4. Documentacao oficial LimboAI:
   - https://limboai.readthedocs.io/en/stable/
   - https://limboai.readthedocs.io/en/stable/classes/featured-classes.html
   - https://limboai.readthedocs.io/en/stable/behavior-trees/using-blackboard.html
   - https://limboai.readthedocs.io/en/stable/hierarchical-state-machines/create-hsm.html
5. Godot NavigationAgent2D:
   - https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html
   - https://docs.godotengine.org/en/stable/classes/class_navigationagent2d.html

## 3. Mapa completo de funcoes LimboAI para o Nexus
### 3.1 Core BT/HSM (base obrigatoria)
1. `BehaviorTree`
   - Armazena a arvore de decisao.
   - No Nexus: cada tipo de agente tem uma BT propria (`res://ai/trees/...`).
2. `BTPlayer`
   - Executor da BT no actor.
   - No Nexus: player e hostis usam BTPlayer para decisao.
3. `Blackboard` + `BlackboardPlan`
   - Estado compartilhado entre tasks.
   - No Nexus: chaves de combate/percepcao/debug padronizadas em constantes.
4. `LimboHSM` + `LimboState`
   - Camada de execucao orientada a eventos.
   - No Nexus: `Idle/Walk/Attack/Wander/Stagger` e estados futuros de cast/interact.
5. `BTState`
   - Estado HSM que hospeda BT (quando for util compor sub-cerebros por estado macro).

### 3.2 Composites (controle de fluxo)
1. `BTSequence`
   - Encadeamento tipo AND (falha interrompe).
   - Uso: Acquire -> Validate -> InRange -> Face -> Attack.
2. `BTSelector`
   - Fallback tipo OR.
   - Uso: Attack branch, senao Chase branch, senao Idle branch.
3. `BTDynamicSelector`
   - Reavaliacao por tick (prioridade dinamica).
   - Uso recomendado para stamina/percepcao emergente.
4. `BTDynamicSequence`
   - Reavaliacao dinamica em sequencia.
   - Uso quando condicoes podem mudar no meio da execucao.
5. `BTProbabilitySelector`
   - Escolha por pesos.
   - Uso: variedade taticas sem scripts por inimigo (flank, disengage, all-in).
6. `BTParallel`
   - Tarefas em paralelo.
   - Uso com cautela para sensores leves/observabilidade.

### 3.3 Decorators (moduladores de comportamento)
1. `BTCooldown`
   - Evita repetir acao forte em alta frequencia.
2. `BTTimeLimit`
   - Aborta acao longa e forca reavaliacao.
3. `BTRunLimit`
   - Executa acao apenas N vezes (ex.: abertura).
4. `BTAlwaysSucceed`
   - Converte falha em sucesso para fluxo resiliente.
5. `BTAlwaysFail`
   - Forca caminho de fallback.
6. `BTInvert`
   - Inverte condicao.
7. `BTRepeat`
   - Repeticao controlada.

### 3.4 Actions/Conditions prontas e custom (pratica do demo)
1. Prontas comuns:
   - `BTWait`, `BTRandomWait`, `BTPlayAnimation`, `BTCallMethod`, `BTCheckVar`.
2. Custom do demo (referencia forte):
   - `get_first_in_group`, `in_range`, `pursue`, `face_target`, `arrive_pos`,
     `select_flanking_pos`, `back_away`, `move_forward`.
3. Custom do Nexus (atuais):
   - acquire/validate/face/chase/request_attack/wait_stamina/perception checks.

## 4. O que ja temos no projeto
1. BT decide / HSM executa / motor locomove.
2. Profiles de combate e acao data-driven.
3. Telemetria de combate e decisao BT.
4. Orb de vida/stamina reativa integrada.
5. Core compartilhado entre player e hostis, com variacao por dados.

## 5. Gap real que falta para "agente emergente"
1. Hoje stamina ainda esta majoritariamente em gating de threshold.
2. Falta decisao tatico-economica: "ataco agora ou preservo para janela melhor?"
3. Falta usar mais blocos nativos do Limbo (probability/decorators) na arvore principal de combate.

## 6. Plano de adocao total (sem quebrar projeto)
### Fase A - Cerebro de stamina inteligente (obrigatoria)
1. Inserir ramo `LowStaminaBehavior` no BT de player e hostis:
   - `hold_range` ou `reposition` ou `pressure_chase` por dados.
2. Substituir logica fixa por prioridade dinamica:
   - `BTDynamicSelector` no topo do combate.
3. Evitar spam de acao:
   - `BTCooldown` + `BTTimeLimit` em ramos ofensivos.

### Fase B - Variacao de personalidade por dados (archetype)
1. BlackboardPlan com parametros:
   - `speed`, `fast_speed`, `slow_speed`
   - `aggression`, `discipline`, `risk_bias`
   - `stamina_reserve_ratio`, `preferred_combo_budget`
2. `BTProbabilitySelector` para escolhas taticas:
   - atacar, recuar curto, flanquear, esperar.
3. Sem script por inimigo; apenas preset/config.

### Fase C - Comportamentos avancados
1. Rage state por dados (boost temporario).
2. Assist/focus de grupo por blackboard compartilhado.
3. Cast/craft channeling usando orb radial + estado HSM de cast.

## 7. Contrato data-driven final (player e NPC)
1. CombatActionData:
   - range, cadence, damage, `stamina_cost`,
   - `attack_stamina_buffer_ratio`,
   - `attack_stamina_resume_multiplier_when_exhausted`.
2. CombatPerceptionProfile:
   - acquire, lose, memory, reacquire, stop_buffer.
3. BlackboardPlan:
   - parametros de velocidade/tatica/personalidade.
4. Stats/Modifiers:
   - alteram budgets e thresholds sem mudar BT script.

## 8. Regras de engenharia (lei do projeto)
1. Nenhuma regra de archetype em hardcode de task/script.
2. Toda nova logica de decisao exige:
   - teste MCP (`open_scene` -> `play_scene` -> `get_godot_errors`)
   - telemetria habilitada e auditada.
3. Toda feature de agente deve nascer com:
   - doc da decisao
   - checklist de regressao
   - parametros em dados.

## 9. Protocolo de validacao (gate)
1. Cenarios obrigatorios:
   - chase curto/longo
   - low stamina
   - kite real (clicando alvo e chao)
   - death/respawn
2. Evidencias em log:
   - `target_acquired`, `reacquire`, `attack_commit`,
   - `attack_blocked_reason`,
   - `low_stamina_entered/exited`,
   - eventos de orb (`orb_stamina_react`, `orb_stamina_exhausted_pulse`).

## 10. Ordem de execucao recomendada (proxima sprint)
1. Fechar BT de stamina inteligente (Fase A).
2. Introduzir `BTProbabilitySelector` e decorators nos hostis base (Fase B parcial).
3. Replicar no player mantendo mesmo cerebro com dados diferentes.
4. Consolidar baseline de tuning em `combat-tuning-matrix-v1.md`.

## 11. Resultado esperado
1. Agentes deixam de ser "threshold bot" e passam a decidir por janela taticamente.
2. Player e NPC compartilham mesma inteligencia com diferenca de personalidade por dados.
3. Escalabilidade para novos inimigos/skills/craft sem explodir complexidade.

