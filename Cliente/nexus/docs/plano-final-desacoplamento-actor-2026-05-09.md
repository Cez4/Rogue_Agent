# Plano Final - Desacoplamento do Actor (Pre-escala de Conteudo)

Data: 2026-05-09  
Branch alvo: `feat/final-actor-decoupling-phase`

## Contexto
- O projeto ja concluiu o desacoplamento **essencial** (BT decide, HSM executa, runtimes tipados, bridge tecnico).
- Antes de escalar com muitos NPCs, itens, armaduras e novas mecanicas, o custo de refator sobe muito se o actor continuar concentrando orquestracao demais.
- Decisao tecnica: fechar o **acabamento final** do actor agora (hardening de longo prazo).

## Objetivo desta etapa
Deixar `actor_8dir_limbo.gd` como orquestrador fino, com contrato publico minimo e estavel, evitando crescimento de logica interna.

## Definicao de pronto (DoD)
1. Actor com contrato publico explicitamente documentado por seccao:
- Gameplay API (BT/HSM/Controller usam).
- Bridge-only API (uso tecnico interno).

2. Sem logica densa nova no actor:
- regras de percepcao/targeting/social/ataque ficam em runtimes/tasks.

3. Sem regressao funcional:
- chase, attack, death, respawn, look/wander, emotes, hitbox/hurtbox.

4. Gate de qualidade por microcorte:
- `open_scene -> play_scene -> get_godot_errors`
- auditoria de telemetria (combat + thought) sem ruido excessivo.

## Escopo tecnico (cortes pequenos)
### Corte 1 - Boundary/API freeze
- Mapear e congelar API publica do actor.
- Marcar metodos internos como privados quando nao sao contrato real.
- Remover wrappers residuais que nao sao usados fora da camada tecnica.

### Corte 2 - Bridge hygiene
- Garantir que servicos legados usem somente:
  - ActorRuntimeBridge
  - API publica de gameplay
- Proibir acesso acidental a detalhes internos do actor.

### Corte 3 - Telemetria de contrato
- Manter `bt_decision` com filtros atuais.
- Adicionar marcador tecnico opcional para violacao de boundary (somente debug).

Status (2026-05-09):
- Corte 1: concluido.
- Corte 2: concluido no essencial.
- Corte 3: concluido (flag debug `boundary_guard_enabled` + evento `runtime_boundary_violation` no `ActorRuntimeBridge`).
- Corte 4: concluido (docs consolidados + checklist padrao de regressao para PR).

### Corte 4 - Doc + checklist final
- Atualizar docs de auditoria e status com fronteira final.
- Checklist de regressao padrao para PRs futuros.
- Entregue em: `docs/checklist-regressao-pr-actor-bt-hsm.md`.

## Riscos e mitigacao
1. Regressao de comportamento em ataque/chase.
- Mitigacao: microcortes + MCP gate em cada passo.

2. Drift de contrato entre task e runtime.
- Mitigacao: centralizar keys/contratos em arquivos unicos e revisar chamadas.

3. Ruido de log atrapalhar tuning.
- Mitigacao: manter painel debug + presets de telemetria (`quiet/balanced/verbose`) como proximo opcional.

## Ordem recomendada apos esta etapa
1. Fechar acabamento final do actor (este plano).
2. Entrar em tuning v1 data-driven (`combat-tuning-matrix-v1.md`):
   - Targeting -> Approach/Stop -> Cadence -> Survivability.
3. Expandir template de inimigos sobre contrato estavel.

## Referencias oficiais usadas
- Godot Signals (desacoplamento por observer):  
  https://docs.godotengine.org/en/latest/getting_started/step_by_step/signals.html
- Godot GDScript style/code order (manutenibilidade):  
  https://docs.godotengine.org/en/4.3/tutorials/scripting/gdscript/gdscript_styleguide.html
- LimboAI Blackboard (contratos de dados e escopo):  
  https://limboai.readthedocs.io/en/stable/behavior-trees/using-blackboard.html
