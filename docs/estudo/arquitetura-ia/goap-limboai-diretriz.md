# Arquitetura de IA - GOAP + LimboAI (Projeto)

Este documento define a arquitetura oficial de IA para o projeto.

## Decisao central

- GOAP faz o agente "viver" (rotina e objetivos de longo prazo).
- LimboAI faz entidades "agirem bem" em combate e eventos de curta latencia.

## Responsabilidades por sistema

### GOAP (macro planeamento)

Usar para:
- Rotina de agent (agenda/vida)
- Fome, sono e necessidades
- Cozinhar, ler, guardar item, craft
- Escolha de objetivo de longo prazo

Nao usar GOAP para:
- Execucao frame-a-frame de combate rapido
- Controle tatico detalhado de boss em fase ativa

### LimboAI (micro decisao + execucao comportamental)

Usar para:
- Combate
- Fases de boss
- Inimigos comuns
- Minions
- Companions
- Reacoes rapidas
- Patrulha
- Fuga
- Ataque
- Defesa
- Invocacao
- Troca de estado

## Por que LimboAI para bosses

Boss precisa de comportamento:
- Previsivel
- Editavel
- Visual

Combinacao recomendada:
- HSM (LimboHSM/LimboState) para fases e macroestado
- Behavior Tree para decisao tatico-operacional
- Blackboard para contexto de runtime

Exemplo de fluxo:
- Fase 1: ataque basico, movimentacao para alvo, skill simples
- HP < 50%: transicao para Fase 2
- Fase 2: invocar minions, ataque especial, projeteis, reposicionamento/fuga

## Blackboard (memoria de trabalho)

Exemplo de variaveis:
- target_player
- hp_percent
- boss_phase
- minions_alive
- skill_cooldown_ready
- danger_position
- last_attack

Exemplo de decisoes:
- Se hp_percent < 50 -> mudar fase
- Se minions_alive < 2 -> invocar minions
- Se target_player longe -> ataque ranged
- Se target_player perto -> ataque melee

## Encaixe com plugins/sistemas

- LimboAI: decide o que entidade faz
- GEQO: ajuda a escolher alvo/posicao/cobertura
- BlastBullets2D: executa projeteis e padroes de tiro
- Spawner Plugin: instancia inimigos/minions
- Quest Manager: escuta morte de boss/progresso
- Orchestrator: eventos, cutscene, UI

## Regra de multiplayer (obrigatoria)

Host/Servidor:
- Roda IA oficial (LimboAI/GOAP autoritativo)
- Decide estado oficial de NPC/Boss

Clients:
- Recebem estado replicado
- Exibem animacao e feedback

Regra critica:
- Nao executar IA oficial completa em todos os clients para evitar dessincronizacao.

## Escopo: onde nao usar LimboAI como sistema principal

Nao usar LimboAI como core para:
- Inventario
- Save
- Quests
- Camada de rede
- Persistencia de simulacao de vida de longo prazo

## Modelo hibrido recomendado

- GOAP escolhe objetivo macro (ex.: cozinhar, descansar, buscar recurso).
- LimboAI executa comportamento contextual de curta janela (ex.: autodefesa, fuga, combate).

## Resumo executivo

- GOAP: vida, rotina e planejamento de longo prazo.
- LimboAI: combate, bosses, inimigos, minions e companions.
- Multiplayer: host autoritativo, clients apenas visualizacao e sincronizacao.

Esta decisao e oficial para orientar implementacoes futuras de IA no projeto.
