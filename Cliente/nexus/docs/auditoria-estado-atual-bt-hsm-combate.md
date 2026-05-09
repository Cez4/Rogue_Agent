# Auditoria Tecnica - Estado Atual BT/HSM/Combate

Data: 2026-05-09  
Branch de referencia: `feat/actor-combat-profile-runtime`

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
- `actor_8dir_limbo.gd` reduziu para 526 linhas mantendo contrato do BT/HSM.
19. Consolidacao de contrato minimo (v5):
- remocao de wrappers privados redundantes sem impacto no contrato publico.
- `actor_8dir_limbo.gd` reduziu para 501 linhas.
20. Consolidacao de contrato minimo (v6):
- remocao de wrappers internos adicionais de lifecycle/combat.
- `actor_8dir_limbo.gd` reduziu para 473 linhas.
21. Integracao tecnica por bridge (v7):
- `ActorRuntimeBridge` centraliza operacoes tecnicas de runtime sem expor novos metodos de gameplay no actor.
- contrato do actor para BT/HSM permanece estavel.

### Parcial
1. Smart Objects avancados (Talk/Use/Trade com affordances completos) fora desta fase.

2. Telemetria ainda basica (sem correlacao por decisao BT/task id).

3. `actor_8dir_limbo.gd` ainda possui wrappers de delegacao que podem ser consolidados em contrato menor.

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
1. Consolidar contrato publico minimo do actor:
   - reduzir wrappers e garantir API estavel para BT/HSM/runtimes.
2. Telemetria BT:
   - task enter/exit/status + target id + range final.
3. Teste de regressao MCP (obrigatorio em cada bloco):
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
