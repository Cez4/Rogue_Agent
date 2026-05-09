# Plano de Execucao - Tuning Wildcat v1

Data: 2026-05-09
Branch alvo: `feat/final-actor-decoupling-phase`
Status: ativo

## Contexto
- Plano de desacoplamento do actor foi concluido.
- Arquitetura atual preservada:
  - BT decide
  - HSM executa
  - Motor locomove
- Agora o foco e tuning data-driven (sem alterar arquitetura).

## Objetivo
Calibrar o comportamento de combate do Wildcat por microciclos curtos, com evidencia de telemetria e sem regressao funcional.

## Escopo
1. Ajustar somente dados:
   - `configs/combat/profiles/hostile_melee_baseline_v1.tres`
   - (quando necessario) recursos de acao de combate `.tres`
2. Nao alterar:
   - contrato BT/HSM
   - input-intent
   - boundary/bridge do actor

## Ordem obrigatoria dos microciclos
1. Targeting
   - `acquire_radius`
   - `lose_radius`
   - `target_memory_sec`
   - `reacquire_interval_sec`
2. Approach/Stop
   - `attack_stop_buffer`
3. Cadence
   - `windup/active/recover/cooldown`
4. Survivability
   - `hp/damage/knockback`

## Estado inicial desta fase
1. Ciclo 1 (historico):
   - hostile `88/124/0.60/0.18`, `stop_buffer 4.5`
2. Ciclo 2 (aplicado):
   - `acquire_radius: 88.0 -> 92.0`
   - `lose_radius: 124.0 -> 132.0`
   - `target_memory_sec: 0.60 -> 0.75`
   - `reacquire_interval_sec: 0.18 -> 0.16`
   - `attack_stop_buffer` mantido em `4.5`

## Criterios de aceite por ciclo
1. MCP gate obrigatorio:
   - `open_scene(res://cenas/mundo.tscn)`
   - `play_scene(current)`
   - `get_godot_errors` sem erro novo
2. Telemetria coerente:
   - `target_acquired`, `reacquire`, `attack_blocked_reason`, `attack_commit`, `target_died`, `respawned`
3. Sem regressao de fluxo:
   - chase por clique direito hostil
   - ataque commit completo
   - morte/respawn funcionais

## Estado atual consolidado
1. Ciclo 6 (Approach/Stop) aplicado:
   - `hostile.attack_stop_buffer: 4.0 -> 4.8`
2. Ciclo 7 (Cadence) aplicado:
   - `wildcat claw recover_sec: 0.22 -> 0.24`
   - `wildcat claw cooldown_sec: 0.32 -> 0.36`
3. Ciclo 8 (Player Targeting) aplicado:
   - `player lose_radius: 156.0 -> 172.0`
   - `player target_memory_sec: 1.2 -> 1.6`
   - `player reacquire_interval_sec: 0.12 -> 0.10`
4. Telemetria de cancelamento separada por motivo:
   - `chase_canceled` agora inclui `reason` e `manual_lock`
   - permite distinguir cancelamento intencional de kite (`reason=input_move`) de perda real de percepcao.

## Proximo passo imediato
Executar **Ciclo 9 (Player Targeting fine-tune)**:
1. manter arquitetura e ataque sem alteracao;
2. ajustar somente dados do profile do player em passos pequenos:
   - `target_memory_sec` e/ou `lose_radius`;
3. validar em sessao 30-60s com kite real (clique no chao);
4. usar telemetria para separar:
   - esperado: `chase_canceled reason=input_move`;
   - problema real: `chase_canceled` sem `input_move` em lock manual.

## Riscos e mitigacao
1. Ajuste excessivo de stop buffer causar empurra/oscilacao.
   - mitigar com passos pequenos (+/- 0.5) e MCP por ciclo.
2. Misturar eixos no mesmo ciclo mascarar causa.
   - mitigar com regra de um eixo por vez.
3. Ruido de telemetria atrapalhar leitura.
   - mitigar com painel debug (thought/combat filters + dedupe).
