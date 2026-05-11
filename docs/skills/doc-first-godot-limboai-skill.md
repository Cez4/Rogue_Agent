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
12. Em roadmap pos-freeze, respeitar a ordem: Health Regen Data-Driven v1 antes de Actor8Dir Facade Slimming v1.
13. Nao misturar feature de Health Regen com refactor amplo de `Actor8DirLimbo` no mesmo ciclo.

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
- [ ] A sprint atual permite mexer em `Actor8DirLimbo`? Se Health Regen ainda nao fechou, limitar a mudancas minimas de contrato.

Fontes base:
- Godot: https://docs.godotengine.org/en/stable/
- LimboAI: https://limboai.readthedocs.io/en/stable/
