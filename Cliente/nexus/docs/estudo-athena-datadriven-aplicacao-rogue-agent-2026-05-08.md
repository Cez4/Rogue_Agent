# Estudo Athena Data-Driven - Aplicacao no Rogue Agent

Data: 2026-05-08  
Escopo: pesquisa tecnica para tuning de combate (sem portar codigo)  
Contexto: Godot + LimboAI + BT/HSM + pipeline data-driven

## 1) Objetivo
Extrair padroes de engenharia data-driven do ecossistema Athena/rAthena para melhorar nosso fluxo de balanceamento por:
1. Archetype
2. Arma/skill
3. Status/modificadores

Sem alterar arquitetura base do projeto nesta fase.

## 2) O que o modelo Athena ensina
1. Dados de gameplay vivem em tabelas/config e nao no codigo de decisao.
2. Separacao forte entre:
   - definicao de entidade (archetype/mob)
   - definicao de item/arma/skill
   - regras de calculo/modificadores
3. Balanceamento iterativo usa:
   - baseline numerico
   - mudanca pequena por ciclo
   - observacao de resultado (telemetria/comportamento)
4. Escala vem de padrao de dados reutilizavel, nao de script por inimigo.

## 3) Mapeamento para nosso projeto

### 3.1 ArchetypeProfile (IA/combate)
Campos alvo:
- `acquire_radius`
- `lose_radius`
- `target_memory_sec`
- `reacquire_interval_sec`
- `attack_stop_buffer`

No projeto:
- `CombatPerceptionProfile`
- stats de combate/percepcao no `StatsComponent`

### 3.2 WeaponProfile (ataque)
Campos alvo:
- `attack_range`
- `windup_sec`
- `active_sec`
- `recover_sec`
- `cooldown_sec`
- `damage`
- `knockback`

No projeto:
- `equipment_loadout.weapon`
- `action_data` da arma (`CombatActionData`)

### 3.3 StatBlock (modificadores)
Campos alvo:
- `attack_range_bonus`
- `attack_range_multiplier`
- `combat_acquire_radius`
- `combat_lose_radius`
- `combat_target_memory_sec`
- `combat_reacquire_interval_sec`
- `attack_stop_buffer`

No projeto:
- `StatModifier` + `StatsComponent`

## 4) Regras de tuning (v1)
1. Tuning e feito em dados, nao em task BT.
2. Uma variavel por vez por ciclo.
3. Ordem fixa por ciclo:
   1. targeting (`acquire/lose/memory/reacquire`)
   2. aproxima/parada (`range/stop_buffer`)
   3. cadencia (`windup/active/recover/cooldown`)
   4. sobrevivencia (`damage/hp`)
4. Sem mexer em input-intent, sem criar feature nova.

## 5) Telemetria obrigatoria para calibrar
Eventos:
1. `target_acquired`
2. `target_lost`
3. `reacquire`
4. `attack_commit`
5. `attack_blocked_reason`
6. `target_died`
7. `respawned`

Leituras chave:
1. muito `out_of_range` + pouco `attack_commit` => stop/range ruim
2. muito `target_lost` em curta distancia => lose/memory agressivo
3. muito `reacquire` sem kill => cadence/damage/HP desbalanceados

## 6) Risco tecnico e mitigacao
Risco: tuning virar refactor.
Mitigacao:
1. manter BT/HSM/motor como estao.
2. alterar somente resources/exports de tuning.
3. validar sempre com MCP no `mundo.tscn`.

## 7) Plano operacional imediato
1. Preencher `combat-tuning-matrix-v1.md` com valores baseline atuais.
2. Rodar 3 ciclos curtos de tuning com MCP.
3. Registrar diff de valores e impacto de telemetria por ciclo.
4. Congelar preset v1 aprovado.

## 8) Fontes
1. rAthena Database Configuration:
https://github.com/rathena/rathena/wiki/Database-Configuration
2. rAthena db/re:
https://github.com/rathena/rathena/tree/master/db/re
3. eAthena scripting reference:
https://www.eathena.org/eathena/svn/trunk/readme/scripting.html
4. Godot NavigationAgent2D:
https://docs.godotengine.org/en/4.5/classes/class_navigationagent2d.html
5. LimboAI BT/Blackboard:
https://limboai.readthedocs.io/en/latest/

