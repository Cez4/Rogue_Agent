# Estudo de Saude do Projeto (Godot + LimboAI)

Data: 2026-05-09  
Escopo: diretrizes para manter arquitetura saudavel durante producao de novos inimigos e tuning data-driven.

## Objetivo
Consolidar regras tecnicas de manutencao para evitar regressao estrutural enquanto expandimos conteudo (hostis, armas, skills, status).

## Diagnostico atual (resumo)
1. Arquitetura base esta correta para escalar:
- BT decide, HSM executa, motor locomove.
- Configuracao de combate em dados (.tres).
- Telemetria de combate e de decisao BT ativa.

2. Risco principal agora:
- Drift de logica por variacao em script ao criar novos inimigos.
- Hardcode de tuning fora de profiles/actions/stats.

3. Decisao tecnica:
- Variacao de comportamento deve ser por dados (archetype/weapon/stats), nao por duplicacao de codigo.

## Guardrails de saude (obrigatorios)
1. Um ciclo por eixo de tuning:
- Targeting -> Approach/Stop -> Cadence -> Survivability.

2. Gate MCP por ciclo:
- `open_scene` -> `play_scene` -> `get_godot_errors` -> leitura de telemetria.

3. Sem alteracao de arquitetura durante tuning:
- Nao mudar contrato BT/HSM.
- Nao inserir logica nova em tasks para resolver balanceamento.

4. Evidencia obrigatoria por mudanca:
- Fonte oficial consultada.
- Teste funcional.
- Telemetria comprovando resultado.

## Referencias oficiais usadas
Godot:
- https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html
- https://docs.godotengine.org/en/4.1/classes/class_navigationagent2d.html

LimboAI:
- https://limboai.readthedocs.io/en/latest/classes/class_behaviortree.html
- https://limboai.readthedocs.io/en/latest/behavior-trees/using-blackboard.html

## Proximo passo recomendado
1. Seguir tuning v1 do Light com ciclos curtos e registro no `combat-tuning-matrix-v1.md`.
2. Repetir o protocolo no Brute e Wildcat sem alterar logica central.
3. Manter telemetria sempre ON em ambiente de debug.
