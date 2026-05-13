# Plano Sprint - Inventory Data-Driven Core v1

Data: 2026-05-13
Status: PLANEJADA - DOC-FIRST
Baseline obrigatorio: `status-freeze-funcional-v12-inventory-expresso-spike-2026-05-13.md`
Branch sugerida: `feat/inventory-datadriven-core-v1`

## 1) Objetivo
Tornar o addon **ExpressoBits Inventory System** a *Única Fonte da Verdade* (Single Source of Truth) para todos os dados de itens, armamentos, armaduras e consumíveis do projeto. 

Remover o atual débito técnico/gambiarra (duplicidade entre o plugin e os antigos `.tres`) e refatorar o `NexusEquipmentAdapter` para que o Godot construa os dados de combate puramente em memória a partir da Database oficial do inventário.

## 2) Decisao Tecnica e Arquitetural
**O Problema Atual:** O combate do LimboAI (BT/HSM) exige classes fortemente tipadas (`WeaponData`, `CombatActionData`). Se tentarmos forçar a BT a ler dicionários nativos (`properties`) do plugin ExpressoBits, quebraremos dezenas de referências fortemente acopladas do combate V11.

**A Solução Elegante (Adapter em Memória):**
1. Manteremos os scripts `WeaponData.gd` e `CombatActionData.gd` no projeto. Eles atuarão como "Contêineres de Runtime".
2. Em vez do inventário apontar para um arquivo salvo no disco (ex: `res://.../dagger.tres`), as `properties` do `ItemDefinition` no ExpressoBits possuirão as estatísticas reais (dano, alcance, stamina_cost).
3. O `NexusEquipmentAdapter` vai ler essas `properties` e instanciar um `WeaponData.new()` com um `CombatActionData.new()` preenchido na mosca (on the fly).
4. O `EquipmentLoadout` do Player receberá esses objetos em memória. A BT/HSM de combate continuará lendo essas classes, totalmente alheias à origem dos dados.

## 3) Conformidade Com Runbooks E Segurança
1. **Regra de Ouro (Segurança .tres):** A inserção das propriedades no banco de dados do ExpressoBits (`nexus_inventory_database_v1.tres`) deve ser feita via *Godot/Editor API* ou interface gráfica do addon. É estritamente proibido editar o arquivo usando ferramentas de substituição de texto (Regex/Replace Text).
2. **Godot MCP Obrigatório:** Nenhuma fase avança sem o checklist MCP: `open_scene` -> `play_scene` -> `get_godot_errors` -> Confirmação da Telemetria.
3. **Isolamento de Cenas:** O combate (animações, state machines) não deve sofrer alterações em seus scripts base. A mudança é puramente no fornecimento de munição de dados.

## 4) Propriedades Mapeadas Para ExpressoBits
O dicionário `properties` dos equipamentos precisará comportar estas chaves (entre outras, conforme a classe instanciada):
- `combat_damage` (float)
- `combat_stamina_cost` (float)
- `combat_windup_sec` (float)
- `combat_active_sec` (float)
- `combat_recover_sec` (float)
- `combat_cooldown_sec` (float)
- `combat_attack_range` (float)
- `combat_knockback_force` (float)
- `combat_knockback_duration_sec` (float)

## 5) Plano De Execucao

### Fase A - Setup & Branch
- [ ] Criar nova branch `feat/inventory-datadriven-core-v1`.
- [ ] Garantir que o Godot MCP inicializa sem erros no mapa `mundo.tscn`.

### Fase B - População Data-Driven na Database
- [ ] Via Godot Editor Script, popular todas as estatísticas reais de combate (dano, stamina, tempos) dentro do dicionário `properties` do item `weapon_dagger_starter` no `nexus_inventory_database_v1.tres`.
- [ ] Popular estatísticas para `armor_cloth_starter` e `necklace_wooden_charm_starter`.
- [ ] Validar a extração dos dados usando script de teste isolado no MCP.

### Fase C - Refatoração do Adapter
- [ ] Atualizar o script `NexusEquipmentAdapter.gd`.
- [ ] Remover a lógica de leitura do `EQUIPMENT_RESOURCE_PROPERTY` (load de arquivo).
- [ ] Adicionar lógica de parse dinâmico: `_build_weapon_data(properties)`, `_build_combat_action_data(properties)`, `_build_armor_data(properties)`.
- [ ] O Adapter agora deve retornar recursos criados em memória (`WeaponData.new()`) com base nos dicionários.

### Fase D - Ligação no Player & Combate (O Teste de Fogo)
- [ ] Forçar o `EquipmentLoadout` do Player a utilizar o output do novo Adapter (gerado a partir do bridge do inventário).
- [ ] Rodar `mundo.tscn` no MCP.
- [ ] Observar telemetria: verificar se `attack_started`, consumo de stamina e `hit_confirmed` com dano ocorrem perfeitamente usando as variáveis em memória.
- [ ] Não devem surgir `NullReferenceExceptions` na HSM.

### Fase E - Limpeza Geral
- [ ] Com o combate provado e funcional com o Adapter de Memória, excluir os antigos arquivos de configuração que ficaram obsoletos:
  - `configs/items/weapons/dagger_starter.tres`
  - `configs/items/armors/cloth_starter.tres`
  - `configs/items/necklaces/wooden_charm_starter.tres`
- [ ] Limpar antigas menções de preload desses recursos caso existam.
- [ ] Rodar validação final no mapa inteiro para certificar o fim do drift.

### Fase F - Freeze e QA Final
- [ ] Registrar documentação final.
- [ ] Garantir telemetria intacta.
- [ ] Preparar documento de Freeze V13.

## 6) Critérios De Aceite
1. O combate do LimboAI funciona sem arquivos `.tres` de armas antigos.
2. O Adapter constrói objetos `EquipmentData` e herdeiros com perfeição.
3. Não há erros novos no `get_godot_errors`.
4. Os atributos de dano/stamina lidos no momento do combate são idênticos aos cadastrados no banco do ExpressoBits.
5. `inventory-system-demos` continua ignorado pelo Git.