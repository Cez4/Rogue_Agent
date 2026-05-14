# Plano Sprint - SaveFlow Slots & Host Authority v1

Data: 2026-05-13
Status: CONCLUIDA - FREEZE FUNCIONAL V16
Branch sugerida: `feat/saveflow-slots-host-authority-v1`
Baseline obrigatorio:
1. `status-freeze-funcional-v15-saveflow-lite-persistence-2026-05-13.md`
2. `plano-sprint-saveflow-lite-persistence-v1-2026-05-13.md`
3. `docs/godotmcp/runbook-saveflow-lite-rogue-agent.md`
4. `docs/godotmcp/runbook-expressobits-seguranca.md`

## 1) Objetivo
Transformar a prova funcional V15 em um fluxo jogavel/controlado de save/load.

V15 provou que o inventario do Player salva/carrega sem reroll quando o SaveFlow e chamado corretamente. Esta sprint cria a camada que decide **quem**, **quando** e **em qual slot** o save/load acontece.

Resultado esperado:
1. `NexusSaveAuthority` como unica fachada oficial para save/load de gameplay.
2. Slot ativo de dev controlado por dados, inicialmente `profile_0`.
3. Comandos de smoke/dev para salvar e carregar o inventario entre sessoes.
4. Protecao host-authoritative: cliente nao grava/carrega estado autoritativo.
5. Telemetria para provar persistencia real entre restart/load.

## 2) Base Tecnica Confirmada
Docs oficiais SaveFlow Lite consultados:
1. `SaveFlow.save_scope()` e `SaveFlow.load_scope()` sao o caminho correto para grafos hierarquicos com `SaveFlowScope`.
2. `SaveFlowDataSource` e o caminho recomendado para sistemas/modelos como inventario.
3. `SaveFlow.read_slot_summary()` e `SaveFlow.list_slot_summaries()` existem para UI futura de lista de saves sem carregar gameplay inteiro.
4. O plugin ja possui operacoes de slot como save, load, delete, copy, rename e list.
5. O painel `SaveFlow Settings` controla defaults globais, mas comportamento de gameplay deve ficar nos sources/scopes/authority do projeto.

## 3) Decisao Tecnica
SaveFlow continua sendo orquestrador. A autoridade de gameplay deve ficar no namespace Nexus.

Fluxo aprovado:
1. UI/dev command chama `NexusSaveAuthority`.
2. `NexusSaveAuthority` valida autoridade local/host.
3. `NexusSaveAuthority` resolve slot e `SaveFlowScope`.
4. `NexusSaveAuthority` chama `SaveFlow.save_scope()` ou `SaveFlow.load_scope()`.
5. `PlayerInventorySource` executa serializacao/hidratacao do inventario.
6. `NexusEquipmentAdapter` reconstrói `EquipmentLoadout` em memoria.

Nao inverter o fluxo. Nenhuma UI, BT, HSM ou cena deve manipular SaveFlow diretamente para estado autoritativo.

## 4) Escopo Fechado
Dentro da sprint:
1. Criar `NexusSaveAuthority`.
2. Criar slot default `profile_0`.
3. Criar API minima:
   - `save_player_slot(slot_id: String = "") -> SaveResult`;
   - `load_player_slot(slot_id: String = "") -> SaveResult`;
   - `read_player_slot_summary(slot_id: String = "") -> SaveResult`, se a API local estiver disponivel.
4. Emitir telemetria:
   - `save_authority_save_requested`;
   - `save_authority_save_completed`;
   - `save_authority_load_requested`;
   - `save_authority_load_completed`;
   - `save_authority_rejected`.
5. Criar smoke de persistencia entre sessoes:
   - run 1: gerar dagger, salvar slot;
   - run 2: carregar slot, provar mesmos rolls.

Fora da sprint:
1. UI final de save/load.
2. autosave/checkpoint.
3. quests/world flags.
4. runtime entity persistence.
5. sincronizacao completa via SpacetimeDB.
6. inventario de hostis.

## 5) Arquitetura Proposta

```text
mundo.tscn
|- Player
|  |- SaveGraphRoot
|     |- PlayerInventorySource
|- NexusSaveAuthority
```

Responsabilidades:
1. `PlayerInventorySource`: sabe salvar/carregar inventario.
2. `NexusSaveAuthority`: sabe se pode salvar/carregar e qual slot usar.
3. `SaveFlow`: escreve/le arquivo e coordena o grafo.
4. `NexusInventoryBridgeComponent`: aplica payload no inventario.
5. `NexusEquipmentAdapter`: traduz item persistido para combate runtime.

Evitar:
1. autoload novo antes de necessidade real;
2. save dentro do `Actor8DirLimbo`;
3. save direto em botao de UI;
4. salvar BT/HSM/hit reaction/knockback;
5. anexar smoke runner permanente em cena.

## 6) Plano De Execucao

### Fase A - Auditoria E Gate Inicial
- [x] Criar branch `feat/saveflow-slots-host-authority-v1`.
- [x] Confirmar worktree limpa.
- [x] Abrir `res://cenas/mundo.tscn` no Godot MCP.
- [x] Rodar baseline sem alterar cena.
- [x] Confirmar:
  - `weapon_dagger_starter` nasce quando nao ha load;
  - `inventory_equipment_adapter_resolved resource_path=memory_generated`;
  - sem parse/runtime error novo.

### Fase B - NexusSaveAuthority
- [x] Criar `res://Scripts/save/nexus_save_authority.gd`.
- [x] Implementar slot default `profile_0`.
- [x] Resolver Player e `SaveGraphRoot` por `NodePath`.
- [x] Chamar `SaveFlow.save_scope()` e `SaveFlow.load_scope()`.
- [x] Implementar guard de autoridade:
  - offline/dev local permitido;
  - cliente remoto rejeitado.

### Fase C - Integracao Em Cena
- [x] Adicionar `NexusSaveAuthority` ao `mundo.tscn` via Godot/editor API.
- [x] Configurar `player_path`.
- [x] Abrir cena e validar sem erro.
- [x] Nao alterar combate, BT, HSM ou inventario V13/V14.

### Fase D - Smoke De Slot
- [x] Criar runner/comando temporario de QA.
- [x] Run 1:
  - iniciar mundo;
  - registrar `rolled_damage` e `rolled_dex_bonus`;
  - salvar `profile_0`.
- [x] Run 2:
  - carregar `profile_0`;
  - confirmar mesmos rolls;
  - confirmar `memory_generated`.
- [x] Remover runner temporario da cena final.

### Fase E - Slot Summary Para UI Futura
- [x] Validar `SaveFlow.read_slot_summary()` em runtime via authority.
- [x] Registrar no plano/freeze quais campos podem alimentar UI futura:
  - display name;
  - save type;
  - compatibility;
  - location/chapter/playtime quando existirem.
- [x] Nao criar UI final nesta sprint.

### Fase F - Freeze
- [x] Criar `status-freeze-funcional-v16-saveflow-slots-host-authority-2026-05-13.md`.
- [x] Atualizar `README.md`.
- [x] Atualizar `Cliente/nexus/docs/README.md`.
- [x] Atualizar `docs/godotmcp/runbook-saveflow-lite-rogue-agent.md`.
- [x] Atualizar `docs/skills/doc-first-godot-limboai-skill.md`.
- [ ] Commit/push apenas apos MCP gate limpo.

## 7) Criterios De Aceite
1. Save/load de slot passa por `NexusSaveAuthority`.
2. Nenhum gameplay code chama SaveFlow diretamente fora da authority/sources.
3. Slot `profile_0` salva e carrega o inventario do Player.
4. A dagger persiste entre duas sessoes de teste sem reroll.
5. `ItemStack.item_id` e `ItemStack.properties` continuam preservados.
6. `NexusEquipmentAdapter` continua resolvendo `memory_generated`.
7. Cliente sem autoridade nao executa save/load autoritativo.
8. Runner/comando de QA nao fica anexado na cena final.
9. Nenhum script de combate, BT ou HSM e alterado.

## 8) Telemetria Obrigatoria
Eventos:
1. `save_authority_save_requested`
2. `save_authority_save_completed`
3. `save_authority_load_requested`
4. `save_authority_load_completed`
5. `save_authority_rejected`

Payload minimo:
1. `slot_id`
2. `scope_key`
3. `ok`
4. `reason`
5. `actor`
6. `stack_count`
7. `item_id`
8. `rolled_damage`
9. `rolled_dex_bonus`

## 9) Riscos E Mitigacoes
1. **Risco: cliente salvar estado autoritativo.**
   - Mitigacao: `NexusSaveAuthority` como unica entrada de save/load.
2. **Risco: UI futura chamar SaveFlow direto.**
   - Mitigacao: runbook e skill declaram a fachada obrigatoria.
3. **Risco: starter item rerollar por load tardio.**
   - Mitigacao: usar contrato V15 `apply_loaded_inventory`.
4. **Risco: runner temporario ficar em cena.**
   - Mitigacao: `rg` antes do freeze e gate final sem runner.
5. **Risco: salvar estado transiente de combate.**
   - Mitigacao: sprint limitada a inventario/slot.

## 10) Proximo Passo Seguro
Criar a branch `feat/saveflow-slots-host-authority-v1` e executar a Fase A pelo Godot MCP antes de qualquer edicao runtime.

## 11) Resultado Da Sprint
Sprint concluida em V16.

Implementado:
1. `NexusSaveAuthority` como fachada oficial de save/load de gameplay.
2. Slot default `profile_0`.
3. `save_player_slot`, `load_player_slot`, `read_player_slot_summary` e `has_player_slot`.
4. Guard host-authoritative com offline/dev local permitido.
5. Telemetria de requested/completed/rejected para save/load.
6. Runner de QA `SaveFlowAuthoritySmokeRunner`, sem ficar anexado na cena final.

Evidencia:
1. `save_authority_save_completed ok=true`.
2. `save_authority_load_completed ok=true`.
3. `save_authority_smoke_result ok=true`.
4. `payload_restored=true`.
5. `slot_summary_ok=true`.
6. `rolled_damage = 5`, `rolled_dex_bonus = 3`, `rarity = rare` preservados no smoke final.
7. Gate final sem runner temporario manteve `inventory_equipment_adapter_resolved resource_path=memory_generated`.
