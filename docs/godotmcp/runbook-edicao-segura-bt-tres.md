# Runbook: Edição Segura de Árvores de Comportamento (.tres) no LimboAI

## Contexto e Risco Crítico
Arquivos `.tres` de árvores de comportamento do LimboAI (`BehaviorTree`) contêm serialização profunda, arrays indexados estritamente e UUIDs internos gerados pela engine do Godot.
**Tentar editar ou fazer refatoração (Replace Text) manual em arquivos `.tres` via ferramentas de texto/regex causará a corrupção irreversível da árvore**, apagando ramos inteiros (como os nós de Ataque).

## A Única Metodologia Segura para Agentes IA
Quando houver necessidade de inserir, reorganizar ou deletar nós de uma árvore `BT` de forma autônoma pelo console, **é estritamente obrigatório** utilizar a ferramenta `mcp_godot-mcp_execute_editor_script`.

### Passo a Passo (Editor Scripting)
Em vez de manipular o texto, você ordenará que a própria engine do Godot monte a árvore e salve o arquivo via API nativa:

1. Use o método `ResourceLoader.load()` para carregar a árvore base, ou crie uma do zero com `BehaviorTree.new()`.
2. Instancie nós atômicos via GDScript (ex: `var limit = BTTimeLimit.new()`).
3. Instancie e acople tasks customizadas (ex: `var my_task = load("res://Scripts/ai/tasks/minha_task.gd").new()`).
4. Monte a hierarquia perfeitamente usando `.add_child()`.
5. Salve o arquivo na disco usando `ResourceSaver.save(bt, path)`.

### Exemplo Prático de Script de Editor Seguro
```gdscript
func run():
	var bt_path = "res://ai/trees/player/player_combat_bt.tres"
	var bt = BehaviorTree.new()
	var root = BTDynamicSelector.new()
	bt.root_task = root
	
	# Criando um ramo modular seguro
	var seq = BTSequence.new()
	seq.custom_name = "Meu Ramo Tatico"
	
	var time_limit = BTTimeLimit.new()
	time_limit.time_limit = 1.5
	time_limit.add_child(load("res://Scripts/ai/tasks/bt_move_to_blackboard_pos.gd").new())
	
	seq.add_child(time_limit)
	seq.add_child(load("res://Scripts/ai/tasks/bt_stop_movement.gd").new())
	
	var wait = BTRandomWait.new()
	wait.min_duration = 1.0
	wait.max_duration = 1.8
	seq.add_child(wait)
	
	root.add_child(seq)
	ResourceSaver.save(bt, bt_path)
	return "Sucesso"
```

### Regra de Ouro
**Nunca substitua pedaços de um arquivo `.tres` como se fosse um `.gd` ou `.txt`. Use o motor do Godot a seu favor.**

## Contrato pos-freeze do combate tatico (2026-05-11)
1. `player_combat_bt.tres` e a arvore dourada de homologacao.
2. Tasks customizadas devem continuar atomicas.
3. Tempo, repeticao e cadencia devem ficar em decorators nativos (`BTTimeLimit`, `BTRandomWait`, cooldowns), nao em loops internos de task.
4. Nao reintroduzir task monolitica de baixa stamina que calcula, move, espera e decide tudo no mesmo script.
5. Alteracao em ramo de kiting deve provar:
   - spam de clique de ataque nao cancela recuo;
   - clique no chao cancela combate;
   - ator sem stamina para atacar reposiciona;
   - ator volta a atacar apos recuperar stamina suficiente.

## Ordem de roadmap relacionada a BT/Actor
1. Health Regen Data-Driven v1 esta congelado e nao alterou estrutura das arvores BT.
2. Actor8Dir Facade Slimming v1 e a sprint ativa e deve preservar estrutura BT, salvo bug comprovado e editado via Godot/editor API.
3. O refactor de `Actor8DirLimbo` deve manter wrappers publicos usados por BT/HSM/Controller ate haver migracao validada em MCP.
4. Actor Export/Profile Organization v1 nao deve alterar BT/HSM para limpar exports sociais/wander/emote.
5. A Fase E dessa sprint deve comecar por auditoria E0; remocao de exports so depois de cobertura total de `social_profile` ou fallback documentado.

## Congelamento Actor8Dir Slimming bloco 1
1. O bloco 1 (`ActorCombatResourceRuntime`) esta congelado no commit `fb1e408`.
2. Se logs mostrarem spam de `kiting_started`, tratar primeiro como ruido de telemetria/BT.
3. Nao editar `.tres` por texto para corrigir esse ruido.
4. Nao alterar kiting, stamina, movimento ou `bt_move_to_blackboard_pos.gd` por causa desse ruido sem bug visual reproduzido.
5. Qualquer ajuste em emissao de telemetria de BT deve ser feito por task/script pequeno ou via Godot/editor API, com MCP e QA logo em seguida.
