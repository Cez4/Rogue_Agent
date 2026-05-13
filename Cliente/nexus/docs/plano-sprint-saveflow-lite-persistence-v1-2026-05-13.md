# Plano Sprint - SaveFlow Lite Persistence v1

Data: 2026-05-13
Status: CONCLUIDA - FREEZE FUNCIONAL V15
Branch sugerida: `feat/saveflow-lite-persistence-v1`
Baseline obrigatorio:
1. `status-freeze-funcional-v14-dynamic-loot-dex-2026-05-13.md`
2. `status-freeze-funcional-v13-inventory-datadriven-core-2026-05-13.md`
3. `docs/godotmcp/runbook-expressobits-seguranca.md`

## 1) Objetivo
Integrar o **SaveFlow Lite** como camada oficial de persistencia local do Rogue Agent, respeitando o modelo **co-op com autoridade no host** e preservando a ponte V13/V14:

`ExpressoBits Database -> InventoryBridge -> ItemStack.item_id/properties -> NexusEquipmentAdapter -> EquipmentLoadout/WeaponData/CombatActionData em memoria`.

O primeiro alvo funcional e simples e verificavel:
1. Salvar o inventario runtime do Player.
2. Carregar o mesmo inventario antes dos `starting_items`.
3. Garantir que a adaga inicial nao rerolla quando existe save valido.
4. Preservar dano, DEX, stamina, kiting e telemetria aprovados.

## 2) Decisao Tecnica
SaveFlow Lite entra como **orquestrador de save/load por dominios**, nao como fonte de verdade de itens e nao como substituto do ExpressoBits.

Fontes de verdade continuam:
1. `nexus_inventory_database_v1.tres`: moldes de itens e propriedades base.
2. `ItemStack.properties`: rolagens unicas de instancia (`rolled_damage`, `rolled_dex_bonus`, `rarity`, `item_level`).
3. `NexusInventoryAuthority`: validacao host-authoritative de add/remove/transfer/craft.
4. `NexusEquipmentAdapter`: tradutor oficial para runtime de combate.

SaveFlow deve persistir estado estavel. Nao persistir:
1. estado atual de BT;
2. estado atual de HSM;
3. animacao em andamento;
4. hit reaction ativo;
5. knockback ativo;
6. caches reconstruiveis;
7. debug/telemetria temporaria.

## 3) Escopo Co-op Host Authoritative
O Rogue Agent e co-op com autoridade no host. Portanto:
1. Apenas o host deve executar save/load autoritativo de gameplay.
2. Cliente envia intents e recebe estado sincronizado.
3. Save local de cliente nao pode sobrescrever inventario, quests ou mundo autoritativo.
4. Em modo offline/dev, o proprio jogo local e tratado como host, igual ao contrato atual de `NexusInventoryAuthority`.

## 4) Arquitetura Proposta

### Dominios SaveFlow
Criar uma raiz de grafo de save com escopos claros:

```text
SaveGraphRoot
|- SessionScope
|- PlayerScope
|  |- PlayerInventorySource
|  |- PlayerStableStateSource
|- WorldScope
|  |- QuestStateSource        (fase futura)
|  |- WorldFlagsSource        (fase futura)
|- RuntimeScope
   |- RuntimeEntityCollection (fase futura)
```

### Primeira fonte customizada
Criar um `NexusInventorySaveSource` usando `SaveFlowDataSource`, porque o inventario ja tem fonte de verdade propria e precisa de traducao customizada.

Contrato:
1. `gather_data()` chama `NexusInventoryBridgeComponent.serialize_inventory()`.
2. `apply_data(data)` chama `NexusInventoryBridgeComponent.deserialize_inventory(data)`.
3. O load precisa acontecer antes de `_apply_starting_items()` ou o bridge precisa expor um fluxo de hidratacao explicito.
4. Depois do load, o Player deve reconstruir o `EquipmentLoadout` runtime via `get_equipment_loadout_runtime()`.

## 5) Plano De Execucao

### Fase A - Auditoria Da Instalacao
- [x] Confirmar que o plugin foi instalado em `res://addons/saveflow_core/` e `res://addons/saveflow_lite/`.
- [x] Confirmar que o editor abriu a aba `SaveFlow Settings`.
- [x] Validar pelo Godot MCP que o editor esta acessivel com `res://cenas/mundo.tscn` aberto e sem erro de sessao apos a instalacao.
- [x] Registrar que `SaveFlow` foi adicionado como autoload e `res://addons/saveflow_lite/plugin.cfg` foi habilitado no `project.godot`.
- [x] Rodar play/smoke completo pelo MCP antes de qualquer implementacao runtime.

### Fase B - Contrato De Persistencia Do Inventario
- [x] Auditar `NexusInventoryBridgeComponent` para decidir o menor ajuste seguro:
  - opcao preferida: adicionar modo explicito de hidratacao antes dos starting items;
  - alternativa: criar um metodo `apply_loaded_inventory(data)` e marcar `_starting_items_applied = true` quando o save e valido.
- [x] Garantir que starting item so e aplicado quando nao existe save carregado e o inventario real esta vazio.
- [x] Manter `NexusInventoryAuthority` como unica rota de mutacao em gameplay.

### Fase C - Save Source Isolado
- [x] Criar `Scripts/save/nexus_inventory_save_source.gd`.
- [x] Implementar como `SaveFlowDataSource`, nao como `NodeSource`, para evitar double ownership de subtree.
- [x] Adicionar telemetria:
  - `saveflow_inventory_gathered`;
  - `saveflow_inventory_applied`;
  - `saveflow_inventory_rejected`.
- [x] Validar payload minimo:
  - `item_id`;
  - `amount`;
  - `properties`;
  - sem referencia direta para `ItemDefinition`;
  - sem uso de `stack.item`.

### Fase D - SaveGraph De Smoke
- [x] Criar um grafo de save isolado em cena ou subcena propria, sem acoplar em combate.
- [x] Adicionar `PlayerScope` e `PlayerInventorySource`.
- [x] Usar slot de dev em `user://saves`.
- [x] Rodar save/load manual via Godot MCP/editor API.

### Fase E - QA Funcional Principal
- [x] Iniciar jogo com inventario vazio.
- [x] Confirmar geracao da adaga starter.
- [x] Salvar slot.
- [x] Reiniciar/load.
- [x] Confirmar que:
  - o mesmo `rolled_damage` permanece;
  - o mesmo `rolled_dex_bonus` permanece;
  - nao houve novo `inventory_item_added` de starter depois do load;
  - `inventory_equipment_adapter_resolved` segue `memory_generated`;
  - dano, stamina e kiting continuam corretos.

### Fase F - Expansao Controlada
Somente depois do inventario aprovado:
- [ ] `PlayerStableStateSource`: posicao estavel, HP atual/max, stamina se fizer sentido de design.
- [ ] `QuestStateSource`: progresso de quests, flags e objetivos.
- [ ] `WorldFlagsSource`: portas, bau aberto, itens coletados.
- [ ] `RuntimeEntityCollectionSource`: drops no chao, inimigos persistentes e entidades runtime.

### Fase G - Freeze
- [x] Criar `status-freeze-funcional-v15-saveflow-lite-persistence-2026-05-13.md`.
- [x] Atualizar `README.md`, `Cliente/nexus/docs/README.md` e runbooks.
- [x] Registrar evidencia MCP:
  - `open_scene -> play_scene -> get_godot_errors`;
  - save/load;
  - telemetria de inventario;
  - prova anti-reroll.

## 6) Criterios De Aceite
1. SaveFlow Lite instalado e validado sem erro novo no projeto.
2. Inventario do Player salva e carrega em slot local.
3. A adaga inicial nao rerolla apos load valido.
4. `ItemStack.item_id` e `ItemStack.properties` continuam sendo o contrato; `stack.item` continua proibido.
5. O host e o unico autor de save/load de gameplay em co-op.
6. Player continua consumindo ExpressoBits pelo `NexusEquipmentAdapter`.
7. Hostis continuam preservados em `.tres` ate uma sprint propria.
8. Nenhum script de BT/HSM/combat core e alterado para fazer save funcionar.

## 7) Riscos E Mitigacoes
1. **Risco: double ownership de cena.**
   - Mitigacao: inventario usa `SaveFlowDataSource`, nao `SaveFlowNodeSource` varrendo o Player inteiro.
2. **Risco: reroll por ordem errada de load.**
   - Mitigacao: load/hidratacao antes dos starting items ou flag explicita de save carregado.
3. **Risco: quebrar V13/V14 tentando salvar `ItemDefinition`.**
   - Mitigacao: salvar somente `item_id`, `amount` e `properties`.
4. **Risco: cliente gravar estado autoritativo.**
   - Mitigacao: wrapper `NexusSaveAuthority` ou checagem de host antes de save/load.
5. **Risco: salvar estado transiente de combate.**
   - Mitigacao: persistir apenas snapshots estaveis e reconstruir runtime apos load.

## 8) Proximo Passo Seguro
Executar Fase A pelo Godot MCP:
1. abrir `res://cenas/mundo.tscn`;
2. dar play;
3. coletar `get_godot_errors`;
4. confirmar que SaveFlow instalado nao introduziu erro no baseline V14.2.

## 9) Resultado Da Sprint
Sprint concluida em V15.

Implementado:
1. `NexusInventorySaveSource` como `SaveFlowDataSource` customizado.
2. `SaveGraphRoot`/`PlayerInventorySource` no `player.tscn`.
3. `NexusInventoryBridgeComponent.apply_loaded_inventory(data)` para hidratar save valido e impedir reroll de starting items.
4. Invalidação de `EquipmentLoadout` runtime apos add/remove/transfer/load.
5. Smoke runner de QA em `Scripts/save/debug/saveflow_inventory_smoke_runner.gd`.

Evidencia:
1. `saveflow_inventory_gathered` com `stack_count = 1`.
2. `saveflow_inventory_applied` com `stack_count = 1`.
3. `saveflow_inventory_smoke_result ok=true`.
4. `payload_restored=true`.
5. `rolled_damage = 5`, `rolled_dex_bonus = 0`, `rarity = normal` preservados no smoke.
6. Gate final sem runner temporario manteve `inventory_equipment_adapter_resolved resource_path=memory_generated`.
