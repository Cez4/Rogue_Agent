# Docs - Mapa Oficial (Estado Atual)

Data de consolidacao: 2026-05-10
Branch de referencia: `feat/combat-orb-ui-contextual`

## 1) Fonte principal de estado
1. `status-freeze-total-combate-tatico-2026-05-11.md` (freeze total aprovado)
2. `recomendacoes-techlead-pos-freeze-2026-05-11.md` (proximos passos recomendados)
3. `status-freeze-funcional-v3-limbo-modular-2026-05-11.md` (arquitetura modular LimboAI)
4. `status-freeze-funcional-v2-2026-05-10.md` (baseline historico Orb/Stamina)
5. `plano-sprint-port-limbo-demo-tatico-v1-2026-05-10.md` (sprint tatico fechada pelo freeze)
6. `mvp-limboai-combate-wander-status.md` (historico consolidado + links atuais)

## 1.1 Regra anti-drift (obrigatoria)
1. Quando houver conflito entre docs antigos e estado atual:
   - o freeze total de 2026-05-11 vence;
   - os freezes anteriores viram historico tecnico.
2. Docs de tuning/congelamento antigos devem ser lidos como historico, nao como estado operativo da sprint atual.

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
   - fechar Git/docs do baseline;
   - so depois retomar novas features.
5. Sempre que ajustar BT/tarefas taticas, atualizar no mesmo PR:
   - `status-freeze-total-combate-tatico-2026-05-11.md` (estado funcional real),
   - `plano-sprint-port-limbo-demo-tatico-v1-2026-05-10.md` (progresso de sprint).
