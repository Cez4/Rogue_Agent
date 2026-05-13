# Status Freeze V14: Dynamic Loot & DEX System

Data: 2026-05-13
Status: aprovado em QA log/funcional e congelado. Total Freeze Executado.
Branch: `feat/dynamic-loot-dex-v1`
Base obrigatoria:
1. `status-freeze-funcional-v13-inventory-datadriven-core-2026-05-13.md`

## Resumo Executivo
O projeto agora possui um **Sistema de Loot Dinamico e RPG (DEX)** totalmente funcional, integrado nativamente ao **ExpressoBits Inventory System**. Toda a rolagem de atributos (Raridade, Dano, DEX Extra) ocorre em memoria no momento do drop, utilizando o `ItemDefinition` como molde e o `ItemStack` como a instancia unica.

## O Que Mudou Na Arquitetura
1. **O StatsComponent:** O Player agora possui um `StatsComponent` puro que gerencia sua destreza base (`base_dex`) e os bonus vindos de itens equipados (`bonus_dex`). O calculo e resolvido de forma limpa pelo `ActorStatsRuntime`.
2. **ItemGenerator (Host-Authoritative):** Um novo motor de rolagem de loot foi criado (`ItemGenerator.gd`). Ele le os ranges (ex: `damage_min_per_level`) direto das propriedades da Database do ExpressoBits e realiza a matematica de "roll".
3. **Instancias Unicas (ItemStack):** A magia do PoE/Diablo foi realizada populando o dicionario `properties` dentro do proprio `ItemStack` gerado pelo ExpressoBits (ex: `rolled_damage`, `rolled_dex_bonus`, `rarity`).
4. **Adapter Dinamico (Dano):** A formula de combate `Dano = rolled_damage + (final_dex * 0.5)` foi injetada no `NexusEquipmentAdapter`. O combate em si (Hitbox/Hurtbox/BT/HSM) permanece o mesmo do V11, garantindo que o Game Feel esta intacto, recebendo as municoes de dados atualizadas.

## O Desafio Tecnico (A Crise do ItemStack) e A Solucao
Durante esta sprint, o GDExtension do ExpressoBits provou ser estrito. A tentativa inicial de abstrair o `ItemDefinition` inserindo-o numa variavel fantasma `stack.item = definition` falhou miseravelmente, pois o C++ do addon apaga/ignora chaves fora de seu contrato, resultando em Null Reference no Adapter.

**A REGRA DE OURO (Runbook Atualizado):** 
O `ItemStack` so dispoe com seguranca as chaves: `item_id` (String), `amount` (int) e `properties` (Dictionary).
A resolucao de equipamentos e feita OBRIGATORIAMENTE extraindo `item_id` do stack e usando `database.get_item(item_id)` para obter o molde. Qualquer tentativa de burlar esse fluxo quebra o combate.

## Evidencia De QA
Durante QA real no Godot MCP (`mundo.tscn`), comprovamos:
1. Uma Adaga Rara (`weapon_dagger_starter`) Level 3 foi injetada usando a API segura (`apply_add_item`).
2. O Adapter extraiu com sucesso a `definition` atraves do `item_id`.
3. O `StatsComponent` identificou `10` DEX Base + `5` DEX Bonus da adaga rara.
4. O Dano calculado gerou `21.5` de `hit_confirmed` (14 de rolagem de arma + 7.5 do DEX).
5. O Brute foi alvejado com sucesso sem crash de motor.

## Contrato Congelado
O sistema base de inventario, drop e consumo de dados para combate tatico esta completamente blindado e estabilizado. Qualquer nova adicao de atributo (ex: `STR`, `INT`, `Crit Chance`) devera apenas plugar no `StatsComponent` e no `NexusEquipmentAdapter`, respeitando os dicionarios pre-estabelecidos.

## Addendum - Hotfix De Kiting/Stamina Runtime
Data: 2026-05-13
Status: validado via Godot MCP em `res://cenas/mundo.tscn`.

Regressao encontrada apos a migracao V13/V14:
1. O Player passou a resolver arma pelo `InventoryBridge`/ExpressoBits.
2. `ActorCombatProfileRuntime.get_combat_action_data()` ainda consultava `actor.equipment_loadout` legado diretamente.
3. Como o Player nao possui mais `equipment_loadout` legado nem `AttackState.action_data` ativo, a BT via `action_data == null`.
4. Com `action_data == null`, `has_stamina_for_attack()` retornava `true`, impedindo `bt_is_stamina_low` e `bt_request_attack` de entrarem corretamente no ramo de baixa stamina.
5. Sintoma visual: Player avancava/atacava repetidamente e nao fazia o ciclo de kiting aprovado.

Correcao oficial:
1. `ActorCombatProfileRuntime` agora usa `actor.get_equipment_loadout_runtime()`.
2. A mesma fonte runtime alimenta:
   - stamina requerida para ataque;
   - attack range;
   - attack stop distance;
   - parametros de kiting vindos do `CombatActionData` gerado pelo `NexusEquipmentAdapter`.
3. Hostis continuam funcionando pelo fallback aprovado de cena/`.tres`.

Evidencia MCP:
1. Antes do hotfix, `attack_stamina_cost.required` do Player aparecia como `20.0`.
2. Depois do hotfix, `attack_stamina_cost.required` voltou para `40.0`, respeitando `combat_stamina_cost = 20.0` e `combat_attack_stamina_budget_hits = 2.0`.
3. `bt_inrange_check` do Player passou a reportar `attack_stop_distance = 34.0`, derivado da adaga runtime do inventario.
4. Logs confirmaram `kiting_started` e `kiting_holding` do Player apos ataques, preservando o contrato tatico.
