# Docs - Mapa Oficial (Estado Atual)

Data de consolidacao: 2026-05-13
Branch de referencia: `feat/dynamic-loot-dex-v1`

## 1) Fonte principal de estado
1. `status-freeze-funcional-v14-dynamic-loot-dex-2026-05-13.md` (freeze atual: Dynamic Loot & DEX System aprovado)
2. `plano-sprint-balance-scale-v14-1-2026-05-13.md` (micro-freeze V14.1 de escala HP)
3. `plano-sprint-dynamic-loot-dex-v1-2026-05-13.md` (sprint concluida e congelada em V14)
4. `status-freeze-funcional-v13-inventory-datadriven-core-2026-05-13.md` (freeze: Inventory Data-Driven Core aprovado)
5. `plano-sprint-inventory-datadriven-core-v1-2026-05-13.md` (sprint concluida e congelada em V13)
6. `status-freeze-funcional-v12-inventory-expresso-spike-2026-05-13.md` (freeze: Inventory ExpressoBits Spike aprovado)
7. `plano-sprint-inventory-expresso-spike-v1-2026-05-13.md` (sprint concluida e congelada em V12)
8. `status-freeze-funcional-v11-hitbreak-combat-feedback-2026-05-13.md` (freeze historico: Hitbreak Combat Feedback aprovado)
9. `plano-sprint-hitbreak-combat-feedback-v1-2026-05-13.md` (sprint concluida e congelada em V11)
10. `status-freeze-operacional-v10-combat-core-restored-2026-05-13.md` (Combat Core restaurado, Combat Clash temporal removido)
11. `status-freeze-funcional-v9-hostile-hit-reaction-2026-05-12.md` (Hostile Hit Reaction Coverage aprovado)
12. `plano-sprint-combat-clash-parry-v1-2026-05-12.md` (Combat Clash temporal auditado e removido do runtime)
13. `status-freeze-funcional-v8-wildcat-hit-reaction-2026-05-12.md` (Wildcat Hit Reaction aprovado)
14. `plano-sprint-wildcat-hit-reaction-v1-2026-05-12.md` (Wildcat + hostis concluidos)
15. `status-freeze-funcional-v7-hit-reaction-2026-05-12.md` (Player Hit Reaction/Hit Stun universal aprovado)
16. `plano-sprint-universal-hit-reaction-component-v1-2026-05-12.md` (sprint concluida)
17. `status-freeze-funcional-v6-knockback-2026-05-12.md` (knockback modular/Data-Driven com baseline `200.0`)
18. `plano-sprint-combat-knockback-component-v1-2026-05-12.md` (sprint concluida)
19. `status-freeze-funcional-v5-actor-profiles-2026-05-12.md` (actor profiles concluido)
20. `status-freeze-total-combate-tatico-2026-05-11.md` (freeze total aprovado historico)
21. `recomendacoes-techlead-pos-freeze-2026-05-11.md` (proximos passos recomendados)
22. `plano-sprint-health-regen-datadriven-v1-2026-05-11.md` (freeze concluido)
23. `plano-sprint-actor8dir-facade-slimming-v1-2026-05-11.md` (fechamento parcial congelado)
24. `plano-sprint-actor-export-profile-organization-v1-2026-05-11.md` (sprint concluida ate E3; ver V5)
25. `plano-sprint-kiting-datadriven-v1-2026-05-11.md` (sprint concluida)
26. `status-freeze-funcional-v3-limbo-modular-2026-05-11.md` (arquitetura modular LimboAI)

## 1.1 Regra anti-drift (obrigatoria)
1. Quando houver conflito entre docs antigos e estado atual:
   - o freeze V14 de 2026-05-13 vence para o sistema de Loot Dinamico e DEX (ExpressoBits Data-Driven Core);
   - o freeze V13 de 2026-05-13 vence para a infraestrutura Data-Driven de Inventario;
   - o freeze V12 de 2026-05-13 vence para a integracao da Bridge/Authority do ExpressoBits;
   - o freeze V11 de 2026-05-13 vence para Hitbreak Combat Feedback;
   - o freeze operacional V10 de 2026-05-13 vence para Combat Core restaurado e remocao do Combat Clash temporal;
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
10. Combat Clash / Parry Window v1:
   - Fase D/D2 provou tecnicamente `mutual_clash`, mas reprovou como regra global de gameplay;
   - `CombatClashComponent`, `CombatClashProfile` e profiles `.tres` foram removidos do runtime para evitar drift conceitual;
   - Player e Wildcat nao carregam mais componente/profile de Clash;
   - a pesquisa fica registrada no plano como historico tecnico, nao como sistema ativo;
   - o core aprovado continua sendo Hit Reaction/Hit Interrupt: quem acerta primeiro aplica dano, o alvo entra em Taken Damage e o ataque interrompido ja pagou stamina;
   - qualquer Parry futuro deve ser sprint nova de `DefenseComponent`/`ParryComponent` por chance/atributo, consultado antes do dano;
   - nao reengordar `Actor8DirLimbo` e nao criar regra exclusiva de Player.
11. Hitbreak Combat Feedback v1:
   - sprint concluida/congelada em V11 na branch `feat/hitbreak-combat-feedback-v1`;
   - objetivo: brilho/flash data-driven no atacante que causa Hitbreak;
   - apenas feedback visual, sem alterar dano, stamina, Hit Reaction, Knockback, BT ou HSM;
   - usa `CombatFeedbackComponent` + `CombatFeedbackProfile`;
   - Fase A ja integrou o pipeline por evento `hitbreak_success`, sem visual;
   - Fase B ja integrou o Player com shader simples e profile default;
   - Fase C ja integrou o Wildcat com o mesmo componente/profile via Godot/editor API;
   - `hitbreak_success` e emitido somente quando `attack_interrupted.reason == hit_reaction` e existe fonte de dano atual;
   - interrupcao por `death` nao gera falso Hitbreak;
   - usa shader/material por ator em runtime ou fallback controlado por profile;
   - QA visual do Player e Wildcat aprovado pelo diretor;
   - Fase D ja integrou HostileEnemyBase, HostileEnemyLight e HostileEnemyBrute via Godot/editor API;
   - Fase E criou `status-freeze-funcional-v11-hitbreak-combat-feedback-2026-05-13.md`;
   - QA visual/log do Player, Wildcat, Brute, Base e Light aprovado;
   - Parry nao entra nesta sprint; deve virar `DefenseComponent`/`ParryComponent` futuro, data-driven por chance/atributo.
12. Inventory ExpressoBits Spike v1:
   - sprint concluida/congelada em V12 na branch `feat/inventory-expresso-spike-v1`;
   - usa `res://addons/inventory-system/` como core oficial;
   - `res://addons/inventory-system-demos/` e referencia de estudo, nao runtime;
   - database inicial: `res://configs/items/inventory/nexus_inventory_database_v1.tres`;
   - integracao deve nascer por bridge/authority propria do Nexus;
   - cliente envia intent, host valida e executa;
   - nao substituir `EquipmentLoadout` nem alterar combate antes do adapter e QA.
13. Dynamic Loot & DEX V14:
   - sprint concluida na branch `feat/dynamic-loot-dex-v1`;
   - ExpressoBits e a fonte oficial dos dados de equipamento do Player;
   - `NexusEquipmentAdapter` gera `EquipmentLoadout`, `WeaponData` e `CombatActionData` em memoria;
   - `ActorCombatProfileRuntime` deve consultar `actor.get_equipment_loadout_runtime()`, nao `actor.equipment_loadout` direto;
   - stamina, attack range, attack stop distance e kiting do Player dependem dessa fonte runtime;
   - hostis continuam podendo usar fallback de cena/`.tres` enquanto nao forem migrados.
14. Balance Scale V14.1:
   - Wildcat e HostileEnemyBase foram alinhados para `max_health = 50.0`;
   - `wildcat_claw_attack_v1.tres` define `damage = 4.0`, preservando Wildcat como atacante agil;
   - HostileEnemyBase deixou de reutilizar `wildcat_claw_attack_v1.tres` e agora usa `hostile_base_attack_v1.tres`;
   - `hostile_base_attack_v1.tres` define `damage = 5.0`, `stamina_cost = 20.0`, `low_stamina_kite_distance = 130.0` e `knockback_force = 200.0`;
   - HostileEnemyLight permanece `max_health = 50.0`;
   - HostileEnemyBrute permanece `max_health = 75.0`;
   - Player foi ajustado para `max_health = 70.0` para manter uma disputa maior sem voltar ao burst antigo;
   - nenhum script de combate foi alterado.

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
3. `../../docs/godotmcp/runbook-expressobits-seguranca.md`

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
