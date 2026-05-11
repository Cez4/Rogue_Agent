# Plano Sprint - Port Tatico Limbo Demo v1

Data: 2026-05-10  
Status: FECHADA PELO FREEZE TOTAL DE 2026-05-11  
Objetivo: portar o padrao tatico da demo LimboAI para resolver travamento de chase/kite sem inflar arquitetura.

## Encerramento
Esta sprint foi encerrada pelo documento:

`status-freeze-total-combate-tatico-2026-05-11.md`

O comportamento atual foi aprovado pelo QA:

1. spam de clique de ataque nao interrompe o kiting automatico;
2. clique no chao cancela combate e permite fuga manual;
3. baixa stamina usa custo real do ataque equipado;
4. Player e NPCs executam reposicionamento tatico de forma aceitavel;
5. ajustes locais de NavMesh, stamina regen e walk sem loop fazem parte do baseline atual.

## Estado atual da sprint (atualizado)
1. Chase/attack de Player e Brute estao funcionais com ciclo completo.
2. Falso positivo de `request_attack_not_started` foi removido.
3. Telemetria de sucesso recebeu dedupe por `actor+target+status+reason`.
4. Pendente: acabamento de fluidez tatico (reposition/hold) e limpeza final de ruído residual.

## 1) Problema atual (confirmado por logs)
1. Loop de reposicionamento em baixa stamina (`force_separation`) entre player e hostil.
2. Alternancia excessiva `hold/reposition` sem commit de chegada.
3. Sensacao de travar na animacao de walk (na pratica: BT preso em RUNNING tatico).
4. Casos de hostil sem ataque por starvation do ramo tatico.

## 2) Decisao tecnica da sprint
1. Nao inventar logica nova agora.
2. Portar padroes da demo como base:
   - `arrive_pos`
   - `back_away`
   - `pursue`
   - `in_range`
3. Adaptar para contrato atual `Actor8DirLimbo` (sem monolito).
4. BT continua cerebro; HSM continua execucao.

## 3) Escopo (phase-gate)
1. Phase A - Port seguro de tasks taticas
   - criar versoes de tasks inspiradas no demo, pequenas e reutilizaveis.
   - sem mover logica para `actor_8dir_limbo.gd`.
2. Phase B - Troca controlada de arvore
   - ativar novo ramo tatico na BT.
   - manter legado temporario fora da arvore ativa.
3. Phase C - Validacao MCP + telemetria
   - `open_scene -> play_scene -> get_godot_errors`.
   - cenarios: melee colado, kite com clique no chao, reacquire, reengage.
4. Phase D - Remocao legado
   - remover task antiga de low stamina so apos regressao passar.

## 4) Regras obrigatorias da sprint
1. Nenhum commit sem teste MCP.
2. Nenhuma remocao de legado antes da nova arvore ficar estavel.
3. Sem hardcode de tuning em script/task.
4. Tuning somente via `.tres`/blackboard plan.
5. Telemetria deve continuar legivel (dedupe/throttle).

## 5) Criterios de pronto
1. Sem loop infinito de `force_separation`.
2. Reposicionamento com commit (anda ate posicao alvo antes de reavaliar).
3. Hostil volta a atacar apos janela tatico/stamina.
4. Sem travamento visual de walk por starvation do BT.
5. Zero erro novo em `get_godot_errors`.
6. Telemetria de combate legivel sem spam critico de sucesso/bloqueio.

## 6) Fora de escopo nesta sprint
1. Refactor grande de arquitetura.
2. Novos sistemas de skill/magia.
3. Multiplayer/server-authoritative.

## 7) Referencias
1. `docs/referencias/limboai-demo/limboai-demo-combate-referencia.md`
2. LimboAI BT intro:
   - https://limboai.readthedocs.io/en/stable/behavior-trees/introduction.html
3. LimboAI custom tasks:
   - https://limboai.readthedocs.io/en/v1.4.1/behavior-trees/custom-tasks.html
4. LimboAI Blackboard:
   - https://limboai.readthedocs.io/en/stable/behavior-trees/using-blackboard.html
