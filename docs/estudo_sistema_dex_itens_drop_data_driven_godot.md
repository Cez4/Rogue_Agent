# Estudo técnico — Sistema simples de DEX, itens e drops data-driven em Godot

> Documento para orientar outro agente LLM na implementação de um sistema simples, modular e data-driven de itens com variação de status, começando por DEX e uma adaga.

---

## 1. Contexto do projeto

O jogo é um **RPG coop em Godot**, usando o multiplayer nativo do engine, com um jogador atuando como **host autoritativo**. O foco deste documento não é networking completo, nem backend externo, nem arquitetura MMO. O foco é apenas o núcleo de:

- atributo **DEX**;
- item base;
- item dropado com rolagem de atributos;
- dano variável;
- bônus de DEX vindo de item;
- monstro dropando item baseado no level dele.

O projeto já possui ou assume que possui:

- sistema de combate por `Hitbox` e `Hurtbox`;
- `HPComponent`;
- `StaminaComponent`;
- ataques que gastam stamina, estilo souls-like;
- inimigos que podem morrer e disparar drop.

Este documento propõe um sistema **pequeno, funcional e evolutivo**. A regra é: começar simples, sem copiar toda a complexidade de Path of Exile, Ultima Online ou Diablo.

---

## 2. Referências conceituais

### 2.1 Godot Resources

Godot `Resource` é adequado para dados reutilizáveis, editáveis pelo Inspector e salvos como `.tres` ou `.res`. A documentação oficial descreve `Resource` como um container de dados do Godot, podendo ser salvo em disco, referenciado e reutilizado. Custom Resources podem aparecer no editor quando usam `class_name` em GDScript.

Uso no projeto:

- `ItemBase` deve ser `Resource`.
- `ItemInstance` também pode ser `Resource` no começo.
- Cada item base, como `rusty_dagger.tres`, deve ser editável no Inspector.

Fonte:

- https://docs.godotengine.org/en/stable/classes/class_resource.html
- https://docs.godotengine.org/en/4.4/tutorials/scripting/resources.html
- https://docs.godotengine.org/pt-br/4.x/tutorials/scripting/resources.html

### 2.2 Godot multiplayer nativo

Godot 4 possui API high-level multiplayer e implementação baseada em `ENetMultiplayerPeer`, usada como `MultiplayerPeer` para servidor/cliente. Para este sistema de itens, a recomendação é que o **host gere os drops**, não os clients.

Uso no projeto:

- host decide o drop;
- host cria a `ItemInstance`;
- host sincroniza o resultado para os clients;
- client não rola item localmente.

Fontes:

- https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html
- https://docs.godotengine.org/en/stable/classes/class_enetmultiplayerpeer.html
- https://docs.godotengine.org/en/stable/classes/class_multiplayerpeer.html

### 2.3 Path of Exile — inspiração, não cópia

Path of Exile trabalha com raridade, item level, modificadores, prefixos/sufixos e itens únicos. Em PoE, itens podem ter propriedades diferentes e os jogadores caçam versões melhores. Este documento usa apenas a ideia básica:

```txt
item base + item level + raridade + rolagem de atributos
```

Não implementar agora:

- prefixos e sufixos complexos;
- pools grandes de modificadores;
- crafting avançado;
- currency system;
- influência, tiers complexos, implicits/explicits etc.

Fonte comunitária de referência:

- https://www.poewiki.net/wiki/Rarity
- https://www.poewiki.net/wiki/Item_level
- https://www.poewiki.net/wiki/Modifier

### 2.4 Ultima Online — inspiração de propriedades mágicas

Ultima Online usa propriedades mágicas em itens, com fontes como loot aleatório, crafting rúnico, imbuing, reforging e itens especiais craftados. Para este projeto, a inspiração é apenas: **um item pode vir com propriedades variáveis e isso cria desejo por drops melhores**.

Fonte:

- https://uo.com/wiki/ultima-online-wiki/items/magic-item-properties/

---

## 3. Objetivo do sistema

Criar um sistema onde um inimigo pode dropar uma adaga com valores diferentes, por exemplo:

```txt
Rusty Dagger [Lv.1]
Rarity: Normal
Damage: 5
DEX: +0
```

```txt
Rusty Dagger [Lv.1]
Rarity: Magic
Damage: 8
DEX: +1
```

```txt
Rusty Dagger [Lv.3]
Rarity: Rare
Damage: 16
DEX: +5
```

O jogador deve conseguir caçar uma versão melhor do mesmo item.

---

## 4. Princípio de arquitetura

Separar o item em duas camadas:

```txt
ItemBase = molde do item
ItemInstance = item real dropado
```

### 4.1 ItemBase

Define o que o item **pode ser**.

Exemplo:

```txt
Rusty Dagger
- pode ser level 1 a 3
- damage level 1: 4-8
- damage level 2: 7-12
- damage level 3: 10-16
- DEX level 1: 0-1
- DEX level 2: 0-2
- DEX level 3: 1-3
```

### 4.2 ItemInstance

Define o que o item **virou depois de dropar**.

Exemplo:

```txt
Rusty Dagger [Lv.2]
Rarity: Magic
Damage: 11
DEX: +1
```

---

## 5. Regra simples de DEX

DEX tem duas funções nesta primeira versão:

1. item pode dar bônus de DEX;
2. DEX pode aumentar o dano da arma equipada.

Não adicionar ainda:

- evasão;
- crítico;
- velocidade de ataque;
- redução de stamina;
- accuracy;
- bleed;
- backstab scaling.

Essas coisas podem vir depois.

Regra inicial:

```txt
Dano final = dano rolado da arma + DEX final * 0.5
```

Exemplo:

```txt
Arma damage: 8
DEX final: 12
Dano final = 8 + 12 * 0.5
Dano final = 14
```

---

## 6. Estrutura de arquivos recomendada

```txt
res://scripts/components/
  stats_component.gd
  equipment_component.gd
  drop_component.gd

res://scripts/data/
  item_base.gd
  item_instance.gd

res://scripts/systems/
  item_generator.gd

res://data/items/
  rusty_dagger.tres
```

---

## 7. StatsComponent

Responsabilidade:

- guardar DEX base;
- guardar DEX bônus vindo dos itens;
- retornar DEX final.

Arquivo:

```txt
res://scripts/components/stats_component.gd
```

Código:

```gdscript
class_name StatsComponent
extends Node

@export var base_dex: int = 10
var bonus_dex: int = 0

func get_dex() -> int:
	return base_dex + bonus_dex

func add_dex_bonus(value: int) -> void:
	bonus_dex += value

func remove_dex_bonus(value: int) -> void:
	bonus_dex -= value
```

Regra:

```txt
base_dex = atributo natural do personagem
bonus_dex = soma dos itens equipados
get_dex() = valor real usado no combate
```

---

## 8. ItemBase

Responsabilidade:

- ser o molde editável do item;
- definir faixas de dano por level;
- definir faixas de DEX por level.

Arquivo:

```txt
res://scripts/data/item_base.gd
```

Código:

```gdscript
class_name ItemBase
extends Resource

@export var item_id: String
@export var display_name: String
@export var item_type: String = "weapon"

@export var min_level: int = 1
@export var max_level: int = 3

@export var damage_min_per_level: Array[int] = [4, 7, 10]
@export var damage_max_per_level: Array[int] = [8, 12, 16]

@export var dex_min_per_level: Array[int] = [0, 0, 1]
@export var dex_max_per_level: Array[int] = [1, 2, 3]
```

Observação importante:

- os arrays usam índice começando em `0`;
- item level 1 usa índice `0`;
- item level 2 usa índice `1`;
- item level 3 usa índice `2`.

---

## 9. ItemInstance

Responsabilidade:

- guardar o item real dropado;
- guardar o level rolado;
- guardar raridade;
- guardar dano rolado;
- guardar bônus de DEX rolado.

Arquivo:

```txt
res://scripts/data/item_instance.gd
```

Código:

```gdscript
class_name ItemInstance
extends Resource

@export var item_id: String
@export var display_name: String
@export var item_type: String = "weapon"

@export var item_level: int = 1
@export var rarity: String = "normal"

@export var damage: int = 0
@export var dex_bonus: int = 0
```

Exemplo de item real:

```txt
item_id = rusty_dagger
display_name = Rusty Dagger
item_type = weapon
item_level = 2
rarity = magic
damage = 11
dex_bonus = 1
```

---

## 10. Rusty Dagger como Resource

Criar arquivo:

```txt
res://data/items/rusty_dagger.tres
```

Tipo:

```txt
ItemBase
```

Valores sugeridos:

```txt
item_id = rusty_dagger
display_name = Rusty Dagger
item_type = weapon

min_level = 1
max_level = 3

damage_min_per_level = [4, 7, 10]
damage_max_per_level = [8, 12, 16]

dex_min_per_level = [0, 0, 1]
dex_max_per_level = [1, 2, 3]
```

Interpretação:

```txt
Rusty Dagger Lv.1
Damage: 4-8
DEX: 0-1

Rusty Dagger Lv.2
Damage: 7-12
DEX: 0-2

Rusty Dagger Lv.3
Damage: 10-16
DEX: 1-3
```

---

## 11. ItemGenerator

Responsabilidade:

- receber um `ItemBase`;
- receber level do monstro;
- decidir item level;
- rolar raridade;
- rolar dano;
- rolar DEX se aplicável;
- retornar `ItemInstance`.

Arquivo:

```txt
res://scripts/systems/item_generator.gd
```

Código:

```gdscript
class_name ItemGenerator
extends Node

static func generate_item(base: ItemBase, monster_level: int) -> ItemInstance:
	var item_level := clamp(monster_level, base.min_level, base.max_level)
	var index := item_level - 1

	var item := ItemInstance.new()
	item.item_id = base.item_id
	item.display_name = base.display_name
	item.item_type = base.item_type
	item.item_level = item_level
	item.rarity = roll_rarity()

	item.damage = randi_range(
		base.damage_min_per_level[index],
		base.damage_max_per_level[index]
	)

	if item.rarity == "normal":
		item.dex_bonus = 0
	elif item.rarity == "magic":
		item.dex_bonus = randi_range(
			base.dex_min_per_level[index],
			base.dex_max_per_level[index]
		)
	elif item.rarity == "rare":
		item.dex_bonus = randi_range(
			base.dex_max_per_level[index],
			base.dex_max_per_level[index] + 2
		)

	return item

static func roll_rarity() -> String:
	var roll := randf() * 100.0

	if roll < 5.0:
		return "rare"
	elif roll < 25.0:
		return "magic"
	else:
		return "normal"
```

Raridade inicial:

```txt
75% normal
20% magic
5% rare
```

---

## 12. Interpretação de raridade

### Normal

```txt
Normal = só dano rolado
DEX = 0
```

Exemplo:

```txt
Normal Rusty Dagger [Lv.1]
Damage: 6
```

### Magic

```txt
Magic = dano rolado + DEX dentro da faixa normal do item level
```

Exemplo:

```txt
Magic Rusty Dagger [Lv.1]
Damage: 8
DEX: +1
```

### Rare

```txt
Rare = dano rolado + DEX acima da faixa normal
```

Exemplo:

```txt
Rare Rusty Dagger [Lv.1]
Damage: 8
DEX: +3
```

---

## 13. DropComponent

Responsabilidade:

- ficar no inimigo;
- guardar level do monstro;
- guardar lista de possíveis itens;
- gerar drop quando o inimigo morrer.

Arquivo:

```txt
res://scripts/components/drop_component.gd
```

Código:

```gdscript
class_name DropComponent
extends Node

@export var monster_level: int = 1
@export var possible_drops: Array[ItemBase] = []

func roll_drop() -> Array[ItemInstance]:
	var drops: Array[ItemInstance] = []

	if possible_drops.is_empty():
		return drops

	var base_item := possible_drops.pick_random()
	var item := ItemGenerator.generate_item(base_item, monster_level)
	drops.append(item)

	return drops
```

Cena do inimigo:

```txt
Enemy
├── HPComponent
├── Hurtbox
└── DropComponent
```

No Inspector:

```txt
monster_level = 1
possible_drops = [rusty_dagger.tres]
```

---

## 14. Chamada no HPComponent

Quando o inimigo morrer, procurar o `DropComponent` e gerar item.

Exemplo:

```gdscript
func die() -> void:
	var drop_component := owner.get_node_or_null("DropComponent")

	if drop_component != null:
		var drops := drop_component.roll_drop()

		for item in drops:
			print(
				"Dropou: ",
				item.display_name,
				" Lv.", item.item_level,
				" ", item.rarity,
				" Damage:", item.damage,
				" DEX:", item.dex_bonus
			)

	owner.queue_free()
```

Por enquanto isso só imprime. Depois criar um item físico no chão.

---

## 15. EquipmentComponent simples

Responsabilidade:

- equipar uma arma;
- aplicar DEX bônus da arma/item;
- remover DEX bônus ao desequipar;
- fornecer a arma equipada para o sistema de ataque.

Arquivo:

```txt
res://scripts/components/equipment_component.gd
```

Código:

```gdscript
class_name EquipmentComponent
extends Node

@onready var stats: StatsComponent = $"../StatsComponent"

var equipped_weapon: ItemInstance = null

func equip_weapon(item: ItemInstance) -> void:
	if equipped_weapon != null:
		unequip_weapon()

	equipped_weapon = item
	stats.add_dex_bonus(item.dex_bonus)

func unequip_weapon() -> void:
	if equipped_weapon == null:
		return

	stats.remove_dex_bonus(equipped_weapon.dex_bonus)
	equipped_weapon = null

func get_weapon() -> ItemInstance:
	return equipped_weapon
```

Observação:

- nesta versão, a própria arma pode dar DEX;
- futuramente luvas, anéis e botas também poderão usar o mesmo conceito.

---

## 16. Cálculo de dano com DEX

Sistema simples:

```txt
Dano final = item.damage + DEX final * 0.5
```

Função:

```gdscript
func calculate_damage(weapon: ItemInstance, stats: StatsComponent) -> int:
	if weapon == null:
		return 1

	var dex := stats.get_dex()
	var value := weapon.damage + dex * 0.5
	return roundi(value)
```

Exemplo:

```txt
Weapon damage: 8
Base DEX: 10
Item DEX bonus: +1
DEX final: 11

Dano final = 8 + 11 * 0.5
Dano final = 13.5
round = 14
```

---

## 17. Fluxo completo do sistema

```txt
1. Inimigo morre.
2. HPComponent chama DropComponent.
3. DropComponent escolhe um ItemBase.
4. ItemGenerator cria uma ItemInstance.
5. ItemInstance recebe:
   - item_level;
   - rarity;
   - damage;
   - dex_bonus.
6. Item é impresso no console ou spawnado no chão.
7. Player pega o item.
8. Player equipa o item.
9. EquipmentComponent soma dex_bonus no StatsComponent.
10. AttackController usa item.damage + DEX final * 0.5.
```

---

## 18. Teste isolado do gerador

Criar script temporário em qualquer Node de teste:

```gdscript
@export var test_item_base: ItemBase

func _ready() -> void:
	randomize()

	for i in 10:
		var item := ItemGenerator.generate_item(test_item_base, 1)
		print(
			item.display_name,
			" Lv.", item.item_level,
			" ", item.rarity,
			" Damage:", item.damage,
			" DEX:", item.dex_bonus
		)
```

Saída esperada:

```txt
Rusty Dagger Lv.1 normal Damage:5 DEX:0
Rusty Dagger Lv.1 normal Damage:8 DEX:0
Rusty Dagger Lv.1 magic Damage:7 DEX:1
Rusty Dagger Lv.1 rare Damage:8 DEX:3
```

---

## 19. Como o jogador entende o loot

Na UI, mostrar:

```txt
Magic Rusty Dagger [Lv.1]
Damage: 8
+1 DEX
```

Ou:

```txt
Rare Rusty Dagger [Lv.3]
Damage: 16
+5 DEX
```

O jogador deve entender rapidamente:

```txt
level maior = base melhor
raridade maior = chance de bônus melhor
rolagem maior = item melhor dentro do mesmo level
```

---

## 20. O que não implementar agora

Não implementar nesta fase:

- prefixos e sufixos;
- múltiplos status além de DEX;
- item mágico com fogo, gelo, veneno, bleed;
- crítico;
- item sockets;
- crafting;
- reroll;
- upgrade;
- identificação de item;
- economia complexa;
- raridade lendária;
- unique/artifact;
- comparação visual avançada;
- serialização completa de inventário.

Motivo: o objetivo é validar o núcleo primeiro.

---

## 21. Próximas evoluções naturais

Depois que o sistema acima estiver funcionando, evoluir nesta ordem:

### Fase 2 — Item físico no chão

Criar cena:

```txt
DroppedItem.tscn
├── Sprite2D
├── Area2D
└── CollisionShape2D
```

O `DroppedItem` guarda uma `ItemInstance`.

### Fase 3 — Inventário simples

Criar:

```txt
InventoryComponent
- items: Array[ItemInstance]
- add_item(item)
- remove_item(item)
```

### Fase 4 — Equipamento por slot

Trocar `equipped_weapon` simples por slots:

```txt
main_hand
off_hand
head
chest
legs
gloves
ring
boots
```

### Fase 5 — Mais atributos

Adicionar:

```txt
STR
INT
VIT
END
```

Mas manter a mesma estrutura:

```txt
base_stat + bonus_stat = final_stat
```

### Fase 6 — Affixes simples

Adicionar modificadores como:

```txt
of Agility = +DEX
of Power = +STR
Sharp = +Damage
```

Só depois que o básico estiver estável.

---

## 22. Critérios de aceite para o agente LLM

O sistema está correto quando:

- [ ] `ItemBase` existe como `Resource`.
- [ ] `ItemInstance` existe como item real dropado.
- [ ] `rusty_dagger.tres` pode ser editado no Inspector.
- [ ] `ItemGenerator.generate_item()` cria drops diferentes.
- [ ] Monstro level 1 gera item level 1.
- [ ] Monstro level 3 gera item level 3, respeitando `max_level`.
- [ ] Raridade normal não dá DEX.
- [ ] Raridade magic dá DEX dentro da faixa.
- [ ] Raridade rare dá DEX acima da faixa.
- [ ] Equipar item soma DEX bônus.
- [ ] Desequipar item remove DEX bônus.
- [ ] Dano usa `item.damage + DEX * 0.5`.
- [ ] O client não deve gerar drop localmente em multiplayer; o host gera.

---

## 23. Resumo final

O núcleo do sistema é:

```txt
Monstro tem level.
ItemBase define faixas por level.
ItemGenerator cria ItemInstance.
ItemInstance guarda a rolagem real.
Raridade decide se vem DEX extra.
StatsComponent soma DEX base + DEX dos itens.
Ataque usa dano rolado + DEX final.
```

Esse modelo é simples, modular, data-driven e permite crescer sem reescrever tudo.

