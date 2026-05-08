# Interaction Intent Fase 2 - Combate + Itens (Status)

Data: 2026-05-08  
Branch base historica: `feat/interaction-intent-fase2`  
Estado atual consolidado: `feat/combat-intent-fase4`

## Objetivo desta entrega
- Corrigir comportamento mouse-only de intents (cancelar chase, trocar target, parar empurrar em interacao).
- Preparar base data-driven de itens/equipamentos (arma, armadura, colar) com adaga inicial.

## Ajustes de comportamento (estado atual)
1. Cancelamento de chase combat
- Clique no chao (`move`) cancela intents ativos (`cancel_all_intents`) e inicia walk normal.
- Clique em alvo social (`inspect`) cancela chase combat antes da acao social.
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

4. Regra de input vigente (mouse-only)
- Clique esquerdo em chao: `move`.
- Clique esquerdo em `hostile`: `none` (nao ataca e nao inicia chase).
- Clique secundario em `hostile`: `chase_attack`.
- Clique secundario em chao ou alvos nao-hostis: `none`.

5. Migracao BT-first no player (LimboAI)
- `player.tscn` com `use_bt_brain = true`.
- `BTPlayer` do player ativo com `player_combat_bt.tres`.
- HSM permanece como executor de animacao/ataque.
- Loop manual de chase no actor fica desativado quando `use_bt_brain = true` (evita dupla autoridade BT+manual).

6. Correcao de travamento/deslize no chase
- `bt_chase_combat_target.gd` deixa de forcar `set_combat_target()` em loop (isso forçava idle via `face_toward`).
- Chase task passa a:
  - `request_move` no motor;
  - tocar walk via `play_walk_toward(target)`;
  - retornar `SUCCESS` ao entrar no range de ataque.
- Sequencia de ataque BT reordenada para:
  - `Pull -> Validate -> InRange -> Face -> Attack`.

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
1. Telemetria de BT por evento de decisao (task enter/exit, status, alvo).
2. Aplicar o mesmo padrao BT-first de combate para NPCs hostis futuros (minions/bosses) com blackboard padrao.
3. Migrar intents para command bus replicavel em multiplayer (cliente envia intencao, host valida e simula).
