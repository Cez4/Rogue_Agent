# Auditoria Tecnica - Estado Atual BT/HSM/Combate

Data: 2026-05-09  
Branch de referencia: `feat/decoupling-audit-pass-v2`

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

### Parcial
1. Smart Objects avancados (Talk/Use/Trade com affordances completos) fora desta fase.

2. Telemetria ainda basica (sem correlacao por decisao BT/task id).

3. Restam poucos usos defensivos de reflexao fora da trilha critica:
- `player_motor.gd` (`face_dir` opcional)
- `actor_stats_runtime.gd` (itens heterogeneos)

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
1. BT de percepcao combate data-driven:
- `acquire/lose/reacquire/memory` por stats/profile.

2. Resource de perfil de combate:
- `CombatProfileData` (cadencia, persistencia chase, thresholds).

3. Telemetria BT:
- task enter/exit/status + target id + range final.

4. Teste de regressao MCP (obrigatorio em cada bloco):
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
