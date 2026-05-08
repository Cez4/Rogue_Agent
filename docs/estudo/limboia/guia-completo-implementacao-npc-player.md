# Guia Completo - Implementação Player/NPC com Godot + LimboAI

## 1) Objetivo
Este documento consolida, de forma técnica e didática, tudo que foi implementado no projeto para:
- movimento click-to-move;
- animação 8 direções;
- IA de NPC com LimboAI (HSM + BT);
- avoidance entre agentes;
- emotes contextuais (`Exc` e `Hoe`) dirigidos pela IA;
- redução de spam comportamental (distância, chance, cooldown, jitter).

O foco foi criar base **modular, data-driven, escalável e pronta para multiplayer coop autoritativo**.

---

## 2) Escopo funcional entregue

### 2.1 Player
- Move por clique com `NavigationAgent2D`.
- Toca animações de idle/walk/attack em 8 direções.
- Input de ataque protegido para não quebrar NPC.

### 2.2 Wildcat e Villager
- Ambos usam o mesmo ator base.
- Wildcat com `Idle/Wander`.
- Villager com BT:
  - detecta player em faixa de distância;
  - olha o player com cooldown;
  - vagueia quando não está no ramo de look.

### 2.3 Evitação e colisão
- Avoidance ativo (`set_velocity` + `velocity_computed`) no motor.
- Camadas/máscaras ajustadas para evitar “engavetamento”.

### 2.4 Emotes dirigidos pela IA
- `Exc` quando entra no ramo de look.
- `Hoe` ocasional no wander.
- `EmotionBubble` invisível por padrão e exibido só por evento da IA.

---

## 3) Arquitetura adotada

### 3.1 Separação de responsabilidades
- `actor_8dir_limbo.gd`: orquestra ator (animação, timers, hooks de IA, emotes).
- `player_motor.gd`: movimento e steering/avoidance.
- States HSM (`state_idle_8dir`, `state_walk_8dir`, `state_attack_8dir`, `state_wander_8dir`): execução por estado.
- Tasks BT (`bt_*`): decisões granulares para NPC.

### 3.2 Por que híbrido HSM + BT?
- HSM é ótimo para fluxo simples visual de estados.
- BT é melhor para decisões condicionais dinâmicas (look, chance, cooldown, prioridade).
- No Villager, o cérebro ativo está no BT (`BTPlayer`), mantendo HSM disponível para evolução.

---

## 4) Fluxo comportamental final do Villager

### 4.1 Árvore (alto nível)
`BTDynamicSelector`
1. Ramo Look:
   - Acquire target (`player`)
   - Check distance window (min/max)
   - `LookAtTarget` (para movimento, vira para player, toca `Exc`)
   - Decorado por `BTCooldown`
   - Decorado por `BTProbability`
2. Fallback:
   - `IdleWanderLoop` (idle/walk)
   - durante walk, chance de emote `Hoe` com cooldown independente

### 4.2 Anti-spam aplicado
- Look só quando NPC está parado.
- Janela curta de distância.
- Cooldown longo + jitter.
- Probabilidade no ramo.

---

## 5) Arquivos principais alterados/criados

### Core de ator/movimento
- `Cliente/nexus/Scripts/actors/actor_8dir_limbo.gd`
- `Cliente/nexus/Scripts/player/player_motor.gd`
- `Cliente/nexus/Scripts/player/player_movement_config.gd`

### States LimboAI
- `Cliente/nexus/Scripts/actors/state_idle_8dir.gd`
- `Cliente/nexus/Scripts/actors/state_walk_8dir.gd`
- `Cliente/nexus/Scripts/actors/state_attack_8dir.gd`
- `Cliente/nexus/Scripts/actors/state_wander_8dir.gd`

### BT Tasks
- `Cliente/nexus/Scripts/ai/tasks/bt_acquire_target_in_group.gd`
- `Cliente/nexus/Scripts/ai/tasks/bt_is_target_in_range.gd`
- `Cliente/nexus/Scripts/ai/tasks/bt_look_at_target.gd`
- `Cliente/nexus/Scripts/ai/tasks/bt_idle_wander_loop.gd`

### BT Resource
- `Cliente/nexus/ai/trees/npc/villager_look_wander_bt.tres`

### Cenas
- `Cliente/nexus/cenas/player.tscn`
- `Cliente/nexus/cenas/wildcat_1.tscn`
- `Cliente/nexus/cenas/villager_1.tscn`
- `Cliente/nexus/cenas/mundo.tscn`

---

## 6) Exemplos de código (com propósito)

### 6.1 Avoidance real no motor (evita travamento entre agentes)
```gdscript
# player_motor.gd
_navigation_agent.set_velocity(desired_velocity)
# recebe velocidade segura calculada pelo NavigationServer
_body.velocity = _body.velocity.move_toward(_safe_velocity, accel * delta)
_body.move_and_slide()
```
Para que serve:
- evita colisões dinâmicas entre agentes móveis;
- reduz impasse de `move_and_slide` quando dois corpos cruzam.

### 6.2 Filtro de look por distância + cooldown
```gdscript
# actor_8dir_limbo.gd
func can_look_target(target: Node2D) -> bool:
	if is_actor_moving():
		return false
	if Time.get_ticks_msec() * 0.001 < _next_look_allowed_sec:
		return false
	var dist_sq := global_position.distance_squared_to(target.global_position)
	return dist_sq >= min_dist * min_dist and dist_sq <= max_dist * max_dist
```
Para que serve:
- impede look contínuo;
- só permite reação em faixa desejada (“médio para perto”).

### 6.3 Cooldown com jitter (quebra padrão robótico)
```gdscript
func trigger_look_cooldown() -> void:
	var cooldown := look_cooldown_sec + randf_range(0.0, look_cooldown_jitter_sec)
	_next_look_allowed_sec = Time.get_ticks_msec() * 0.001 + cooldown
```
Para que serve:
- evita sincronização artificial e repetição previsível.

### 6.4 Emote contextual controlado pela IA
```gdscript
func play_look_emote() -> void:
	_show_emote(&"Exc", false, 1.3, 2) # prioridade alta

func try_play_wander_emote() -> void:
	if randf() <= wander_emote_chance:
		_show_emote(&"Hoe", true, wander_emote_hold_sec, 1)
```
Para que serve:
- só mostra balão quando comportamento pede;
- prioriza surpresa (`Exc`) acima do assovio (`Hoe`).

---

## 7) Configuração recomendada (Villager)

Valores atuais usados para reduzir spam:
- `look_interest_min_distance = 52.0`
- `look_interest_max_distance = 84.0`
- `look_cooldown_sec = 8.0`
- `look_cooldown_jitter_sec = 3.0`
- `wander_emote_chance = 0.2`
- `wander_emote_min_cooldown_sec = 8.0`
- `wander_emote_max_cooldown_sec = 14.0`

Observação:
- ajuste fino depende da escala visual do mapa/sprite;
- se ainda olhar demais, aumentar cooldown e reduzir probabilidade.

---

## 8) Boas práticas adotadas
- Data-driven via exports/resources.
- Reuso de base de ator para player/NPC.
- IA desacoplada do visual (IA decide “quando”, nó visual executa “como”).
- Evitação dinâmica para robustez de movimento.
- Preparação para host autoritativo em multiplayer.

---

## 9) Limitações atuais e próximos passos

### Limitações
- Emotes estão específicos no Villager (ainda não padronizado por recurso global).
- Blackboard ainda simples (sem compartilhamento por facção/grupo).

### Próximos passos
1. Extrair config de percepção/emote por `Resource` de tipo de NPC.
2. Aplicar mesmo padrão no Wildcat.
3. Adicionar `LookAtPlayerState` como fallback HSM para NPCs sem BT.
4. Iniciar integração de replicação autoritativa no host para IA.

---

## 10) Como validar (checklist)
1. Abrir `res://cenas/mundo.tscn`.
2. Dar play.
3. Verificar:
- player move por clique sem travar em NPC;
- villager vagueia;
- villager olha player apenas quando perto;
- `Exc` aparece no look;
- `Hoe` aparece ocasional no wander;
- sem spam contínuo.

---

## 11) Fontes oficiais

### Godot
- NavigationAgent2D:
  - https://docs.godotengine.org/en/stable/classes/class_navigationagent2d.html
- Using NavigationAgents:
  - https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html
- AnimatedSprite2D:
  - https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html
- Importing images:
  - https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html

### LimboAI
- Docs (index):
  - https://limboai.readthedocs.io/en/stable/
- LimboHSM:
  - https://limboai.readthedocs.io/en/stable/classes/class_limbohsm.html
- LimboState:
  - https://limboai.readthedocs.io/en/stable/classes/class_limbostate.html
- BTPlayer:
  - https://limboai.readthedocs.io/en/stable/classes/class_btplayer.html
- BTCooldown:
  - https://limboai.readthedocs.io/en/stable/classes/class_btcooldown.html
- BTProbability:
  - https://limboai.readthedocs.io/en/stable/classes/class_btprobability.html
- BTDynamicSelector:
  - https://limboai.readthedocs.io/en/stable/classes/class_btdynamicselector.html

---

## 12) Resumo executivo
Foi construída uma base funcional e escalável de gameplay/IA com Godot + LimboAI:
- movimento e animação 8-dir;
- NPC com decisão por BT;
- reações contextuais com emotes;
- anti-spam comportamental;
- documentação e padrão para evolução.

Estado atual: **funcional e validado em runtime**.

