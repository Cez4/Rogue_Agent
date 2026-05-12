# Docs - Mapa Oficial (Estado Atual)

Data de consolidacao: 2026-05-11
Branch de referencia: `feat/actor-export-profile-organization-v1`

## 1) Fonte principal de estado
1. `status-freeze-total-combate-tatico-2026-05-11.md` (freeze total aprovado)
2. `recomendacoes-techlead-pos-freeze-2026-05-11.md` (proximos passos recomendados)
3. `plano-sprint-health-regen-datadriven-v1-2026-05-11.md` (freeze concluido)
4. `plano-sprint-actor8dir-facade-slimming-v1-2026-05-11.md` (fechamento parcial congelado)
5. `plano-sprint-actor-export-profile-organization-v1-2026-05-11.md` (sprint ativa; Fase E1 concluida, proxima decisao e E2 para Player/restantes)
6. `plano-sprint-kiting-datadriven-v1-2026-05-11.md` (sprint concluida)
7. `status-freeze-funcional-v3-limbo-modular-2026-05-11.md` (arquitetura modular LimboAI)
8. `status-freeze-funcional-v2-2026-05-10.md` (baseline historico Orb/Stamina)
9. `plano-sprint-port-limbo-demo-tatico-v1-2026-05-10.md` (sprint tatico fechada pelo freeze)
10. `mvp-limboai-combate-wander-status.md` (historico consolidado + links atuais)

## 1.1 Regra anti-drift (obrigatoria)
1. Quando houver conflito entre docs antigos e estado atual:
   - o freeze total de 2026-05-11 vence;
   - os freezes anteriores viram historico tecnico.
2. Docs de tuning/congelamento antigos devem ser lidos como historico, nao como estado operativo da sprint atual.
3. Ordem oficial atual:
   - `plano-sprint-health-regen-datadriven-v1-2026-05-11.md` esta fechado;
   - `plano-sprint-actor8dir-facade-slimming-v1-2026-05-11.md` esta em fechamento parcial congelado;
   - `plano-sprint-actor-export-profile-organization-v1-2026-05-11.md` esta ativa.
4. A organizacao de exports/perfis deve iniciar por auditoria e profile social/wander com fallback; nao migrar dados de cena sem QA visual.
5. A limpeza de exports sociais/wander/emote deve seguir E0/E1/E2/E3:
   - E0: auditar cobertura e classificar fallback real, override aprovado e tuning fantasma; concluida em 2026-05-11;
   - E1: limpar somente overrides antigos de entidades ja migradas; concluida em 2026-05-11;
   - E2: decidir Player/restantes com profile proprio, profile default ou fallback tecnico;
   - E3: remover exports do actor somente com cobertura total comprovada.

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
