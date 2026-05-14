# Skill - Doc-First Godot + LimboAI (Obrigatorio)

Objetivo:
- Evitar implementacao com API incorreta.
- Garantir estudo continuo antes de alterar logica.

Regra:
1. Ler docs internos do projeto sobre o tema.
2. Ler docs oficiais Godot da classe/sistema usado.
3. Ler docs oficiais LimboAI da classe/sistema usado.
4. So depois implementar.
5. Validar no Godot MCP: `open_scene -> play_scene -> get_godot_errors`.
6. Registrar fontes no doc de estudo/status da entrega.
7. Toda logica nova deve ter teste funcional + telemetria/log comprovando o comportamento.
8. Em troca de fase, rodar auditoria de saude: docs internos + docs web oficiais + estado atual do codigo.
9. Em qualquer ajuste de combate, validar paridade de composicao da cena (Health + Hurtbox + AttackHitbox) em todos os combatentes.
10. Em bug de morte/respawn, verificar override no nodo instanciado da cena-mapa antes de alterar o script base.
11. Em fase de producao de inimigos, provar variacao por dados com pelo menos 2 inimigos reais antes de escalar conteudo.
12. Em roadmap pos-freeze, considerar Health Regen Data-Driven v1 como congelado antes de iniciar Actor8Dir Facade Slimming v1.
13. Durante Actor8Dir Facade Slimming v1, nao alterar Health Regen, Orb, BT/HSM, stamina ou kiting sem bug comprovado e novo QA.
14. Depois do bloco 1 de Actor8Dir Slimming, tratar spam de `kiting_started` como ponto congelado de telemetria antes de nova extracao estrutural.
15. Durante Actor Export/Profile Organization v1, nao remover exports sociais/wander/emote do `Actor8DirLimbo` antes da Fase E0 de auditoria de cobertura.
16. Antes de limpar tuning antigo, classificar cada valor como `fallback_real`, `override_aprovado`, `tuning_fantasma` ou `remover_depois`.
17. Se uma cena/ator ainda nao tiver `social_profile`, preservar os exports antigos como fallback real ate migracao/default aprovado.
18. Universal Hit Reaction / Hit Stun v1 esta congelado em camadas: V7 Player, V8 Wildcat e V9 Hostile Coverage. Preservar `HitReactionComponent` + profile `.tres` + estado HSM; nao criar logica exclusiva do Player, nao mover regra de dano para BT e nao reengordar `Actor8DirLimbo`.
19. Combat Clash / Parry Window v1 deve comecar por telemetria, nao por gameplay. O custo de stamina do ataque interrompido ja e a punicao base; dano extra de stamina/parry perfeito so entra depois de logs com fase do ataque e `attack_sequence_id`.
20. Combat Clash temporal D/D2 foi removido do runtime apos auditoria de feel. Nao reativar Parry unilateral nem `mutual_clash` global; qualquer Parry futuro deve nascer como `DefenseComponent`/`ParryComponent` por chance/atributo em `.tres`.
21. Hitbreak Combat Feedback v1 esta congelado em V11: feedback visual no atacante que causa interrupcao por `hit_reaction`, sem alterar dano/stamina/BT/HSM. Player, Wildcat, Brute, Base e Light estao integrados/aprovados. Usar `CombatFeedbackComponent` + `CombatFeedbackProfile`, shader/material duplicado em runtime e telemetria `hitbreak_success`.
22. Parry ficou para depois do V11. Nao implementar ou reativar Parry/Clash no escopo de Hitbreak Feedback; abrir sprint futura com `DefenseComponent`/`ParryComponent` data-driven por chance/atributo.
23. Apos QA D2, Player/Wildcat voltaram para observer. Nao reativar Clash/Parry global automatico sem novo plano de skill/estado explicito e aprovacao visual.
24. Inventory ExpressoBits Spike v1 esta congelado em V12. Usar `res://addons/inventory-system/` como core oficial, tratar `inventory-system-demos` apenas como referencia e manter cliente como emissor de intents.
25. Inventory Data-Driven Core v1 esta congelado em V13. O Player nao deve depender de `.tres` antigos de equipamento; a database ExpressoBits e a fonte oficial, e `NexusEquipmentAdapter` monta `EquipmentLoadout`, `WeaponData` e `CombatActionData` em memoria.
26. Dynamic Loot & DEX v1 esta congelado em V14. `ItemStack` deve ser lido por `item_id` + `properties`; buscar o molde com `inventory.database.get_item(item_id)`. Nunca usar `stack.item` nem inserir stack com `.append()`.
27. Runtime de combate do Player deve consumir `actor.get_equipment_loadout_runtime()`. Nao voltar a ler `actor.equipment_loadout` diretamente em stamina, range, stop distance ou kiting, pois isso quebra a ponte V13/V14.
28. Ao trabalhar com ExpressoBits, evitar nomes genericos que colidem com classes nativas da GDExtension; `Slot` local deve ser `EquipmentSlot` ou nome prefixado.
29. SaveFlow Lite Persistence v1 deve ser doc-first e host-authoritative: SaveFlow orquestra save/load, mas nao substitui ExpressoBits, `NexusInventoryAuthority`, `NexusInventoryBridgeComponent` nem `NexusEquipmentAdapter`.
30. Ao salvar inventario com SaveFlow, usar fonte customizada (`SaveFlowDataSource`) e preservar somente `ItemStack.item_id`, `amount` e `properties`; nunca salvar `ItemDefinition`, nunca usar `stack.item` e nunca varrer o Player inteiro com `NodeSource` para persistir inventario.
31. Load valido de inventario deve acontecer antes dos `starting_items` ou marcar hidratacao explicita para impedir reroll da adaga starter. Prova obrigatoria: mesmo `rolled_damage`/`rolled_dex_bonus` apos save/load.
32. SaveFlow Lite Persistence v1 esta congelado em V15: `PlayerInventorySource` salva/carrega o inventario do Player via `NexusInventoryBridgeComponent`, o smoke aprovado gera `saveflow_inventory_smoke_result ok=true payload_restored=true`, e qualquer expansao para quests/world flags deve nascer em nova sprint.
33. SaveFlow Slots & Host Authority v1 esta congelado em V16: `NexusSaveAuthority` e a fachada obrigatoria para save/load de gameplay. Nenhum botao, cliente ou sistema de gameplay deve chamar SaveFlow direto para estado autoritativo.
34. SaveFlow UI Dev Panel v1 deve ser apenas cliente visual da `NexusSaveAuthority`: botoes de Save/Load/Summary nao podem chamar SaveFlow direto, nao podem mutar inventario diretamente e nao podem alterar BT/HSM/combat core.

Checklist rapido:
- [ ] Doc interno lido.
- [ ] Godot docs lido.
- [ ] LimboAI docs lido.
- [ ] Mudanca pequena e desacoplada.
- [ ] MCP validado sem erro novo.
- [ ] Telemetria/log do comportamento novo conferida.
- [ ] Fontes registradas no doc.
- [ ] Eixo de tuning registrado (quando aplicavel) e resultado anotado.
- [ ] Paridade de componentes de combate validada nas cenas alteradas.
- [ ] Em lifecycle, log confirma `target_died` -> `chase_canceled(reason=death)` -> `respawned` (se habilitado).
- [ ] Modificou UI ou Camera em combate? Utilize sistema de Trauma (Trauma-based Shake) em vez de Tweens simples para garantir "Game Feel" cumulativo e fluido.
- [ ] Implementou um estado de Crowd Control (Stun/Stagger/Exhaustion) no HSM? Confirme que ele paralisa o ator, mas **NÃO** executa `clear_combat_target()`, preservando a memória da BT para retomada de combate.
- [ ] A Task customizada do LimboAI é Atômica? (Ela faz apenas UMA coisa?). NUNCA crie lógica de timer ou loop de repetição dentro de um arquivo `.gd` de BTAction. Utilize os decorators visuais nativos (`BTTimeLimit`, `BTRandomWait`).
- [ ] Implementou UI flutuante ou rastros (Trails)? Confirme que existe uma lógica de "Snap" para igualar as variáveis secundárias ao valor principal em casos de Respawn ou Cura instantânea, evitando desincronização.
- [ ] Necessita alterar um arquivo `.tres` estruturalmente? Utilize estritamente `mcp_godot-mcp_execute_editor_script` para evitar corrupção de serialização.
- [ ] Prova data-driven registrada: mesma logica, perfis `.tres` diferentes e telemetria mostrando comportamento distinto.
- [ ] A fase atual permite mexer em `Actor8DirLimbo`? Se estiver na Actor8Dir Facade Slimming v1, manter wrappers publicos e validar cada bloco no MCP.
- [ ] O log tem spam de `kiting_started`? Nao avancar para Fase C nem mexer em kiting/movimento antes de decidir se e ruido aceito ou ajuste de telemetria.
- [ ] Na sprint Actor Export/Profile Organization v1, a Fase E comecou por E0/auditoria antes de qualquer remocao de export?
- [ ] Valores sociais/wander antigos em cenas migradas foram tratados como tuning fantasma e limpos somente via Godot/editor API?
- [ ] Implementou fuga (Kiting) ou navegação autônoma? Garanta que você NÃO está "spammando" o NavAgent com recalculações por frame (adicione threshold de distância) e NÃO está clampando coordenadas com `map_get_closest_point`.
- [ ] O Player continua compartilhando a mesma fundação biológica e social (Paridade The Sims-like) dos NPCs através de arquivos `.tres` idênticos?

- [ ] Implementou Hit Reaction/Hit Stun? Confirme que e componente copiavel para templates, usa profile `.tres`, entra pela HSM, preserva `combat_target`, tem telemetria e nao adiciona tuning/export no `Actor8DirLimbo`.
- [ ] Alterou Hit Reaction/Hit Stun apos os freezes V7/V8/V9? Confirme Player, Wildcat e hostis aprovados continuam tocando animacoes `TakeDamage_*`/`Dagger01_TakeDamage_*` inteiras, orientadas para a origem do golpe, com logs `hit_reaction_animation played=true duration=1.0`.
- [ ] Iniciou Combat Clash/Parry? Primeiro entregue telemetria `attack_phase_started`, `attack_window_opened`, `attack_window_closed`, `attack_interrupted` e correlacao por `attack_sequence_id`, sem alterar balance.
- [ ] Vai implementar Parry funcional? Crie sprint nova de `DefenseComponent`/`ParryComponent` por chance/atributo, preserve Hit Reaction/Hit Interrupt como core e valide por MCP/logs antes de commit.
- [ ] Vai implementar Hitbreak Feedback? Primeiro emita `hitbreak_success` sem visual, depois adicione `CombatFeedbackComponent` data-driven, validando material unico por ator e MCP/logs.
- [ ] Vai transformar Clash/Parry em gameplay? Garanta que seja skill/estado explicito, nao regra global automatica em todo ataque.
- [ ] Adicionou punicao de stamina em Clash/Parry? Confirme que ela nao duplica o custo ja pago pelo ataque interrompido e que veio de profile `.tres`, com QA aprovado.
- [ ] Vai mexer em inventario/craft/loot/equipamento? Confirme a fase correta: V12 para bridge/authority, V13 para dados de equipamento na database, V14 para loot/DEX. Sem copiar demo para runtime, sem cliente mutar estado oficial, sem `stack.item`, sem `.append()` em `inventory.stacks`.
- [ ] Vai mexer em stamina/range/kiting do Player? Confirme que a fonte de dados vem de `actor.get_equipment_loadout_runtime()` e que a telemetria mostra `attack_stamina_cost.required` coerente com a database ExpressoBits.
- [ ] Vai mexer em SaveFlow/persistencia? Confirme `docs/godotmcp/runbook-saveflow-lite-rogue-agent.md`, preserve host-authority, use `SaveFlowDataSource` para inventario e prove anti-reroll por telemetria.

Fontes base:
- Godot: https://docs.godotengine.org/en/stable/
- LimboAI: https://limboai.readthedocs.io/en/stable/
