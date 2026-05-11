# Checklist de Regressao PR - Actor / BT / HSM

Data: 2026-05-09
Escopo: PRs que alteram actor, runtimes, BT tasks, HSM states, input de intencao, combate, telemetria.

## 1) Boundary/Contrato (obrigatorio)
- [ ] Sem acesso novo a detalhes internos do actor fora de:
  - `Scripts/actors/services/actor_runtime_bridge.gd`
  - API publica de gameplay do `Actor8DirLimbo`
- [ ] Novas regras de dominio ficam em runtime/task (nao no actor monolitico).
- [ ] Sem `has_method/.call` na trilha critica de combate/chase.
- [ ] Chaves de blackboard novas entram em `Scripts/ai/blackboard_keys.gd`.

## 2) Gate MCP (obrigatorio)
- [ ] `open_scene(res://cenas/mundo.tscn)` executado.
- [ ] `play_scene(current)` executado.
- [ ] `get_godot_errors` sem erro novo de parse/runtime.
- [ ] Telemetria observada sem ruído anormal.

## 3) Regressao funcional (obrigatorio)
- [ ] Clique no chao: move e cancela intencao de combate.
- [ ] Clique de ataque em hostile: atualiza alvo sem parar o motor durante kiting automatico.
- [ ] Spam de clique de ataque em hostile: nao quebra reposicionamento por baixa stamina.
- [ ] Clique manual no chao durante combate: cancela combate e permite fuga manual imediata.
- [ ] Chase para em `get_attack_stop_distance()` (sem empurrar alvo).
- [ ] Ataque compromissado: nao cancela no meio da animacao.
- [ ] Sequencia de combate preservada: `InRange -> Face -> RequestAttack`.
- [ ] Baixa stamina usa custo real do ataque equipado, nao threshold percentual fixo.
- [ ] Death/respawn preservados (desativa hurtbox/collision e reativa no respawn).

## 4) Telemetria (obrigatorio)
- [ ] Eventos de combate continuam emitidos:
  - `target_acquired`
  - `attack_started`
  - `attack_commit`
  - `hit_confirmed`
  - `target_died`
  - `respawned`
- [ ] `bt_decision` continua funcional para debug de pensamento.
- [ ] Se `boundary_guard_enabled=true`, evento `runtime_boundary_violation` aparece apenas quando houver uso indevido.

## 5) Qualidade de codigo (obrigatorio)
- [ ] Sem duplicacao de regra entre task e runtime.
- [ ] Sem hardcode novo de valores de percepcao/range/cadencia fora de perfil/stats.
- [ ] Hardcodes legados aceitos no freeze estao documentados antes de qualquer migracao.
- [ ] Assinaturas tipadas preservadas (especialmente `actor: Actor8DirLimbo` nos runtimes).

## 6) Saida do PR (obrigatorio)
- [ ] Atualizar docs de status impactados:
  - `docs/mvp-limboai-combate-wander-status.md`
  - `docs/auditoria-estado-atual-bt-hsm-combate.md`
- [ ] Registrar risco residual e prox. passo tecnico.
- [ ] Se alterar baseline congelado, atualizar `docs/status-freeze-total-combate-tatico-2026-05-11.md`.
- [ ] Fluxo Git executado em modo serial (sem paralelismo) e sync confirmado:
  - `git status -sb`
  - `git rev-list --left-right --count origin/<branch>...HEAD` = `0 0`.
