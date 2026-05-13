# Plano Sprint - Inventory ExpressoBits Spike v1

Data: 2026-05-13
Status: PLANEJADA - DOC-FIRST
Baseline obrigatorio: `status-freeze-funcional-v11-hitbreak-combat-feedback-2026-05-13.md`
Branch: `feat/inventory-expresso-spike-v1`

## 1) Objetivo
Validar e integrar, em bloco pequeno e reversivel, o addon **ExpressoBits Inventory System** como base data-driven de inventario, itens, craft, loot e hotbar do projeto.

Esta sprint nao substitui imediatamente o sistema atual de `ItemData`, `EquipmentData`, `WeaponData` e `EquipmentLoadout`. O objetivo e criar uma ponte segura entre o addon e a arquitetura atual, preservando o combate aprovado.

## 2) Decisao Tecnica
Tecnologia escolhida:

1. `res://addons/inventory-system/` como core oficial de inventario/craft.
2. `res://addons/inventory-system-demos/` somente como referencia de estudo, nao como runtime do projeto.
3. `res://configs/items/inventory/nexus_inventory_database_v1.tres` como database inicial do projeto.
4. Adaptador proprio do Nexus para isolar o addon do gameplay.

O addon entrou como `GDExtension`, nao como plugin GDScript tradicional. Portanto, ele pode nao aparecer em `Project Settings > Plugins`, mas a aba `Inventory` e as classes nativas (`InventoryDatabase`, `ItemDefinition`, `Inventory`, `GridInventory`, `Hotbar`, `CraftStation`, `Recipe`, `ItemStack`) confirmam que ele esta carregado.

## 3) Estado Atual Comprovado
Auditoria inicial feita em 2026-05-13:

1. Addon instalado em `res://addons/inventory-system/`.
2. Demo instalado em `res://addons/inventory-system-demos/`, tratado como referencia e candidato a exclusao antes do commit final.
3. Database criada pelo diretor:
   - `res://configs/items/inventory/nexus_inventory_database_v1.tres`
4. Godot MCP confirmou:
   - `InventoryDatabase` carrega corretamente;
   - `items = 0`;
   - `recipes = 0`;
   - `item_categories = 0`;
   - `loots = 0`;
   - metodos disponiveis: `get_item`, `get_category_from_id`, `import_json_file`, `export_json_file`.
5. Classes instanciaveis confirmadas por MCP:
   - `ItemDefinition`;
   - `ItemCategory`;
   - `Recipe`;
   - `Inventory`;
   - `GridInventory`;
   - `Hotbar`;
   - `CraftStation`;
   - `Loot`;
   - `ItemStack`.
6. Erro de parser causado por colisao de nome foi corrigido:
   - nosso `EquipmentData.enum Slot` virou `EquipmentSlot`;
   - motivo: o addon registra uma classe nativa chamada `Slot`.

## 4) Principios Da Sprint
1. Nao copiar `CharacterInventorySystem` do demo para o projeto.
2. Nao colocar inventario dentro de `Actor8DirLimbo`.
3. Nao alterar dano, stamina, Hit Reaction, Knockback, BT, HSM, kiting ou Orb nesta sprint.
4. Nao trocar `EquipmentLoadout` por inventario antes de provar o adapter.
5. Cliente nunca muta inventario oficial diretamente em co-op.
6. Host valida e executa intents de inventario/craft.
7. Toda criacao/alteracao estrutural de `.tres` deve usar Godot/editor API ou o editor visual do addon, nao edicao textual manual.
8. A database do projeto deve morar em `res://configs/items/inventory/`, nunca dentro do addon ou do demo.

## 5) Como O Demo Deve Ser Usado
Usar como referencia:

1. `tests/inventory_tests.gd` para contrato basico:
   - `add`;
   - `remove`;
   - `transfer`;
   - `serialize`;
   - `deserialize`;
   - sinais de item/stack.
2. `tests/grid_inventory_test.gd` para contrato de grade:
   - `set_size`;
   - `add_at_position`;
   - `transfer_to`;
   - `split`;
   - `rotate`;
   - ocupacao por tamanho.
3. `ui/craft/*` para entender apresentacao de receitas.
4. `mp/sync_grid_inventory.gd`, `mp/sync_hotbar.gd` e `mp/sync_craft_station.gd` como referencia conceitual de sync por eventos.

Nao usar diretamente:

1. `CharacterInventorySystem.gd` como runtime do Nexus.
2. UI demo como tela final.
3. RPCs do demo sem adapter.
4. Caminhos `rpc_id(1)` hardcoded como contrato de producao.
5. Assets/demos como dependencia real da engine.

## 6) Arquitetura Alvo
Componentes propostos:

1. **NexusInventoryBridgeComponent**
   - Node plug-and-play em atores que possuem inventario.
   - Resolve `InventoryDatabase`.
   - Mantem referencias para `Inventory`, `GridInventory`, `Hotbar` e/ou `CraftStation` quando existirem.
   - Expoe metodos de intent:
     - `request_add_item(item_id, amount, properties)`;
     - `request_remove_item(item_id, amount)`;
     - `request_transfer(...)`;
     - `request_equip(...)`;
     - `request_craft(...)`.
   - Em runtime co-op, delega execucao para o host.

2. **NexusInventoryAuthority**
   - Camada de validacao host-authoritative.
   - Aceita intents de jogador.
   - Valida item, quantidade, origem, destino, craft station e permissao.
   - Executa no addon somente apos validacao.
   - Emite telemetria.

3. **NexusEquipmentAdapter**
   - Ponte entre inventario e `EquipmentLoadout`.
   - No v1, apenas prova que uma dagger do inventario pode apontar para o `WeaponData` atual ou equivalente.
   - Nao muda o combate ate QA provar equivalencia.

4. **InventoryTelemetry**
   - Logs padronizados para:
     - `inventory_item_added`;
     - `inventory_item_removed`;
     - `inventory_transfer_requested`;
     - `inventory_transfer_committed`;
     - `inventory_equip_requested`;
     - `inventory_equip_committed`;
     - `craft_requested`;
     - `craft_committed`;
     - `inventory_rejected`.

## 7) Modelo Data-Driven Inicial
Database inicial:

`res://configs/items/inventory/nexus_inventory_database_v1.tres`

Itens minimos para spike:

1. `dagger_starter`
   - espelha `res://configs/items/weapons/dagger_starter.tres`;
   - item nao stackavel;
   - categoria `weapon`;
   - propriedade sugerida: `nexus_equipment_resource = "res://configs/items/weapons/dagger_starter.tres"`.
2. `cloth_starter`
   - espelha `res://configs/items/armors/cloth_starter.tres`;
   - categoria `armor`;
   - propriedade sugerida: `nexus_equipment_resource = "res://configs/items/armors/cloth_starter.tres"`.
3. `wooden_charm_starter`
   - espelha `res://configs/items/necklaces/wooden_charm_starter.tres`;
   - categoria `necklace`;
   - propriedade sugerida: `nexus_equipment_resource = "res://configs/items/necklaces/wooden_charm_starter.tres"`.
4. Materiais simples para craft smoke:
   - `wood`;
   - `stone`;
   - `fiber`.

Categorias iniciais:

1. `weapon`
2. `armor`
3. `necklace`
4. `material`
5. `consumable` reservado para sprint futura.

Receita inicial de smoke:

1. `fiber + stone -> dagger_starter` ou receita equivalente controlada.
2. Deve ser usada apenas para provar craft pipeline, nao para balance final.

## 8) Fluxo Host-Authoritative
Regra oficial da sprint:

1. Cliente envia intent.
2. Host valida:
   - ator dono;
   - inventario origem/destino;
   - item existe na database;
   - quantidade valida;
   - espaco valido;
   - recipe/craft station valida;
   - regra de equip permitida.
3. Host executa no addon.
4. Host serializa estado ou emite delta.
5. Cliente reflete estado oficial.

Nao fazer:

1. UI chamar `inventory.add()` diretamente como gameplay final.
2. Cliente decidir craft/equip oficial.
3. Arma equipada alterar combate sem passar pelo adapter e QA.

## 9) Plano De Execucao

### Fase A - Higiene De Instalacao E Baseline
- [x] Criar branch propria: `feat/inventory-expresso-spike-v1`.
- [x] Instalar addon via Godot.
- [x] Confirmar `Inventory` tab carregada.
- [x] Corrigir colisao `Slot` -> `EquipmentSlot`.
- [x] Criar database vazia do projeto.
- [ ] Remover ou excluir do commit final `res://addons/inventory-system-demos/`, mantendo apenas como referencia local se necessario.
- [ ] Validar MCP limpo: `get_godot_errors`.
- [ ] Documentar exatamente o que fica versionado.

### Fase B - Database Nexus v1
- [ ] Criar categorias iniciais via Godot/editor API ou editor visual do addon.
- [ ] Criar `dagger_starter`, `cloth_starter`, `wooden_charm_starter`.
- [ ] Criar materiais simples de smoke.
- [ ] Registrar propriedades Nexus nos itens sem acoplar runtime.
- [ ] Validar que `InventoryDatabase.get_item(...)` encontra todos os ids.
- [ ] Criar telemetria/editor script de auditoria da database.

### Fase C - Smoke De Inventario Isolado
- [ ] Criar script/ferramenta de smoke sem cena final:
  - carregar database;
  - criar `Inventory`;
  - adicionar/remover/transferir item;
  - serializar/desserializar;
  - validar retornos.
- [ ] Criar smoke de `GridInventory`:
  - tamanho fixo;
  - item stackavel;
  - item nao stackavel;
  - transferencia.
- [ ] Nenhum Player/NPC deve ser alterado nesta fase.

### Fase D - Bridge Sem Gameplay
- [ ] Criar `NexusInventoryBridgeComponent`.
- [ ] Criar `NexusInventoryAuthority` ou servico equivalente.
- [ ] Integrar telemetria de intent/commit/reject.
- [ ] Instanciar em cena de teste ou sandbox, nao no `mundo.tscn` principal.
- [ ] Provar que cliente/UI chama intent e nao muta inventario oficial diretamente.

### Fase E - Adapter De Equipamento Controlado
- [ ] Criar `NexusEquipmentAdapter`.
- [ ] Mapear item de inventario para resource atual de equipamento.
- [ ] Provar leitura de `nexus_equipment_resource`.
- [ ] Nao substituir `EquipmentLoadout` ativo ainda.
- [ ] Validar que o combate continua usando a dagger atual sem regressao.

### Fase F - Craft Smoke
- [ ] Criar recipe simples na database.
- [ ] Criar `CraftStation` ou smoke de craft isolado.
- [ ] Validar:
  - ingredientes presentes;
  - craft aceito;
  - ingredientes removidos;
  - produto adicionado;
  - rejeicao quando falta ingrediente.
- [ ] Registrar telemetria `craft_requested`, `craft_committed`, `inventory_rejected`.

### Fase G - Integracao Minima Com Player
- [ ] Somente apos A-F aprovadas, adicionar bridge ao Player via Godot/editor API.
- [ ] Inventario inicial deve conter `dagger_starter` sem mudar feel do combate.
- [ ] Confirmar que `EquipmentLoadout` atual permanece fonte de ataque ate adapter aprovado.
- [ ] Validar MCP com `mundo.tscn`.
- [ ] Logs devem confirmar sem erro:
  - player spawn;
  - combat;
  - attack;
  - inventory smoke.

### Fase H - Freeze E Decisao
- [ ] Registrar resultado do spike.
- [ ] Confirmar se ExpressoBits vira dependencia oficial.
- [ ] Remover demos do commit final ou registrar explicitamente como referencia nao-runtime se ficarem versionados.
- [ ] Atualizar README, docs, runbooks e skill.
- [ ] Criar freeze funcional V12 somente se houver QA positivo.

## 10) Criterios De Aceite
Sprint pronta somente quando:

1. Addon core instalado e carregando sem erro.
2. Demo nao entra como dependencia de runtime.
3. Database Nexus v1 tem itens/categorias minimos.
4. Smoke de inventario passa por MCP/editor script.
5. Smoke de serializacao passa.
6. Craft smoke passa.
7. Bridge existe sem inflar `Actor8DirLimbo`.
8. Cliente nao muta estado oficial diretamente.
9. Combate V11 continua sem regressao.
10. Docs e runbooks refletem o contrato.

## 11) Riscos E Mitigacoes
1. **Addon grande demais para o projeto:** manter tudo atras de bridge; se reprovado, remover branch sem afetar core.
2. **Colisao de nomes globais GDExtension:** prefixar enums/classes nossas quando houver conflito; evitar nomes genericos como `Slot`.
3. **Demo virar dependencia acidental:** nao referenciar caminhos `inventory-system-demos` em recursos do projeto.
4. **Cliente autoritativo sem querer:** toda chamada de UI vira intent; host executa.
5. **Combate quebrar ao trocar equipamento:** adapter primeiro em modo leitura; combate so muda apos QA.
6. **`.tres` corrompido por edicao textual:** usar Godot/editor API ou editor visual do addon.
7. **Lock-in do addon:** preservar resources antigos ate provar equivalencia.

## 12) Fontes Tecnicas
1. ExpressoBits Inventory System - Installation:
   - https://expressobits.com/inventory-system/getting_started/installation.html
2. ExpressoBits Inventory System - Creating a Database:
   - https://expressobits.com/inventory-system/getting_started/quickstart/create_database.html
3. Godot GDExtension:
   - https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/index.html
4. Godot Resource:
   - https://docs.godotengine.org/en/stable/classes/class_resource.html
5. Godot ResourceSaver:
   - https://docs.godotengine.org/en/stable/classes/class_resourcesaver.html
6. Godot High-level multiplayer:
   - https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html

## 13) Definicao De Pronto
1. Plano versionado.
2. Database auditada.
3. Demos classificados como referencia, nao runtime.
4. Implementacao em fases pequenas.
5. Godot MCP limpo a cada bloco.
6. Telemetria de inventario/craft registrada.
7. Freeze V12 criado somente depois de QA funcional.
