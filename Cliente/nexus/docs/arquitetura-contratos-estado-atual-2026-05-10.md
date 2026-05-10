# Arquitetura e Contratos - Estado Atual

Data: 2026-05-10  
Escopo: consolidacao tecnica do estado real do projeto (cliente Godot + LimboAI)

## 1) Visao de alto nivel
Arquitetura operacional atual:
1. `InteractionResolver` interpreta intencao por contexto (mouse-first).
2. BT (LimboAI) decide comportamento.
3. HSM (LimboHSM) executa estados/animacao.
4. Motor (PlayerMotor/NavigationAgent2D) locomove.
5. Componentes de combate aplicam dano/vida/stamina.

Regra de ouro:
1. BT decide **o que** fazer.
2. HSM executa **como** fazer.
3. Motor apenas move.
4. Tuning por dados (`.tres`), nao por script.

## 2) Contratos principais (API e responsabilidade)

### 2.1 Actor base
Arquivo: `Scripts/actors/actor_8dir_limbo.gd`

Contrato publico (gameplay):
1. `request_attack()`
2. `set_combat_target(target, manual_lock)`
3. `clear_combat_target()`
4. `cancel_chase_attack(reason)`
5. `stop_motor_movement()`
6. `get_combat_target()`
7. `is_combat_target_manual_lock()`

Contrato tecnico (bridge/runtimes):
1. metodos `_bridge_*` para integracao interna.
2. nao usar `_bridge_*` em gameplay externo (task/controller).

### 2.2 Resolver de intencao
Arquivo: `Scripts/interaction/interaction_resolver.gd`

Contrato de entrada:
1. `resolve_primary(actor, click_position)`
2. `resolve_secondary(actor, click_position)`

Contrato de saida (Dictionary):
1. `intent`
2. `target`
3. `position`

Intents em uso:
1. `move`
2. `inspect`
3. `chase_attack`
4. `none`

### 2.3 Combate por componentes
Arquivos:
1. `Scripts/combat/health_component.gd`
2. `Scripts/combat/hurtbox_component.gd`
3. `Scripts/combat/hitbox_component.gd`
4. `Scripts/combat/combat_action_data.gd`
5. `Scripts/stats/stamina_component.gd`

Contrato de ataque:
1. `CombatActionData` define `attack_range`, janelas (`windup/active/recover/cooldown`), `stamina_cost`, `damage`.
2. Estado de ataque consome stamina no `_enter()` (nao no request).
3. Hit/hurt aplica dano e telemetria.

### 2.4 Telemetria
Arquivo: `Scripts/combat/combat_telemetry.gd`

Contratos/eventos-chave:
1. Combate: `target_acquired`, `attack_started`, `attack_commit`, `hit_confirmed`, `target_died`, `respawned`.
2. Stamina: `stamina_consumed`, `stamina_exhausted`, `stamina_recovered`, `orb_stamina_react`, `orb_stamina_exhausted_pulse`.
3. Controle: dedupe para `reacquire` e `attack_blocked_reason`.

## 3) Decisoes tecnicas congeladas
1. Input contextual mouse-first via resolver central.
2. Desacoplamento do actor em runtimes + bridge.
3. UI orb stamina com perfil visual global unico.
4. Diferenca de archetype por dados de combate (`stamina_cost`, cadence), nao por logica de orb.
5. Fluxo de QA obrigatorio com MCP:
   - `open_scene -> play_scene -> get_godot_errors`.

## 4) Baselines de combate ativos (v1)
Hostis validados:
1. `HostileEnemyLight`
2. `Wildcat`
3. `HostileEnemyBrute`

Stamina v1 fechada:
1. Light: `stamina_cost=14` (`spent_ratio=0.14`)
2. Wildcat: `stamina_cost=20` (`spent_ratio=0.20`)
3. Brute: `stamina_cost=28` (`spent_ratio=0.28`)

## 5) Exemplos prontos (fonte da verdade)

### 5.1 Orb stamina data-driven
1. Script de perfil: `Scripts/ui/orb/orb_resource_profile.gd`
2. Preset oficial: `configs/ui/orbs/stamina_orb_profile_v1.tres`
3. Presenter: `Scripts/ui/orb/combat_orb_presenter.gd`

### 5.2 Hostil data-driven (sem script dedicado)
1. Cenas:
   - `cenas/enemies/hostile_enemy_light.tscn`
   - `cenas/enemies/hostile_enemy_brute.tscn`
2. Profiles:
   - `configs/combat/profiles/hostile_light_profile_v1.tres`
   - `configs/combat/profiles/hostile_brute_profile_v1.tres`
3. Actions:
   - `configs/combat/hostile_light_attack_v1.tres`
   - `configs/combat/hostile_brute_attack_v1.tres`

### 5.3 Player/NPC com mesmo core
1. Actor compartilhado: `Scripts/actors/actor_8dir_limbo.gd`
2. BT player: `ai/trees/player/player_combat_bt.tres`
3. BT NPC base: `ai/trees/npc/wildcat_look_wander_bt.tres`

## 6) Riscos tecnicos e guardrails
Riscos:
1. drift por override acidental em cena (`mundo.tscn`).
2. tuning hardcoded em script/task.
3. uso de API bridge fora da camada tecnica.

Guardrails:
1. manter tuning em `.tres`.
2. atualizar docs de freeze + matriz ao mudar baseline.
3. commit pequeno por ciclo e status limpo antes de push.

## 7) Proximo passo recomendado (apos consolidacao)
1. Produzir novo hostil usando `enemy-profile-checklist-v1.md` (sem alterar logica).
2. Manter baseline stamina v1 e validar apenas por telemetria.
3. Evoluir observabilidade (dash/debug), sem mexer em contrato de gameplay.

## 8) Referencias
1. Status oficial: `status-freeze-funcional-v2-2026-05-10.md`
2. Matriz de tuning: `combat-tuning-matrix-v1.md`
3. Auditoria BT/HSM: `auditoria-estado-atual-bt-hsm-combate.md`
4. LimboAI docs: https://limboai.readthedocs.io/en/latest/
5. Godot Navigation guide: https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html
