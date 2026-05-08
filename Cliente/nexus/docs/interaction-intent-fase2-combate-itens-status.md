# Interaction Intent Fase 2 - Combate + Itens (Status)

Data: 2026-05-08  
Branch: `feat/interaction-intent-fase2`

## Objetivo desta entrega
- Corrigir comportamento mouse-only de intents (cancelar chase, trocar target, parar empurrar em interacao).
- Preparar base data-driven de itens/equipamentos (arma, armadura, colar) com adaga inicial.

## Ajustes de comportamento
1. Cancelamento de chase combat
- Clique no chao (`move`) cancela intents ativos (`cancel_all_intents`) e inicia walk normal.
- Clique em alvo social (`inspect`/`context_menu`) cancela chase combat antes da acao social.
- Troca de alvo hostil atualiza `combat_target`.

2. Chase + attack com saida segura
- `actor_8dir_limbo.gd` agora:
  - para chase se target invalido;
  - para chase se target morreu (`Health.is_alive() == false`);
  - usa range de ataque data-driven da arma equipada.

3. Aproximacao social sem empurrar
- Novo fluxo de `interaction_target`:
  - `set_interaction_target(target, stop_range)`;
  - move ate um range de parada;
  - para e limpa intent ao entrar no range.
- Resolve o problema de "grudar empurrando NPC amigo".

4. Menu contextual
- `PopupMenu` mantido somente no player local.
- Opcoes atuais:
  - `Inspect`
  - `Talk` (para NPC/friendly)
  - `Attack` / `Chase + Attack` (para hostile)

## Base de itens/equipamentos
Scripts novos:
- `Scripts/items/item_data.gd`
- `Scripts/items/equipment_data.gd`
- `Scripts/items/weapon_data.gd`
- `Scripts/items/armor_data.gd`
- `Scripts/items/necklace_data.gd`
- `Scripts/items/equipment_loadout.gd`

Recursos novos:
- `configs/items/weapons/dagger_starter.tres`
- `configs/items/armors/cloth_starter.tres`
- `configs/items/necklaces/wooden_charm_starter.tres`
- `configs/items/loadouts/player_starter_loadout.tres`

Integracao:
- `actor_8dir_limbo.gd` carrega automaticamente o loadout inicial do player quando vazio.
- Range de chase/ataque passa a vir da arma equipada (`weapon.attack_range`).
- `state_attack_8dir.gd` passa a usar `weapon.action_data` quando disponivel.

## Validacao MCP
- Teste executado via Godot MCP:
  - abrir cena principal
  - play main
  - checar logs/runtime (`get_godot_errors`)
  - checar arvore da cena (`get_scene_tree`)
- Resultado: sem parser/runtime error na sessao.

## Proximos passos recomendados
1. Conectar evento de `Health.death` para animacao de morte + remocao/disable do collider.
2. Adicionar comando explicito "Stop" no contexto (opcional UX).
3. Migrar intents para command bus replicavel em multiplayer (cliente envia intencao, host valida e simula).
