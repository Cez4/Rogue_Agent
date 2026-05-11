# Recomendacoes Tech Lead Pos-Freeze

Data: 2026-05-11
Escopo: proximos passos recomendados apos congelamento do combate tatico atual.

## 1) Resumo executivo
O combate tatico esta funcional e aprovado. O sistema atingiu um ponto bom para congelar: Player, Brute, Light e Wildcat usam o mesmo core de arquitetura, a BT controla decisao, a HSM executa ataque/estados e o motor locomove sem ser interrompido por spam de input.

Agora o risco principal nao e falta de feature. O risco e regressao por ajuste pequeno em lugar errado.

## 2) Recomendacao principal
Manter o baseline atual intacto e evoluir em ciclos controlados:

1. primeiro consolidar docs e commit;
2. depois criar testes/smokes repetiveis;
3. so entao iniciar novo conteudo ou migracao multiplayer.

## 3) Prioridades tecnicas
1. Fechar Git do freeze atual.
2. Criar checklist de QA jogavel de 2 minutos para `mundo.tscn`.
3. Migrar somente dividas de baixo risco que nao alterem comportamento.
4. Expandir inimigos por dados, nao por scripts novos.
5. Comecar planejamento server-authoritative antes de adicionar sistemas grandes.

## 4) Dividas tecnicas recomendadas
### 4.1 Kiting data-driven
Problema: `bt_get_kite_position.gd` usa `160.0` hardcoded.

Recomendacao: manter visual atual, mas mover o valor para dado:

1. usar `agent.get_low_stamina_kite_distance()` quando existir;
2. garantir que o valor default preserve `160.0` no Player;
3. documentar valores por archetype em `combat-tuning-matrix-v1.md`.

Trade-off: a migracao melhora escala e tuning, mas pode mudar feel se os dados atuais nao forem preenchidos corretamente. Deve ser feita em commit pequeno e com teste A/B.

### 4.2 Limpeza de parametro morto
Problema: `bt_is_stamina_low.gd` ainda exporta `threshold_ratio`, mas nao usa.

Recomendacao: remover o export ou renomear a task para deixar claro que a checagem segue o custo real do ataque.

Trade-off: remover parametro pode afetar serializacao/inspector de BT. Fazer somente com Godot aberto e MCP limpo.

### 4.3 Stop no `_exit()` do MoveToBBPosition
Problema: `bt_move_to_blackboard_pos.gd` chama `stop_motor_movement()` em todo `_exit()`.

Recomendacao: nao mexer agora. Se aparecer micro-parada, separar saidas:

1. stop quando chegou no destino;
2. stop quando ramo tatico terminou explicitamente;
3. nao parar em aborto por reavaliacao de prioridade, se isso estiver causando tremor.

Trade-off: remover stop cedo demais pode causar sliding e overshoot. A mudanca precisa de telemetria e video/QA.

### 4.4 Smoke test automatizavel
Problema: a validacao atual depende muito de observacao manual.

Recomendacao: criar um smoke de runtime com logs esperados:

1. carregar `mundo.tscn`;
2. forcar alvo;
3. reduzir stamina;
4. observar `low_stamina_entered`;
5. observar reposicionamento;
6. observar retorno a `attack_commit`.

Trade-off: exige setup de teste no Godot, mas reduz retrabalho nas proximas sprints.

## 5) Regras para novas features
1. Nao criar nova feature de combate antes de congelar Git do baseline.
2. Nao adicionar magia/skill sem contrato de autoridade multiplayer.
3. Nao colocar regra de dano, cooldown ou custo no cliente como fonte final de verdade.
4. Nao criar script especifico por inimigo se o comportamento puder ser resolvido por profile/action.
5. Nao misturar tuning, refactor e feature no mesmo commit.

## 6) Caminho recomendado para multiplayer/MMO
O cliente atual pode continuar sendo prototipo jogavel, mas a arquitetura deve caminhar para:

1. cliente envia intencao;
2. servidor valida stamina, cooldown, alcance, alvo e hit;
3. servidor publica estado autoritativo;
4. cliente interpola/prediz apenas apresentacao;
5. telemetria registra divergencia entre intencao local e resultado autoritativo.

## 7) Observabilidade minima futura
Adicionar paineis/logs para:

1. stamina atual e stamina requerida para ataque;
2. BT branch ativa;
3. alvo atual e manual_lock;
4. distancia ate alvo e attack_stop_distance;
5. destino tatico atual;
6. motivo de attack_blocked;
7. estado atual da HSM.

## 8) Ordem sugerida das proximas entregas
1. Commit do freeze atual.
2. Smoke test manual documentado.
3. Limpeza de docs antigos que contradizem o freeze.
4. Migracao segura do kiting hardcoded para dado, preservando `160.0`.
5. Novo inimigo data-driven usando checklist.
6. Plano tecnico SpacetimeDB/server-authoritative para combate.

## 9) Criterio de sucesso
O projeto deve conseguir adicionar um novo inimigo melee sem tocar em `Actor8DirLimbo`, sem alterar tasks BT, sem editar script de motor e sem quebrar o comportamento aprovado do Player.
