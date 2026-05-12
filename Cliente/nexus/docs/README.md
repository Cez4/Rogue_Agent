# Docs - Mapa Oficial (Estado Atual)

Data de consolidacao: 2026-05-12
Branch de referencia: `feat/universal-hit-reaction-component-v1`

## 1) Fonte principal de estado
1. `status-freeze-funcional-v9-hostile-hit-reaction-2026-05-12.md` (freeze atual: Hostile Hit Reaction Coverage aprovado)
2. `status-freeze-funcional-v8-wildcat-hit-reaction-2026-05-12.md` (Wildcat Hit Reaction aprovado)
3. `plano-sprint-wildcat-hit-reaction-v1-2026-05-12.md` (Wildcat + hostis concluidos)
4. `status-freeze-funcional-v7-hit-reaction-2026-05-12.md` (Player Hit Reaction/Hit Stun universal aprovado)
5. `plano-sprint-universal-hit-reaction-component-v1-2026-05-12.md` (sprint concluida)
6. `status-freeze-funcional-v6-knockback-2026-05-12.md` (knockback modular/Data-Driven com baseline `200.0`)
7. `plano-sprint-combat-knockback-component-v1-2026-05-12.md` (sprint concluida)
8. `status-freeze-funcional-v5-actor-profiles-2026-05-12.md` (actor profiles concluido)
9. `status-freeze-total-combate-tatico-2026-05-11.md` (freeze total aprovado historico)
10. `recomendacoes-techlead-pos-freeze-2026-05-11.md` (proximos passos recomendados)
11. `plano-sprint-health-regen-datadriven-v1-2026-05-11.md` (freeze concluido)
12. `plano-sprint-actor8dir-facade-slimming-v1-2026-05-11.md` (fechamento parcial congelado)
13. `plano-sprint-actor-export-profile-organization-v1-2026-05-11.md` (sprint concluida ate E3; ver V5)
14. `plano-sprint-kiting-datadriven-v1-2026-05-11.md` (sprint concluida)
15. `status-freeze-funcional-v3-limbo-modular-2026-05-11.md` (arquitetura modular LimboAI)

## 1.1 Regra anti-drift (obrigatoria)
1. Quando houver conflito entre docs antigos e estado atual:
   - o freeze V9 de 2026-05-12 vence para Hostile Hit Reaction Coverage;
   - o freeze V8 de 2026-05-12 vence para Wildcat Hit Reaction;
   - o freeze V7 de 2026-05-12 vence para Player Hit Reaction/Hit Stun e game feel de dano recebido;
   - o freeze V6 de 2026-05-12 vence para knockback e game feel de impacto fisico;
   - o freeze V5 de 2026-05-12 vence para perfis sociais de ator;
   - o freeze total de 2026-05-11 vence;
   - os freezes anteriores viram historico tecnico.
2. Docs de tuning/congelamento antigos devem ser lidos como historico, nao como estado operativo da sprint atual.
3. Ordem oficial atual:
   - `status-freeze-funcional-v9-hostile-hit-reaction-2026-05-12.md` e o estado atual da cobertura visual de Hit Reaction em hostis;
   - `plano-sprint-wildcat-hit-reaction-v1-2026-05-12.md` esta fechado para Wildcat e hostis;
   - `status-freeze-funcional-v8-wildcat-hit-reaction-2026-05-12.md` permanece como baseline do Wildcat;
   - `plano-sprint-universal-hit-reaction-component-v1-2026-05-12.md` esta fechado;
   - `status-freeze-funcional-v7-hit-reaction-2026-05-12.md` permanece como baseline do Player;
   - `plano-sprint-combat-knockback-component-v1-2026-05-12.md` esta fechado;
   - `status-freeze-funcional-v6-knockback-2026-05-12.md` permanece como baseline de knockback;
   - `plano-sprint-health-regen-datadriven-v1-2026-05-11.md` esta fechado;
   - `plano-sprint-actor8dir-facade-slimming-v1-2026-05-11.md` esta em fechamento parcial congelado;
   - `plano-sprint-actor-export-profile-organization-v1-2026-05-11.md` esta fechado ate E3; ver freeze V5.
4. A organizacao de exports/perfis deve iniciar por auditoria e profile social/wander com fallback; nao migrar dados de cena sem QA visual.
5. A limpeza de exports sociais/wander/emote deve seguir E0/E1/E2/E3:
   - E0: auditar cobertura e classificar fallback real, override aprovado e tuning fantasma; concluida em 2026-05-11;
   - E1: limpar somente overrides antigos de entidades ja migradas; concluida em 2026-05-11;
   - E2: decidir Player/restantes com profile proprio, profile default ou fallback tecnico;
   - E3: remover exports do actor somente com cobertura total comprovada.
6. Knockback V6:
   - `knockback_force = 200.0` e o baseline aprovado dos ataques principais;
   - a fonte de tuning e sempre `CombatActionData` em `.tres`;
   - nao tunar knockback pelo `KnockbackComponent`, que e receptor fisico modular.
7. Hit Reaction V7:
   - implementado via `HitReactionComponent`, `HitReactionProfile` e `HitReactionState`;
   - Player toca `Dagger01_TakeDamage_*` inteiro ao receber dano;
   - animacao orienta para a origem do golpe, nao para a direcao do knockback;
   - BT preservada como decisora de intencao e HSM executa a reacao corporal.
8. Wildcat Hit Reaction V8:
   - `wildcat_1.tscn` possui `HitReactionComponent` e `LimboHSM/HitReactionState`;
   - profile dedicado: `wildcat_hit_reaction_profile_v1.tres`;
   - animacoes `TakeDamage_*` tocam com `played=true` e duracao de 1.0s;
9. Hostile Hit Reaction V9:
   - `HostileEnemyBase`, `HostileEnemyLight` e `HostileEnemyBrute` possuem `HitReactionComponent` e `LimboHSM/HitReactionState`;
   - Base/Light usam `hostile_light_hit_reaction_profile_v1.tres`;
   - Brute usa `hostile_brute_hit_reaction_profile_v1.tres`;
   - animacoes `TakeDamage_*` tocam com `played=true` e duracao de 1.0s;
   - morte final nao dispara nova hit reaction, preservando death/target lost/respawn.

## 2) Arquitetura e contratos
1. `arquitetura-contratos-estado-atual-2026-05-10.md` (doc mestre)
2. `auditoria-estado-atual-bt-hsm-combate.md`
3. `plano-final-desacoplamento-actor-2026-05-09.md`

## 3) Tuning e producao data-driven
1. `combat-tuning-matrix-v1.md`
2. `enemy-profile-checklist-v1.md`
3. `wildcat-tuning-session-protocol-v1.md`
4. `brute-tuning-session-protocol-v1.md`

## 4) UI de combate (orb)
1. `plano-orb-ui-contextual-combate-v1-2026-05-09.md`
2. `plano-sprint-orb-stamina-gamefeel-v1-2026-05-10.md`
3. `plano-estrategico-gamefeel-stamina-actions-v1-2026-05-10.md` (proxima sprint consolidada)

## 5) Regras de processo (qualidade)
1. `checklist-regressao-pr-actor-bt-hsm.md`
2. `guia-saude-projeto-godot-limboai-2026-05-09.md`

## 6) Referencias externas (base tecnica)
1. Godot Navigation:
   - https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html
2. Godot NavigationAgent2D:
   - https://docs.godotengine.org/en/4.5/classes/class_navigationagent2d.html
3. LimboAI docs:
   - https://limboai.readthedocs.io/en/latest/
4. LimboAI demo interna:
   - `referencias/limboai-demo/README.md`

## 7) Convenio para evitar drift
1. Alteracao de comportamento deve atualizar:
   - `status-freeze-funcional-v2-2026-05-10.md`
   - `combat-tuning-matrix-v1.md` (se afetar tuning)
2. Alteracao de contrato/API deve atualizar:
   - `arquitetura-contratos-estado-atual-2026-05-10.md`
3. Sempre validar com MCP:
   - `open_scene -> play_scene -> get_godot_errors`
4. Ordem de prioridade atual:
   - preservar freeze total;
   - manter Health Regen Data-Driven v1 congelado;
   - manter `Actor8Dir Facade Slimming v1` congelado;
   - organizar exports/perfis em blocos pequenos;
   - tratar Fase E como limpeza controlada, nunca como remocao direta de exports;
   - nao migrar `.tscn`/`.tres` por texto;
   - validar cada bloco no Godot MCP antes de seguir.
5. Sempre que ajustar BT/tarefas taticas, atualizar no mesmo PR:
   - `status-freeze-total-combate-tatico-2026-05-11.md` (estado funcional real),
   - `plano-sprint-port-limbo-demo-tatico-v1-2026-05-10.md` (progresso de sprint).
