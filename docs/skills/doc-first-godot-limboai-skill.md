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
- [ ] A sprint atual permite mexer em `Actor8DirLimbo`? Na Actor8Dir Facade Slimming v1, manter wrappers publicos e validar cada bloco no MCP.
- [ ] O log tem spam de `kiting_started`? Nao avancar para Fase C nem mexer em kiting/movimento antes de decidir se e ruido aceito ou ajuste de telemetria.
- [ ] Na sprint Actor Export/Profile Organization v1, a Fase E comecou por E0/auditoria antes de qualquer remocao de export?
- [ ] Valores sociais/wander antigos em cenas migradas foram tratados como tuning fantasma e limpos somente via Godot/editor API?
- [ ] Implementou fuga (Kiting) ou navegação autônoma? Garanta que você NÃO está "spammando" o NavAgent com recalculações por frame (adicione threshold de distância) e NÃO está clampando coordenadas com `map_get_closest_point`.
- [ ] O Player continua compartilhando a mesma fundação biológica e social (Paridade The Sims-like) dos NPCs através de arquivos `.tres` idênticos?

- [ ] Implementou Hit Reaction/Hit Stun? Confirme que e componente copiavel para templates, usa profile `.tres`, entra pela HSM, preserva `combat_target`, tem telemetria e nao adiciona tuning/export no `Actor8DirLimbo`.
- [ ] Alterou Hit Reaction/Hit Stun apos os freezes V7/V8/V9? Confirme Player, Wildcat e hostis aprovados continuam tocando animacoes `TakeDamage_*`/`Dagger01_TakeDamage_*` inteiras, orientadas para a origem do golpe, com logs `hit_reaction_animation played=true duration=1.0`.

Fontes base:
- Godot: https://docs.godotengine.org/en/stable/
- LimboAI: https://limboai.readthedocs.io/en/stable/
