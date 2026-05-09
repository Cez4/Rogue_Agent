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

## Proximo passo imediato
Executar validacao do **Ciclo 7 (Cadence only)**:
1. validar em sessao de 30-60s usando:
   - `docs/wildcat-tuning-session-protocol-v1.md`;
2. confirmar impacto em:
   - frequencia de `attack_commit`;
   - reducao de lock-step em troca de ataques;
   - manutencao de `out_of_range` sob kite;
3. registrar resultado na matriz:
   - `docs/combat-tuning-matrix-v1.md`.

## Riscos e mitigacao
1. Ajuste excessivo de stop buffer causar empurra/oscilacao.
   - mitigar com passos pequenos (+/- 0.5) e MCP por ciclo.
2. Misturar eixos no mesmo ciclo mascarar causa.
   - mitigar com regra de um eixo por vez.
3. Ruido de telemetria atrapalhar leitura.
   - mitigar com painel debug (thought/combat filters + dedupe).
