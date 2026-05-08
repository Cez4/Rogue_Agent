# Padrão Oficial de NPCs com LimboAI

## Objetivo
Todos os NPCs devem usar LimboAI como cérebro principal de comportamento, com arquitetura modular, data-driven e pronta para multiplayer.

## Princípios
1. LimboAI como núcleo de decisão.
2. Estados pequenos e reutilizáveis.
3. Dados de comportamento em parâmetros/export/resources (não hardcode).
4. Separação clara:
- Decisão: LimboAI (HSM/BT/Blackboard)
- Movimento: motor de movimento
- Visual: animações/sprite
- Rede: camada autoritativa (host/servidor)

## Baseline obrigatório para NPC comum
### HSM mínimo (MVP)
- `IdleState`
- `WanderState`
- `LookAtPlayerState` (opcional no início, recomendado)

Fluxo:
- `Idle -> Wander -> Idle`
- Se player entrar em raio de interesse: `Idle/Wander -> LookAtPlayer -> Idle`

## Quando usar BT (Behavior Tree)
Use BT quando o NPC tiver múltiplas decisões concorrentes:
- prioridade entre patrulha/reação/interação/fuga
- condições mais ricas (hora do dia, perigo, objetivo)

Estrutura típica:
- `Selector`
- `Sequence` por comportamento
- leitura/escrita no `Blackboard`

## Blackboard padrão (base)
Campos sugeridos:
- `target_player`
- `interest_point`
- `home_position`
- `state_timer`
- `threat_level`
- `is_busy`

## Diretriz de escalabilidade
1. Criar estados genéricos reutilizáveis (`state_idle_8dir`, `state_wander_8dir`, etc.).
2. Configurar variações por NPC só por dados:
- tempos de idle
- raio de wander
- velocidade
- raio de percepção
3. Evitar duplicar script por tipo de NPC sem necessidade.

## Diretriz multiplayer (coop autoritativo)
- Host/servidor roda a IA oficial.
- Cliente apenas renderiza resultado replicado.
- Cliente não decide estado final do NPC.

## Padrão de colisão e navegação para NPCs
- `NavigationAgent2D` com avoidance ativo.
- Personagens em `collision_layer` de personagem e máscara focada em cenário.
- Evitar bloqueio físico entre NPCs; usar avoidance para desvio.

## Roadmap de evolução de NPCs
1. MVP: `Idle + Wander`
2. Reação: `LookAtPlayer`
3. Interação: diálogo simples/contextual
4. Rotina mais rica: BT + Blackboard expandido
5. Integração futura com GOAP para vida cotidiana

## Regra do projeto
Novo NPC deve nascer já nesse padrão LimboAI.
Se houver exceção, documentar motivo técnico.

