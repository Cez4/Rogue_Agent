# Plano Sprint - SaveFlow UI Dev Panel v1

Data: 2026-05-13
Status: CONCLUIDA - FREEZE FUNCIONAL V17
Branch executada: `feat/saveflow-ui-dev-panel-v1`
Baseline obrigatorio:
1. `status-freeze-funcional-v16-saveflow-slots-host-authority-2026-05-13.md`
2. `plano-sprint-saveflow-slots-host-authority-v1-2026-05-13.md`
3. `docs/godotmcp/runbook-saveflow-lite-rogue-agent.md`
4. `docs/skills/doc-first-godot-limboai-skill.md`

## 1) Objetivo
Criar um painel dev simples para operar o save/load funcional ja aprovado em V16.

Esta sprint nao cria UI final de produto. O objetivo e dar ao diretor/dev uma interface visual minima para testar e operar:
1. salvar o slot `profile_0`;
2. carregar o slot `profile_0`;
3. ler o resumo do slot;
4. exibir sucesso/erro;
5. provar que UI chama `NexusSaveAuthority`, nunca SaveFlow direto.

## 2) Decisao Tecnica
O painel e cliente da authority.

Fluxo permitido:
```text
SaveFlowDevPanel -> NexusSaveAuthority -> SaveFlow.save_scope/load_scope -> PlayerInventorySource -> InventoryBridge
```

Fluxo proibido:
```text
SaveFlowDevPanel -> SaveFlow direto
```

Motivo: o projeto e co-op/host-authoritative. Mesmo sendo painel dev, ele precisa respeitar o contrato real do jogo. Se a UI aprende a chamar SaveFlow direto agora, a futura UI final nasce errada.

## 3) Escopo Fechado
Dentro da sprint:
1. Criar cena `res://cenas/debug/saveflow_dev_panel.tscn` ou integrar em `DebugTelemetryPanel`, apos auditoria.
2. Criar script `res://Scripts/debug/saveflow_dev_panel.gd` ou equivalente.
3. Botao Save `profile_0`.
4. Botao Load `profile_0`.
5. Botao Refresh Summary.
6. Label/status compacta mostrando:
   - slot id;
   - existe/nao existe;
   - ultimo comando;
   - ok/error;
   - item id;
   - rolled damage;
   - rolled dex bonus.
7. Telemetria:
   - `saveflow_dev_panel_save_clicked`;
   - `saveflow_dev_panel_load_clicked`;
   - `saveflow_dev_panel_summary_clicked`;
   - `saveflow_dev_panel_status_updated`.
8. MCP gate visual/log.

Fora da sprint:
1. UI final de menu principal.
2. multiplos perfis jogaveis.
3. thumbnails.
4. autosave.
5. checkpoint.
6. tela de confirmacao/destrutiva.
7. suporte remoto cliente/host completo.
8. persistencia de quests/world flags.

## 4) Arquitetura Proposta

Opcao preferida:
```text
mundo.tscn
|- DebugTelemetryPanel
|- SaveFlowDevPanel
|- NexusSaveAuthority
```

Alternativa aceitavel:
```text
DebugTelemetryPanel
|- SaveFlowDevPanel
```

Regra de decisao:
1. Se `DebugTelemetryPanel` ja tiver estrutura segura para comandos dev, integrar ali.
2. Se isso aumentar acoplamento ou risco visual, criar painel separado em `cenas/debug`.
3. Nao mexer em `Actor8DirLimbo`.
4. Nao mexer em BT/HSM.
5. Nao alterar `NexusInventoryBridgeComponent` ou `NexusEquipmentAdapter` salvo bug real.

## 5) Plano De Execucao

### Fase A - Auditoria Inicial
- [x] Criar branch `feat/saveflow-ui-dev-panel-v1`.
- [x] Confirmar worktree limpa.
- [x] Auditar `DebugTelemetryPanel`.
- [x] Decidir painel separado vs integracao no painel existente.
- [x] Rodar gate MCP baseline:
  - abrir `mundo.tscn`;
  - play;
  - `get_godot_errors`;
  - confirmar `inventory_equipment_adapter_resolved resource_path=memory_generated`.

### Fase B - Criar UI Minima
- [x] Criar cena/script do painel.
- [x] Layout simples e funcional:
  - titulo curto;
  - botao Save;
  - botao Load;
  - botao Refresh;
  - texto de status.
- [x] Nao usar design final, inventario visual ou menus complexos.
- [x] Garantir que texto nao sobrepoe em viewport comum.

### Fase C - Conectar Authority
- [x] Exportar `authority_path`.
- [x] Resolver `NexusSaveAuthority` por NodePath.
- [x] Botao Save chama `authority.save_player_slot("profile_0")`.
- [x] Botao Load chama `authority.load_player_slot("profile_0")`.
- [x] Botao Refresh chama `authority.read_player_slot_summary("profile_0")`.
- [x] Nenhum metodo chama `SaveFlow` direto.

### Fase D - Telemetria E Status
- [x] Emitir eventos de clique.
- [x] Atualizar status com resultado de `SaveResult`.
- [x] Mostrar resumo de inventario apos save/load quando possivel.
- [x] Mostrar erro legivel quando authority ausente ou slot inexistente.

### Fase E - QA MCP
- [x] Rodar `mundo.tscn`.
- [x] Clicar Save via editor/teste manual ou runner de input se disponivel.
- [x] Clicar Load.
- [x] Clicar Refresh.
- [x] Confirmar logs:
  - `saveflow_dev_panel_save_clicked`;
  - `save_authority_save_completed ok=true`;
  - `saveflow_dev_panel_load_clicked`;
  - `save_authority_load_completed ok=true`;
  - `saveflow_dev_panel_summary_clicked`;
  - summary ok.
- [x] Confirmar que o combate/inventario continuam `memory_generated`.

### Fase F - Freeze
- [x] Criar `status-freeze-funcional-v17-saveflow-ui-dev-panel-2026-05-13.md`.
- [x] Atualizar `README.md`.
- [x] Atualizar `Cliente/nexus/docs/README.md`.
- [x] Atualizar `docs/godotmcp/runbook-saveflow-lite-rogue-agent.md`.
- [x] Atualizar `docs/skills/doc-first-godot-limboai-skill.md`.
- [ ] Commit/push apenas apos gate limpo.

## 6) Criterios De Aceite
1. Painel dev aparece no jogo sem erro.
2. Save `profile_0` funciona por `NexusSaveAuthority`.
3. Load `profile_0` funciona por `NexusSaveAuthority`.
4. Refresh summary funciona por `NexusSaveAuthority`.
5. Nenhum script do painel chama SaveFlow direto.
6. A dagger continua preservando `ItemStack.item_id/properties`.
7. Adapter continua `memory_generated`.
8. Runner temporario, se usado, nao fica em cena final.
9. Nenhum script de combate/BT/HSM e alterado.

## 7) Telemetria Obrigatoria
Eventos do painel:
1. `saveflow_dev_panel_save_clicked`
2. `saveflow_dev_panel_load_clicked`
3. `saveflow_dev_panel_summary_clicked`
4. `saveflow_dev_panel_status_updated`

Eventos esperados da authority:
1. `save_authority_save_requested`
2. `save_authority_save_completed`
3. `save_authority_load_requested`
4. `save_authority_load_completed`

Payload minimo:
1. `slot_id`
2. `ok`
3. `reason`
4. `item_id`
5. `rolled_damage`
6. `rolled_dex_bonus`

## 8) Riscos E Mitigacoes
1. **Risco: UI dev virar caminho paralelo ao runtime real.**
   - Mitigacao: painel chama somente `NexusSaveAuthority`.
2. **Risco: poluir UI final com ferramenta dev.**
   - Mitigacao: manter em `cenas/debug` ou claramente marcado como dev panel.
3. **Risco: painel acoplar em inventario diretamente.**
   - Mitigacao: painel consulta estado via authority/bridge apenas para status, sem mutar inventario.
4. **Risco: regressao visual no HUD.**
   - Mitigacao: painel simples, pequeno, desativavel se necessario.
5. **Risco: mexer em combate por conveniencia.**
   - Mitigacao: escopo proibe BT/HSM/combat core.

## 9) Resultado Da Sprint
V17 esta funcional e congelada. O projeto agora possui:
1. `res://cenas/debug/saveflow_dev_panel.tscn`;
2. `res://Scripts/debug/saveflow_dev_panel.gd`;
3. `res://Scripts/debug/saveflow_dev_panel_smoke_runner.gd` como runner de QA manual;
4. `SaveFlowDevPanel` instanciado em `res://cenas/mundo.tscn`;
5. telemetria de Save, Load, Summary e Status;
6. gate MCP final sem runner temporario salvo na cena.

Evidencia validada:
1. `saveflow_dev_panel_summary_clicked`;
2. `saveflow_dev_panel_status_updated command=summary ok=true`;
3. `saveflow_dev_panel_save_clicked`;
4. `save_authority_save_completed ok=true`;
5. `saveflow_dev_panel_load_clicked`;
6. `save_authority_load_completed ok=true`;
7. `saveflow_dev_panel_smoke_result ok=true`;
8. `inventory_equipment_adapter_resolved resource_path=memory_generated`.

O painel chama somente `NexusSaveAuthority`, nao chama SaveFlow direto, nao muta inventario diretamente e nao altera combate, BT ou HSM.
