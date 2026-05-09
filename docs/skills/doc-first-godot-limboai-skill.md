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
- [ ] Prova data-driven registrada: mesma logica, perfis `.tres` diferentes e telemetria mostrando comportamento distinto.

Fontes base:
- Godot: https://docs.godotengine.org/en/stable/
- LimboAI: https://limboai.readthedocs.io/en/stable/
