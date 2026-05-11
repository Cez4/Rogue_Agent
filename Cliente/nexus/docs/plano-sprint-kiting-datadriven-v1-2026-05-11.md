# Plano Sprint - Kiting Data-Driven v1

Data: 2026-05-11
Status: PLANEJADA
Versao: v1
Escopo: migrar distancia de kiting de valor hardcoded para templates/data sem alterar o contrato BT atomico.

## 1) Objetivo
Remover o valor fixo `160.0` de `bt_get_kite_position.gd` e fazer o kiting consumir `low_stamina_kite_distance` dos templates `CombatActionData`.

O objetivo nao e mudar a arquitetura nem recriar comportamento. O objetivo e deixar o comportamento aprovado configuravel por dados.

## 2) Principio tecnico
Esta sprint deve preservar o padrao aprovado:

1. BT decide.
2. Task atomica calcula apenas uma coisa.
3. Movimento fica em `bt_move_to_blackboard_pos.gd`.
4. Tempo de execucao fica em `BTTimeLimit`.
5. Pausa/respiracao fica em `BTRandomWait`.
6. Reorientacao fica em `bt_face_combat_target_8dir.gd`.
7. Nenhuma task nova pode virar god script.

## 3) Problema atual
`bt_get_kite_position.gd` calcula a posicao de fuga com:

```gdscript
agent.global_position + away_dir * 160.0
```

Esse valor funcionou para estabilizar o comportamento, mas esta fora do contrato data-driven do projeto.

O projeto ja possui dados adequados:

1. `CombatActionData.low_stamina_kite_distance`
2. `Actor8DirLimbo.get_low_stamina_kite_distance()`
3. Templates `.tres` por archetype/arma

## 4) Decisao da sprint
Migrar para:

```gdscript
var kite_distance := agent.get_low_stamina_kite_distance()
var destination := agent.global_position + away_dir * kite_distance
```

Com fallback seguro somente para caso sem action data.

## 5) Fora de escopo
1. Nao mexer no `_exit()` de `bt_move_to_blackboard_pos.gd`.
2. Nao alterar BT estruturalmente nesta sprint.
3. Nao alterar `BTTimeLimit`, `BTRandomWait` ou ordem dos ramos.
4. Nao criar nova task composta.
5. Nao reativar clamp manual de NavMesh.
6. Nao alterar input de ataque/movimento.

## 6) Arquivos provaveis
Scripts:
1. `Scripts/ai/tasks/bt_get_kite_position.gd`
2. `Scripts/ai/tasks/bt_is_stamina_low.gd` (limpeza opcional do `threshold_ratio`)

Dados:
1. `configs/combat/player_light_attack.tres`
2. `configs/combat/hostile_brute_attack_v1.tres`
3. `configs/combat/hostile_light_attack_v1.tres`
4. `configs/combat/wildcat_claw_attack_v1.tres`

Docs:
1. `docs/combat-tuning-matrix-v1.md`
2. `docs/status-freeze-total-combate-tatico-2026-05-11.md` se o baseline mudar

## 7) Valores iniciais sugeridos
Estes valores sao ponto de partida, nao lei. O QA visual manda.

| Archetype | Arquivo | Valor inicial sugerido |
|---|---|---:|
| Player | `player_light_attack.tres` | 120.0-160.0 |
| Brute | `hostile_brute_attack_v1.tres` | 90.0-130.0 |
| Light | `hostile_light_attack_v1.tres` | 100.0-140.0 |
| Wildcat | `wildcat_claw_attack_v1.tres` | 100.0-150.0 |

Regra: se o feel aprovado atual deve ser preservado inicialmente, usar valores proximos de `160.0` e reduzir por archetype depois.

## 8) Plano de execucao
### Fase A - Preparacao
- [ ] Ler `status-freeze-total-combate-tatico-2026-05-11.md`.
- [ ] Confirmar que o jogo esta sem erro novo em `get_godot_errors`.
- [ ] Registrar valores atuais de `low_stamina_kite_distance`.

### Fase B - Dados
- [ ] Definir valores iniciais por archetype.
- [ ] Atualizar apenas `.tres` de `CombatActionData`.
- [ ] Nao alterar cena nesta fase.

### Fase C - Script atomico
- [ ] Alterar `bt_get_kite_position.gd` para consumir `agent.get_low_stamina_kite_distance()`.
- [ ] Manter a task limitada a calcular `destination` e gravar `output_pos_var`.
- [ ] Nao adicionar timer, loop, movimento ou decisao composta.
- [ ] Opcional: remover `threshold_ratio` de `bt_is_stamina_low.gd` se nao houver serializacao usando o campo.

### Fase D - Validacao MCP
- [ ] `open_scene(res://cenas/mundo.tscn)`.
- [ ] `play_scene(current)`.
- [ ] Testar Player com spam de clique no Brute.
- [ ] Testar clique no chao durante combate.
- [ ] Testar baixa stamina ate observar reposicionamento.
- [ ] Confirmar retorno ao ataque apos recuperar stamina.
- [ ] `get_godot_errors` sem parse/runtime novo.

### Fase E - Telemetria
- [ ] Confirmar `low_stamina_entered`.
- [ ] Confirmar `attack_task_blocked` com `insufficient_stamina` quando aplicavel.
- [ ] Confirmar `kiting_started`.
- [ ] Confirmar `kiting_ended`.
- [ ] Confirmar retorno a `attack_commit`.
- [ ] Confirmar ausencia de spam critico ou loop infinito.

### Fase F - Documentacao e Git
- [ ] Atualizar `combat-tuning-matrix-v1.md` com valores finais.
- [ ] Atualizar status/freeze se o feel aprovado mudar.
- [ ] Commit pequeno com escopo claro.
- [ ] Push e `rev-list --left-right --count origin/<branch>...HEAD = 0 0`.

## 9) Criterios de aceite
- [ ] Kiting nao usa distancia hardcoded em script.
- [ ] Distancia de kite vem de `CombatActionData`.
- [ ] Task continua atomica.
- [ ] BT continua compondo tempo, pausa, face e reengage.
- [ ] Player nao perde kiting por spam de clique.
- [ ] Clique no chao continua cancelando combate.
- [ ] NPCs continuam reposicionando quando sem stamina.
- [ ] Sem regressao visual de "passinhos curtos".
- [ ] Sem erro novo no Godot.
- [ ] Telemetria comprova ciclo: stamina baixa -> kiting -> retorno ao ataque.

## 10) Riscos e mitigacoes
Risco: valores atuais dos `.tres` ficarem curtos demais.
Mitigacao: iniciar com valores proximos ao feel aprovado e reduzir por archetype em ciclos de tuning.

Risco: virar god script novamente.
Mitigacao: proibir timer, loop, movimento e decisao composta dentro de `bt_get_kite_position.gd`.

Risco: regressao de kiting por reavaliacao da BT.
Mitigacao: nao alterar `_exit()` do movimento nem estrutura da arvore nesta sprint.

## 11) Tick final da sprint
- [ ] Sprint concluida
- [ ] Freeze atualizado se necessario
- [ ] Commit/push sincronizado
- [ ] QA aprovou feel de Player, Brute, Light e Wildcat
