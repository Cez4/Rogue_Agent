# Interaction Intent - Fase 1 (Status)

Data: 2026-05-08  
Branch: `feat/interaction-intent-fase1`

## Entrega desta fase
- Input migrado para intencao contextual:
  - `interact_primary`
  - `interact_secondary`
- Novo resolvedor central de intencao.
- Fluxo antigo preservado como fallback de transicao (`move_click`).

## O que foi implementado
1. `Scripts/interaction/interaction_resolver.gd`
- Resolve intencao primaria:
  - sem alvo -> `move`
  - alvo no grupo `hostile` -> `attack`
  - alvo `npc`/`friendly` -> `inspect`
- Resolve intencao secundaria:
  - com alvo -> `context_menu`
  - sem alvo -> `move`
- Faz picking no ponto de clique com `intersect_point`.

2. `Scripts/player/player_controller.gd`
- Passou a usar `interact_primary` e `interact_secondary`.
- Converte intencao em comando local:
  - `move` -> `request_move`
  - `attack` -> `request_attack`
  - `inspect/context_menu` -> log de intencao (placeholder de UI)

3. `Scripts/actors/actor_8dir_limbo.gd`
- Removeu trigger direto de ataque por action fixa no actor.
- Input do player agora passa pelo controller/resolver.

## Como testar
1. Clique em chao vazio com botao principal:
- esperado: player move.
2. Clique principal em alvo com grupo `hostile`:
- esperado: player ataca.
3. Clique secundario em NPC/objeto:
- esperado: log `[INTENT] context_menu -> ...` (placeholder).

## Observacoes de arquitetura
- Esta fase abre o caminho para:
  - menu contextual real (`PopupMenu`) no secundario;
  - comandos de dominio replicaveis para multiplayer;
  - chase-and-attack com lock de alvo via BT/HSM.
- Proximo passo tecnico: substituir logs por Command Bus + UI de contexto.
