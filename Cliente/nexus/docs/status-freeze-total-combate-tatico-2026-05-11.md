# Status Freeze Total - Combate Tatico BT/LimboAI

Data: 2026-05-11
Status: CONGELADO
Escopo: combate tatico local no Godot, BT/HSM, stamina, kiting, input de combate, NavMesh da arena de teste.

## 1) Decisao de freeze
O estado atual esta aprovado como baseline funcional. A prioridade deixa de ser refatorar o combate tatico e passa a ser preservar o comportamento validado.

Qualquer mudanca futura em input, BT, HSM, stamina, motor, NavigationAgent2D, cenas de combatentes ou NavMesh deve ser tratada como alteracao de comportamento e precisa de:

1. leitura deste freeze;
2. teste MCP em `res://cenas/mundo.tscn`;
3. telemetria comprovando que o contrato de combate continua valido;
4. atualizacao de docs se o baseline mudar.

## 2) Contrato funcional aprovado
1. BT decide comportamento tatico.
2. LimboHSM executa ataque, animacao e estados punitivos.
3. PlayerMotor move e para fisicamente o ator.
4. Controller apenas despacha intencoes de input.
5. Stamina regula ataque e reposicionamento.
6. CombatActionData e CombatPerceptionProfile continuam sendo a fonte de tuning por dados.

## 3) Comportamentos aprovados
1. Spam de clique de ataque em alvo hostile nao cancela kiting automatico.
2. Clique no chao continua cancelando intencao de combate e funciona como escape manual.
3. Se o ator nao tem stamina suficiente para o ataque real equipado, a BT considera baixa stamina e entra em comportamento tatico.
4. Atores nao devem ficar presos na zona morta entre "sem stamina para atacar" e "nao esta cansado o suficiente para fugir".
5. Kiting automatico usa ponto calculado para longe do alvo e delega a rota ao NavigationAgent2D.
6. Reposicionamento tatico termina com orientacao para o alvo e janela de respiro quando a arvore assim compoe.
7. Brute, Light, Wildcat e Player compartilham o core de ator; diferencas devem continuar vindo de dados/cena.

## 4) Ajustes de cena aprovados pelo QA
As seguintes alteracoes locais fazem parte do baseline atual e nao devem ser revertidas automaticamente:

1. NavMesh/NavPolygon da arena de teste ajustado manualmente.
2. Regen de stamina ajustado para forcar ciclos de reposicionamento sem stamina.
3. Animacoes `Walk_Unarmed_*` do Player com loop desativado conforme validacao visual atual.
4. Ajustes de stamina/health/collision em cenas usados para deixar a batalha mais performatica e testavel.
5. Tuning atual do Brute deve ser preservado enquanto o QA estiver aprovando o ritmo da luta.

## 5) Arquivos-chave do baseline
Scripts:
1. `Scripts/player/player_controller.gd`
2. `Scripts/player/player_motor.gd`
3. `Scripts/ai/tasks/bt_is_stamina_low.gd`
4. `Scripts/ai/tasks/bt_get_kite_position.gd`
5. `Scripts/ai/tasks/bt_move_to_blackboard_pos.gd`
6. `Scripts/ai/tasks/bt_request_attack.gd`
7. `Scripts/actors/actor_8dir_limbo.gd`

Arvores e cenas:
1. `ai/trees/player/player_combat_bt.tres`
2. `ai/trees/npc/wildcat_look_wander_bt.tres`
3. `cenas/mundo.tscn`
4. `cenas/player.tscn`
5. `cenas/enemies/hostile_enemy_light.tscn`
6. `cenas/enemies/hostile_enemy_brute.tscn`

Dados:
1. `configs/combat/player_light_attack.tres`
2. `configs/combat/wildcat_claw_attack_v1.tres`
3. `configs/combat/hostile_light_attack_v1.tres`
4. `configs/combat/hostile_brute_attack_v1.tres`
5. `configs/combat/profiles/player_melee_baseline_v1.tres`
6. `configs/combat/profiles/hostile_light_profile_v1.tres`
7. `configs/combat/profiles/hostile_brute_profile_v1.tres`

## 6) Gates de regressao obrigatorios
Cena padrao: `res://cenas/mundo.tscn`

1. `open_scene(res://cenas/mundo.tscn)`
2. `play_scene(current)`
3. Testar spam de clique de ataque no Brute.
4. Testar clique no chao durante combate para confirmar cancelamento manual.
5. Testar baixa stamina ate observar reposicionamento.
6. Confirmar que o ator volta a atacar depois de recuperar stamina suficiente.
7. `get_godot_errors` sem parse/runtime novo.

Eventos esperados:
1. `intent_dispatched`
2. `target_acquired`
3. `low_stamina_entered`
4. `attack_task_blocked` com `insufficient_stamina` quando aplicavel
5. `attack_started`
6. `attack_commit`
7. `attack_finished`
8. `hit_confirmed`
9. `target_died` quando a luta concluir

## 7) O que nao mexer sem evidencia
1. Nao reintroduzir cancelamento de combate em clique de ataque.
2. Nao trocar o criterio de baixa stamina para threshold percentual fixo.
3. Nao voltar clamp manual agressivo para NavMesh no motor/tarefa de kiting.
4. Nao editar `.tres` de BT por texto/regex.
5. Nao limpar alvo de combate em Stagger/Exhaustion.
6. Nao transformar task atomica em script monolitico com timer, loop e decisao ao mesmo tempo.

## 8) Dividas tecnicas aceitas no freeze
Estas dividas nao bloqueiam o freeze porque o comportamento esta aprovado:

1. `bt_get_kite_position.gd` ainda usa distancia hardcoded `160.0`; recomendacao futura e migrar para dado/export sem mudar comportamento.
2. `bt_is_stamina_low.gd` ainda expoe `threshold_ratio`, embora a logica atual use `has_stamina_for_attack()`.
3. `bt_move_to_blackboard_pos.gd` para o motor no `_exit()`; manter enquanto nao houver evidencia de micro-paradas regressivas.
4. Algumas alteracoes de tuning/cena estao no working tree e devem ser comitadas de forma consciente quando o usuario pedir fechamento Git.

## 9) Resultado do freeze
Estado aprovado para continuar desenvolvimento em cima deste baseline.
Proxima etapa recomendada: registrar o freeze no Git e so entao abrir nova frente de trabalho.
