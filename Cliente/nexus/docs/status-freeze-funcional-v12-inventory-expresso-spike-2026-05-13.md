# Status Freeze V12: Inventory ExpressoBits Spike

Data: 2026-05-13
Status: aprovado em QA log/funcional e congelado.
Branch: `feat/inventory-expresso-spike-v1`
Base obrigatoria:
1. `status-freeze-funcional-v11-hitbreak-combat-feedback-2026-05-13.md`

## Resumo Executivo
Esta sprint congelou a aprovacao do addon **ExpressoBits Inventory System** como a engine oficial de inventario data-driven do projeto.

O spike foi feito garantindo que o addon atue apenas como "banco de dados" e conteiner de itens, sem ditar a logica final de combate. Os modulos `NexusInventoryBridgeComponent` e `NexusInventoryAuthority` foram criados para servirem de barreira de seguranca host-authoritative entre a engine do addon e a arquitetura `Actor8DirLimbo` do nosso Action-RPG. 

## Escopo Congelado
Arquitetura validada e congelada:
1. `res://addons/inventory-system/` aprovado como core oficial.
2. `res://configs/items/inventory/nexus_inventory_database_v1.tres` operando com seeds (dagger, armor, materiais simples).
3. `NexusInventoryBridgeComponent` (presente em `player.tscn`).
4. `NexusInventoryAuthority`.
5. `NexusEquipmentAdapter`.

Importante: o diretorio `addons/inventory-system-demos` esta no `.gitignore`. Nao deve ser commitado para a codebase oficial a fim de evitar acoplamento do projeto ao runtime da demo.

## Evidencia De QA
Durante QA real no Godot MCP (`mundo.tscn`), comprovamos:
1. **Zero Corrupcao no V11:** O Player iniciou o combate contra o Brute. Ataques, Hit Reaction, Knockback e Hitbreak ocorreram de forma exata. O Brute morreu (`target_died`).
2. **Kiting / Orbs / Regen Intactos:** Ticks de health regen (`health_regen_tick`) rodaram normalmente ao final do engajamento.
3. **Seed Inicial Estavel:** O inventario seedou `weapon_dagger_starter` atraves da *Authority*, emitindo a telemetria `inventory_add_requested` e `inventory_item_added`. A bridge e passiva e nao tentou substituir o `EquipmentLoadout` aprovado ainda.

## Contrato Congelado
1. O ExpressoBits so podera sofrer modificacoes usando o *Godot Editor API* ou a interface do Godot. *Nunca* por text replacement manual.
2. A database continuara em `configs/items/inventory`.
3. Todo intent de adicionar, consumir, equipar ou craftar um item tem que passar por uma validacao (Host-Authoritative) via `NexusInventoryAuthority`.
4. Os recursos antigos (`ItemData`, `WeaponData`) irao coexistir pacificamente com os definitions do ExpressoBits ate uma sprint futura em que a refatoracao do *Adapter* permita que a BT / HSM leia puramente dos itens novos.

## Estado Atual Apos V12
A fundacao data-driven de inventario esta solida e nao quebrou nosso *Game Feel* do Action-RPG. O projeto esta limpo de erros e pronto para o proximo grande avanco.