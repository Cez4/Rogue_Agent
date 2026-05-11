# Auditoria Tecnica - Estado Atual BT/HSM/Combate

Data: 2026-05-09  
Branch de referencia: `feat/final-actor-decoupling-phase`

## Escopo desta auditoria
- Consolidar o estado real do combate/intencao contextual.
- Evitar regressao arquitetural durante evolucao para LimboAI-first.
- Definir checklist objetivo do que esta fechado, parcial e pendente.

## Arquitetura vigente (fonte de verdade)
- **BT (LimboAI)** decide comportamento de combate do player (`chase/face/range/attack`).
- **HSM (LimboHSM)** executa estados de ataque/animacao.
- **PlayerMotor** executa locomocao/nav/avoidance.
- **InteractionResolver** interpreta input contextual (mouse-first) e seta intencao/alvo.

Regra de autoridade:
1. BT decide **o que fazer**.
2. HSM/Motor executam **como fazer**.
3. Nao duplicar logica de chase fora das tasks BT quando `use_bt_brain = true`.

## Status consolidado

### Fechado
1. Input por intencao:
- `interact_primary` / `interact_secondary`.

2. Regras mouse-only:
- Esquerdo em chao: move.
- Esquerdo em hostile: `none` (nao ataca/nao chase).
- Direito em hostile: `chase_attack`.

3. `InteractionResolver` central e `InteractableComponent` formal.

4. BT-first no player:
- `use_bt_brain = true`.
- `BTPlayer` ativo no player.
- loop manual de chase bloqueado nesse modo.

5. Ataque compromissado:
- task de ataque fica `RUNNING` ate fim do ataque.
- chase nao retoma no meio da animacao.

6. Correcao de mira/facing no ataque:
- face para alvo antes de atacar.
- hitbox orientada por direcao 8-dir.
- ataque nao usa mais direcao de `velocity` para escolher golpe.

7. Pos-morte do wildcat funcional:
- cancel intents.
- disable hurtbox/collision.
- respawn/reset configuravel.

8. Erro de depurador de flush fisico corrigido:
- uso de `set_deferred` para `monitoring`, `monitorable`, `disabled`.

9. Telemetria minima:
- `attack_started`, `hit_confirmed`, `target_died`, `chase_canceled`, `respawned`.

10. Base inicial de stats/modifiers:
- `StatsComponent`.
- `StatModifier`.
- `stat_modifiers` em equipamento.

11. Integracao inicial de stats em combate/percepcao:
- bonus/multiplicador de range.
- distancia de parada para ataque.
- percepcao de look consultando stats.

12. Desacoplamento tecnico consolidado:
- componentes core tipados (`Actor8DirLimbo`, `PlayerController`, `PlayerMotor`);
- tasks BT principais sem `has_method/.call` na trilha critica;
- estados HSM principais sem reflexao dinamica no fluxo de execucao;
- keys de blackboard centralizadas em `AIBlackboardKeys`.
13. Runtime de perfil de combate extraido:
- `ActorCombatProfileRuntime` com range/percepcao/reacquire data-driven.
14. Runtime de targeting consolidado:
- acquire/validate/reacquire centralizados em `ActorTargetingRuntime`.
15. Setup/lifecycle extraidos do actor:
- `ActorSetupRuntime` (`_ready`, setup estrutural, sinais, interactable, HSM).
- `ActorLifecycleRuntime` (respawn/reset/reativacao + telemetria).
16. Tipagem no caminho de hit/hurt:
- `HitboxComponent` chama `HurtboxComponent` tipado.
- `HurtboxComponent` chama `HealthComponent` tipado.
17. `attack_blocked_reason` padronizado:
- `combat_blocked_reasons.gd` como fonte unica de motivos.
18. Runtime de action/animacao extraido:
- `ActorActionRuntime` centraliza face/play/wait/orient/finalizacao de ataque.
- `actor_8dir_limbo.gd` reduziu para 526 linhas mantendo contrato do BT/HSM. (historico)
19. Consolidacao de contrato minimo (v5):
- remocao de wrappers privados redundantes sem impacto no contrato publico.
- `actor_8dir_limbo.gd` reduziu para 501 linhas. (historico)
20. Consolidacao de contrato minimo (v6):
- remocao de wrappers internos adicionais de lifecycle/combat.
- `actor_8dir_limbo.gd` reduziu para 473 linhas. (historico)
21. Integracao tecnica por bridge (v7):
- `ActorRuntimeBridge` centraliza operacoes tecnicas de runtime sem expor novos metodos de gameplay no actor.
- contrato do actor para BT/HSM permanece estavel.
22. Bridge social/wander (v8):
- estado social (idle/wander/look/emote request/priority) migrado para bridge tecnico.
- `actor_8dir_limbo.gd` reduzido para 469 linhas mantendo comportamento. (historico)
23. Boundary hardening adicional:
- `ActorRuntimeBridge` tipado para `Actor8DirLimbo` (contrato tecnico explicito).
- conexao de `Health.death` via API publica (`on_health_death`) sem dependencia de metodo privado.
24. Telemetria de decisao BT (v1):
- helper `Scripts/ai/bt_decision_telemetry.gd` adicionado.
- tasks de combate principais instrumentadas com `task/status/reason`.
- chave `debug_bt_decision_telemetry` em `AIBlackboardKeys`.
- debug OFF por padrao (ativacao explicita por blackboard var).
26. Telemetria de decisao BT (v2):
- cobertura estendida para tasks sociais/wander (`acquire_target`, `is_target_in_range`, `look_at_target`, `idle_wander_loop`).
- mantido modelo debug-gated (OFF por padrao).
- validacao MCP + logs sem erro novo.
25. Boundary 100% (hardening de consistencia):
- runtimes legados de actor migrados para assinatura `actor: Actor8DirLimbo`.
- reduz risco de acoplamento acidental fora de bridge/contrato tecnico.
- validacao MCP + logs sem erro novo.
27. Telemetria runtime com controle operacional:
- painel de debug (F9) com toggles de stream.
- stream de combate sempre disponivel e filtravel por `combat_enabled`.
- stream de pensamento (`bt_decision`) filtravel por:
  - `thought_enabled`
  - dedupe por chave
  - throttle por ator
  - transicoes-only + heartbeat.
- persistencia local em `user://debug_telemetry.cfg`.
28. Hardening de contrato com marcador opcional:
- `ActorRuntimeBridge` emite `runtime_boundary_violation` quando `boundary_guard_enabled` estiver ativo e houver chamada fora da camada esperada.
- controle global em `DebugTelemetrySettings` (`boundary_guard_enabled`, default OFF).
29. Plano final de desacoplamento concluido:
- cortes 1-4 concluídos.
- checklist padrao de regressao para PR criado em `docs/checklist-regressao-pr-actor-bt-hsm.md`.
30. Hardening operacional de versionamento:
- fluxo Git serial formalizado no runbook (sem comandos Git em paralelo).
- validacao de sincronizacao por `rev-list` (`0 0` = local/remoto alinhados).
- tratamento padrao para falhas operacionais de ambiente (`index.lock`/SSH intermitente) sem risco ao historico.

### Parcial
1. Smart Objects avancados (Talk/Use/Trade com affordances completos) fora desta fase.

2. Telemetria BT ainda parcial:
- combate + social/wander cobertos;
- faltam (opcional) enter/exit separado por task.

3. Acabamento de boundary:
- concluido no essencial; manter apenas disciplina de contrato em novas tasks/runtimes.

### Fora do escopo atual
1. Multiplayer autoritativo completo (host resolve tudo e replica oficial).
2. UX avancada (tooltip/highlight/fila/menu contextual completo).
3. Sistema de magia/skill tree completo.

## Riscos tecnicos atuais
1. Regressao de autoridade:
- adicionar task nova que move/ataca fora da sequencia pode conflitar com HSM/Motor.

2. Regressao de animacao:
- qualquer chamada de `face_toward` durante chase sem controle pode puxar animacao errada.

3. Regressao de range:
- usar `get_attack_range()` para stop sem buffer pode voltar a encostar/empurrar.

## Guardrails obrigatorios (nao quebrar)
1. Quando `use_bt_brain = true`:
- proibido loop manual de chase paralelo.

2. Ataque sempre:
- `InRange -> Face -> RequestAttack`.

3. Durante `_attack_pending = true`:
- nao perseguir.
- nao trocar animacao para walk/idle de forma indevida.

4. Desligar/ligar colisao em sinais de hit/death:
- sempre `set_deferred`.

5. Range de stop para combate:
- usar `get_attack_stop_distance()` (com buffer), nao range bruto.

## Checklist de fechamento do proximo ciclo
1. Health Regen Data-Driven v1:
   - concluida/congelada.
   - centralizou contrato de "ator em combate" antes do refactor amplo do actor.
2. Actor8Dir Facade Slimming v1:
   - sprint ativa, depois do Health Regen.
   - objetivo: reduzir `actor_8dir_limbo.gd` sem alterar contrato BT/HSM/Controller.
3. Boundary 100% (acabamento final):
   - concluido no essencial nesta fase.
   - proximo ciclo tecnico de refactor conforme:
     - `docs/plano-sprint-actor8dir-facade-slimming-v1-2026-05-11.md`
4. Telemetria BT v2:
   - concluida no essencial (social/wander cobertos);
   - opcional: eventos enter/exit separados.
5. Teste de regressao MCP (obrigatorio em cada bloco):
   - `play_scene`
   - `get_godot_errors`
   - validacao de comportamento (chase/stop/face/attack/death/respawn).

## Referencias tecnicas
- Godot NavigationAgent2D:  
https://docs.godotengine.org/en/4.5/classes/class_navigationagent2d.html

- LimboAI Behavior Trees:  
https://limboai.readthedocs.io/en/latest/classes/class_behaviortree.html

- LimboAI BTAction status (`RUNNING/SUCCESS/FAILURE`):  
https://limboai.readthedocs.io/en/latest/classes/class_btaction.html

- LimboAI Blackboard:  
https://limboai.readthedocs.io/en/latest/behavior-trees/using-blackboard.html
> Nota de precedencia (2026-05-10): este documento contem historico de cortes de desacoplamento.
> Para estado operativo atual, considerar primeiro:
> 1. `docs/status-freeze-funcional-v2-2026-05-10.md`
> 2. `docs/plano-sprint-port-limbo-demo-tatico-v1-2026-05-10.md`
> 3. `docs/arquitetura-contratos-estado-atual-2026-05-10.md`
> Nota de roadmap (2026-05-11): Health Regen foi executado antes de Actor8Dir Facade Slimming; a sprint ativa agora e o slimming do actor.
