# Plano Sprint - Health Regen Data-Driven v1

Data: 2026-05-11
Status: PLANEJADA
Versao: v1
Escopo: criar regeneracao passiva de vida fora de combate, modular e data-driven, compartilhada por Player, NPCs e inimigos.

## 1) Objetivo
Implementar um sistema modular de regeneracao de vida por segundo fora de combate.

Regra de design inicial:

1. Fora de combate: regenera `3 HP/s`.
2. Em combate: nao regenera.
3. Morto: nao regenera.
4. Orb de vida deve refletir cura de forma visualmente rica, preservando liquido/trail/slosh.
5. A regra deve ser data-driven e reutilizavel em qualquer entidade com `HealthComponent`.

## 2) Principio tecnico
O sistema deve seguir o padrao atual do projeto:

1. Componente pequeno por responsabilidade.
2. Dados em `.tres`/exports, nao hardcode em script.
3. Sem logica global monolitica.
4. Sem regra duplicada entre UI, actor e regen.
5. Compatibilidade futura com server-authoritative MMO.

## 3) Diagnostico do estado atual
Hoje o estado "em combate" e inferido em `CombatOrbPresenter`:

1. ator tem `combat_target` valido;
2. ou algum hostile esta mirando o ator.

Essa regra funciona para UI, mas nao deve ser duplicada no novo regen. Antes do regen, a regra precisa virar contrato central reutilizavel.

## 4) Decisao arquitetural
Criar uma fonte unica para saber se um ator esta em combate.

Opcao recomendada:

```gdscript
ActorCombatRuntime.is_actor_in_combat(actor: Actor8DirLimbo) -> bool
```

Consumidores:

1. `CombatOrbPresenter`
2. `HealthRegenComponent`
3. futuros sistemas de descanso, stealth, aggro decay e UI de combate

## 5) Fora de escopo
1. Nao criar sistema server-authoritative nesta sprint.
2. Nao alterar BT/HSM de combate.
3. Nao alterar stamina.
4. Nao alterar dano/hitbox/hurtbox, exceto se necessario para signal de vida.
5. Nao criar singleton global para aplicar regen em todos os atores.
6. Nao mexer no feel congelado de kiting.

## 6) Arquivos provaveis
Scripts:
1. `Scripts/actors/services/actor_combat_runtime.gd`
2. `Scripts/combat/health_component.gd`
3. `Scripts/combat/health_regen_component.gd` (novo)
4. `Scripts/ui/orb/combat_orb_presenter.gd`

Cena/componente:
1. `cenas/components/combat/health_regen_component_node.tscn` (novo, se o projeto mantiver padrao de cenas de componentes)
2. `cenas/player.tscn`
3. `cenas/wildcat_1.tscn`
4. `cenas/enemies/hostile_enemy_base.tscn`
5. `cenas/enemies/hostile_enemy_light.tscn`
6. `cenas/enemies/hostile_enemy_brute.tscn`

Dados:
1. `configs/combat/regen/default_health_regen_v1.tres` (novo, se for criado Resource dedicado)

Docs:
1. `combat-tuning-matrix-v1.md`
2. `status-freeze-total-combate-tatico-2026-05-11.md`, se o baseline funcional mudar

## 7) Componentes propostos
### 7.1 HealthComponent
Adicionar API minima:

```gdscript
signal health_changed(current: float, max_health: float)
signal healed(amount: float)

func heal(amount: float) -> void
func get_health_ratio() -> float
```

Regras:
1. `heal()` nunca passa de `max_health`.
2. `heal()` nao revive entidade morta nesta sprint.
3. `take_damage()` tambem deve emitir `health_changed`.
4. `reset_health()` deve emitir `health_changed` e preservar snap visual da Orb.

### 7.2 HealthRegenComponent
Componente por entidade.

Exports sugeridos:

```gdscript
@export var enabled: bool = true
@export var health_component_path: NodePath = ^"../Health"
@export var regen_per_sec: float = 3.0
@export var out_of_combat_delay_sec: float = 2.0
@export var tick_interval_sec: float = 0.2
@export var regen_when_dead: bool = false
```

Responsabilidade:
1. localizar `HealthComponent`;
2. localizar owner como `Actor8DirLimbo`;
3. consultar `ActorCombatRuntime.is_actor_in_combat(actor)`;
4. acumular tempo fora de combate;
5. aplicar heal em ticks controlados.

Nao pode:
1. decidir alvo;
2. limpar target;
3. alterar BT/HSM;
4. mexer em Orb diretamente.

### 7.3 CombatOrbPresenter
Atualizar para reagir a cura:

1. conectar `HealthComponent.healed`;
2. aplicar slosh/energia de cura com intensidade menor que dano;
3. manter snap de trail para ganho de vida instantaneo;
4. emitir telemetria opcional `orb_health_heal_react`.

## 8) Plano de execucao
### Fase A - Contrato de combate
- [ ] Extrair regra de combate para `ActorCombatRuntime.is_actor_in_combat(actor)`.
- [ ] Atualizar `CombatOrbPresenter` para usar esse contrato.
- [ ] Validar que comportamento visual da Orb nao mudou.

### Fase B - HealthComponent
- [ ] Adicionar `health_changed`.
- [ ] Adicionar `healed`.
- [ ] Adicionar `heal(amount)`.
- [ ] Adicionar `get_health_ratio()`.
- [ ] Garantir que `take_damage()` e `reset_health()` emitem `health_changed`.
- [ ] Nao permitir revive por heal nesta sprint.

### Fase C - HealthRegenComponent
- [ ] Criar componente modular.
- [ ] Usar `regen_per_sec = 3.0`.
- [ ] Regenerar somente fora de combate.
- [ ] Respeitar delay fora de combate.
- [ ] Usar tick interval para evitar processamento ruidoso.
- [ ] Emitir telemetria `health_regen_tick`.

### Fase D - Integracao em cenas
- [ ] Adicionar componente ao Player.
- [ ] Adicionar componente ao Wildcat.
- [ ] Adicionar componente ao Hostile Base.
- [ ] Adicionar componente ao Hostile Light.
- [ ] Adicionar componente ao Hostile Brute.
- [ ] Conferir overrides em `mundo.tscn`.

### Fase E - Orb de vida
- [ ] Orb reage a `healed`.
- [ ] HP subindo nao deixa trail visual atrasado para baixo.
- [ ] Liquido/slosh exibe cura sem parecer dano.
- [ ] Orb continua visivel conforme regra de combate atual.

### Fase F - Validacao MCP
- [ ] `open_scene(res://cenas/mundo.tscn)`.
- [ ] `play_scene(current)`.
- [ ] Tomar dano.
- [ ] Sair de combate.
- [ ] Confirmar regen depois do delay.
- [ ] Confirmar sem regen durante combate.
- [ ] Confirmar sem regen quando morto.
- [ ] `get_godot_errors` sem erro novo.

### Fase G - Telemetria
- [ ] `health_regen_tick` aparece fora de combate.
- [ ] `health_changed` reflete dano/cura.
- [ ] `orb_health_heal_react` aparece quando a Orb reage a cura.
- [ ] Combate continua emitindo `target_acquired`, `target_lost`, `attack_commit`, `hit_confirmed`.
- [ ] Sem spam excessivo no log.

### Fase H - Documentacao e Git
- [ ] Atualizar `combat-tuning-matrix-v1.md`.
- [ ] Atualizar freeze/status se o comportamento for aprovado.
- [ ] Commit pequeno e claro.
- [ ] Push e sync confirmado com `rev-list --left-right --count`.

## 9) Criterios de aceite
- [ ] Player regenera fora de combate.
- [ ] NPC amigavel regenera fora de combate.
- [ ] Inimigo regenera fora de combate.
- [ ] Ninguem regenera durante combate.
- [ ] Ninguem revive por regen.
- [ ] Valor base `3 HP/s` e configuravel por dados/export.
- [ ] Orb de vida exibe cura com feedback visual agradavel.
- [ ] Regra de "em combate" nao esta duplicada na UI e no regen.
- [ ] Sem alteracao de BT/HSM.
- [ ] Sem erro novo no Godot.

## 10) Riscos e mitigacoes
Risco: regen iniciar cedo demais enquanto ator ainda esta em combate.
Mitigacao: usar `ActorCombatRuntime.is_actor_in_combat()` + `out_of_combat_delay_sec`.

Risco: duplicar regra de combate em varios scripts.
Mitigacao: centralizar contrato antes de criar regen.

Risco: Orb parecer dano ao curar.
Mitigacao: usar intensidade/cor/energia de cura separada, sem shake agressivo.

Risco: multiplayer futuro ter divergencia cliente/servidor.
Mitigacao: tratar esta sprint como apresentacao/prototipo local; documentar que server deve validar regen oficial.

## 11) Notas MMO/server-authoritative
No futuro, regen deve ser validada pelo servidor:

1. servidor decide se entidade esta fora de combate;
2. servidor aplica heal por tick;
3. cliente recebe estado autoritativo;
4. Orb apenas apresenta transicao visual.

## 12) Tick final da sprint
- [ ] Sprint concluida
- [ ] QA aprovou feel visual da Orb de cura
- [ ] Commit/push sincronizado
- [ ] Freeze atualizado se necessario
