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
  - alvo `hostile` -> `chase_attack` (lock + perseguir/atacar)
  - outros alvos -> `context_menu`
  - sem alvo -> `move`
- Faz picking no ponto de clique com `intersect_point`.

2. `Scripts/player/player_controller.gd`
- Passou a usar `interact_primary` e `interact_secondary`.
- Converte intencao em comando local:
  - `move` -> `request_move`
  - `attack` -> `request_attack`
  - `chase_attack` -> `set_combat_target`
  - `inspect` -> log (placeholder)
  - `context_menu` -> `PopupMenu` real com acoes contextuais

3. `Scripts/actors/actor_8dir_limbo.gd`
- Removeu trigger direto de ataque por action fixa no actor.
- Input do player agora passa pelo controller/resolver.
- Adicionou `is_hostile` (grupo hostil via configuracao).
- Adicionou `set_combat_target` + loop de `chase_attack`:
  - fora de range: repath para alvo.
  - em range: para movimento e tenta ataque.

## Como testar
1. Clique em chao vazio com botao principal:
- esperado: player move.
2. Clique principal em alvo com grupo `hostile`:
- esperado: player ataca.
3. Clique secundario em inimigo (`hostile`):
- esperado: trava alvo e comeca `chase + attack`.
4. Clique secundario em NPC/objeto nao-hostil:
- esperado: abre menu contextual com `Inspect` (e opcoes hostis quando aplicavel).

## Observacoes de arquitetura
- Esta fase abre o caminho para:
  - comandos de dominio replicaveis para multiplayer;
  - menu contextual expandido por tipo de objeto;
  - comandos de dominio replicaveis para multiplayer;
  - chase-and-attack com lock de alvo via BT/HSM.
- Proximo passo tecnico: migrar `chase_attack` para task BT dedicada (player/NPC) e registrar telemetria de intencao.
