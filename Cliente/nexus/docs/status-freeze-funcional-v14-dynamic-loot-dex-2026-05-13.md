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