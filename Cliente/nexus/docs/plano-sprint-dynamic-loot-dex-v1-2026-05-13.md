# Plano Sprint - Dynamic Loot & DEX System v1

Data: 2026-05-13
Status: PLANEJADA - DOC-FIRST
Baseline obrigatoria: `status-freeze-funcional-v13-inventory-datadriven-core-2026-05-13.md`
Branch sugerida: `feat/dynamic-loot-dex-v1`

## 1) Objetivo
Implementar um sistema de loot dinâmico e atributos RPG (DEX) adaptando a lógica do estudo `estudo_sistema_dex_itens_drop_data_driven_godot.md` para a nossa arquitetura nativa do **ExpressoBits Inventory System**, sem criar recursos duplicados no disco.

## 2) Decisão Técnica e Arquitetural
Não criaremos novas classes de `Resource` para moldes ou instâncias. Utilizaremos o motor que já validamos na sprint V13:

1. **O Molde (`ItemDefinition` do ExpressoBits):**
   - As propriedades base da database (`nexus_inventory_database_v1.tres`) receberão os **ranges (faixas) de rolagem**.
   - Exemplo: `damage_min_per_level`, `dex_max_per_level`, `min_level`, `max_level`.

2. **A Instância Real (`ItemStack` do ExpressoBits):**
   - O ExpressoBits permite que cada "stack" no inventário possua um dicionário próprio de `properties`.
   - Quando um monstro morrer ou um baú for aberto, o `ItemGenerator` criará um `ItemStack`, calculará a raridade, fará o "roll" numérico de dano e DEX, e salvará na instância: `stack.properties["rolled_damage"] = 11`, `stack.properties["rarity"] = "magic"`.

3. **Cálculo de Dano (O Combate):**
   - O `StatsComponent` existirá no Player para rastrear: `base_dex` + `bonus_dex` = `final_dex`.
   - O `NexusEquipmentAdapter` lerá o `rolled_damage` do ItemStack (se não houver, cai pro fallback base) e passará para a memória.
   - Fórmula de Dano: `Dano Final = rolled_damage + (final_dex * 0.5)`.

## 3) Conformidade Com Runbooks
- **Sem Text Replace em `.tres`:** A inserção das faixas numéricas de drop na Database do ExpressoBits será feita via *Godot Editor API* (Scripts) ou visualmente pelo Inspector.
- **Isolamento do Cliente:** Toda a rolagem de loot (`ItemGenerator`) e o instanciamento no inventário ocorrerão de forma Autoritativa (Host/Server), mantendo o multiplayer robusto.
- **Validação MCP:** Como lidaremos com modificadores numéricos no combate, cada etapa precisará testar se o Brute e o Player continuam registrando o dano correto na telemetria e visualmente com o Hitbreak.

## 4) Plano De Execução

### Fase A - Setup & Branch
- [x] Criar nova branch `feat/dynamic-loot-dex-v1`.
- [x] Validar inicialização MCP sem erros residuais da sprint anterior.

### Fase B - Stats Component
- [x] Criar `StatsComponent.gd` em `Scripts/stats/` (focado em `base_dex` e `bonus_dex`).
- [x] Acoplar `StatsComponent` ao `player.tscn`.
- [x] Criar funcionalidade no `Actor8DirLimbo` ou `ActorStatsRuntime` para consultar facilmente o DEX atual.

### Fase C - Configuração do "Molde" na Database
- [x] Via *Godot Editor Script*, adicionar os arrays numéricos na `weapon_dagger_starter` dentro do ExpressoBits:
  - `min_level`, `max_level`, `damage_min_per_level`, `damage_max_per_level`, `dex_min_per_level`, `dex_max_per_level`.

### Fase D - Item Generator System
- [x] Criar `ItemGenerator.gd` para ser uma factory Autoritativa.
- [x] Implementar `generate_item_stack(definition, monster_level)` -> Rola Raridade (Normal, Magic, Rare), Dano e DEX, retornando um `ItemStack` do ExpressoBits pronto e preenchido.

### Fase E - Refatoração do Adapter & Dano Dinâmico
- [x] Modificar o `NexusEquipmentAdapter` para ler `rolled_damage` e `rolled_dex_bonus` do `ItemStack`.
- [x] Quando o `InventoryBridge` notificar equipamento alterado, atualizar o `bonus_dex` do `StatsComponent`.
- [x] Fazer a injeção do cálculo de dano: `Dano = rolled_damage + (final_dex * 0.5)` e salvar no `CombatActionData` em memória gerado pelo Adapter.

### Fase F - Teste de Fogo (QA MCP) e Freeze
- [x] Fazer script de inject para dropar propositalmente uma *Rare Rusty Dagger* de level alto na mochila do Player.
- [x] Testar no MCP o player batendo num inimigo e conferir se a telemetria reporta o dano ampliado pelo DEX e Rolagem.
- [x] Gerar Status Freeze V14.

Resultado da Sprint:
A fase de DEX e Loot Dinamico foi implementada e exaustivamente testada no MCP. Durante o QA, descobrimos que a tentativa de injetar o `ItemDefinition` diretamente no stack resultava em falhas criticas devido a natureza GDExtension (C++) do ExpressoBits, que nao expoe a propriedade `item`, mas sim `item_id`. O `NexusEquipmentAdapter` foi blindado para sempre resolver via `item_id` -> `database.get_item()`. O QA final confirmou a telemetria processando `21.5` de dano num hit (Arma com dano base + rolagem rara + DEX bonus). Sprint perfeitamente finalizada.

## 5) Critérios De Aceite
1. Player ganha bônus de dano de acordo com a Raridade da arma e seus stats.
2. Nenhuma classe duplicada tipo `ItemBase.tres` obsoleta retorna ao projeto.
3. Telemetria comprova que armas diferentes (mesmo ID, mas rolagens diferentes) causam estragos diferentes.