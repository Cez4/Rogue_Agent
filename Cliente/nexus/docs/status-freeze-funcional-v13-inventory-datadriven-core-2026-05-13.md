# Status Freeze V13: Inventory Data-Driven Core

Data: 2026-05-13
Status: aprovado em QA log/funcional e congelado.
Branch: `feat/inventory-datadriven-core-v1`
Base obrigatoria:
1. `status-freeze-funcional-v12-inventory-expresso-spike-2026-05-13.md`

## Resumo Executivo
O projeto eliminou oficialmente o débito técnico de duplicidade de itens de equipamento. O plugin **ExpressoBits Inventory System** ascendeu a *Única Fonte de Verdade* (Single Source of Truth) para o balanço de armamentos e armaduras do combate. Arquivos legados (`.tres`) foram deletados para eliminar o risco de drift de dados.

## O Que Mudou Na Arquitetura
1. **Atributos Migrados:** Estatísticas vitais de combate (`damage`, `stamina_cost`, `knockback`, etc) agora vivem como variáveis dentro do dicionário `properties` de cada item dentro da `nexus_inventory_database_v1.tres`.
2. **O Novo Adapter:** `NexusEquipmentAdapter` deixou de carregar recursos do disco. Agora ele possui parsers puros (`_build_weapon_data()`, etc) que geram as antigas classes (`WeaponData`, `CombatActionData`) inteiramente em memória e injetam no `EquipmentLoadout`.
3. **Compatibilidade LimboAI / HSM Preservada:** O Player, NPCs, State Machines e Behavior Trees não sofreram sequer uma quebra de refatoração. Eles recebem os objetos instanciados pelo Adapter e acham que os arquivos originais ainda existem.
4. **Limpeza Cirúrgica:** `dagger_starter.tres`, `cloth_starter.tres` e `wooden_charm_starter.tres` foram definitivamente removidos do disco. 

## Evidencia De QA
Durante QA real no Godot MCP (`mundo.tscn`), comprovamos:
1. **O Fim do Acoplamento ao Disco:** Com os arquivos de equipamento apagados, o Player carregou a sua Adaga Inicial vinda puramente das entranhas do ExpressoBits. 
2. **Combate Preservado:** A telemetria acusou a extração perfeita das propriedades:
   - `attack_stamina_cost` de `20.0` e `hit_confirmed` com dano `1.0`.
   - Hitbreak, Knockback de `200.0` e Kiting funcionaram sem gerar nulo nas BTs ou na HSM.

## Contrato Congelado
1. Novas armas ou armaduras *NÃO DEBEM* ser criadas como recursos individuais na pasta de `configs/items/...`. Elas devem ser configuradas exclusivamente na interface do banco de dados do ExpressoBits ou populadas via Godot Editor API.
2. O Adapter é o tradutor oficial do projeto. Se uma nova estatística de combate surgir (ex: *Lifesteal*, *Crit Chance*), ela deve ser mapeada no banco do inventário e traduzida dentro do `NexusEquipmentAdapter`.

## Estado Atual Apos V13
O *Game Feel* provou-se flexível à abstração de memória. Estamos totalmente desacoplados dos arquivos base e possuímos um sistema 100% Data-Driven usando o addon. Próxima fronteira recomendada: Lógica ativa de consumíveis e inventário de interface UI.