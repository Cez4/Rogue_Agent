# Estudo LimboAI (Godot 4)

Baseado na documentação oficial do LimboAI (latest/stable), com foco prático para adoção no projeto.

## 1) O que é o LimboAI

LimboAI é um módulo/plugin para Godot 4 que combina:
- Behavior Trees (BT) para tomada de decisão modular.
- Hierarchical State Machines (HSM) para organização de estados em camadas.

Ele oferece editor visual, depuração e suporte para extensão via GDScript.

## 2) Conceitos centrais

### 2.1 Behavior Tree

- Estrutura hierárquica de tarefas.
- Fluxo é definido por nós de controle (ex.: `BTSequence`, `BTSelector`) e nós folha (ações/condições).
- Cada task retorna um status:
  - `SUCCESS`
  - `RUNNING`
  - `FAILURE`

### 2.2 BTPlayer

`BTPlayer` é o nó que instancia e executa um `BehaviorTree` em runtime.

Pontos importantes:
- `agent_node` por padrão aponta para o pai (`..`).
- Recebe referências de agent, blackboard e scene root ao inicializar.
- Pode operar em modos de update (`idle`, `physics`, `manual` dependendo da versão).

### 2.3 Blackboard

Blackboard é armazenamento chave/valor para compartilhamento de dados entre tasks/estados.

Pontos importantes:
- Cada instância de BT/HSM tem seu Blackboard.
- Existe cadeia de escopo (parent scope), permitindo herança de dados.
- Escopos novos podem surgir com `BTNewScope`, `BTSubtree`, ou estados/HSM com plano de blackboard.

### 2.4 LimboHSM e LimboState

`LimboHSM` é uma máquina de estados hierárquica baseada em eventos.

- Um `LimboHSM` é também um `LimboState` (permite hierarquia de HSM).
- Estados derivados de `LimboState` podem sobrescrever:
  - `_setup()`
  - `_enter()`
  - `_update()`
  - `_exit()`
- Transições por evento via `add_transition(...)`.

## 3) Ligação entre HSM e BT (ponto crítico)

Quando usar BT dentro de estado (ex.: `BTState`) ou combinar com HSM:
- use `BlackboardPlan` e **mapping de variáveis** para conectar dados entre escopos.
- mapping é recomendado porque mantém variáveis ligadas como estado único em runtime (sem polling manual).

## 4) Custom tasks (GDScript)

Diretriz oficial:
- tasks customizadas, por padrão, em `res://ai/tasks`.
- categorias vêm da estrutura de subpastas.

Base classes:
- `BTAction`
- `BTCondition`
- `BTDecorator`
- `BTComposite`

Estrutura mínima típica:
- `_tick(delta)` obrigatório para execução.
- opcionais: `_setup`, `_enter`, `_exit`, `_generate_name`, `_get_configuration_warnings`.

## 5) Arquitetura recomendada para escalar

Para manter IA sustentável em projeto grande:

1. Separar decisão de execução
- BT decide "o que fazer".
- Sistemas/nós de movimento/combate executam "como fazer".

2. Blackboard tipado por convenção
- definir nomes padrão de variáveis (ex.: `target`, `desired_velocity`, `attack_cooldown`).
- documentar contrato por task.

3. Reuso de árvores
- tratar BehaviorTree como recurso reutilizável.
- overrides por `Blackboard Plan` no `BTPlayer` por cena/entidade.

4. HSM para macroestado
- Ex.: `Exploration`, `Combat`, `Flee` no HSM.
- Cada macroestado pode acionar BT diferente.

5. Observabilidade
- logs de transição de estado/evento.
- métricas de taxa de ticks/failures por task crítica.

## 6) Limitações e cuidados

- Mudanças de versão podem alterar assinatura de métodos/propriedades.
- `agent_node` e inicialização do BT devem ser definidos antes de runtime efetivo.
- Evitar lógica de gameplay pesada dentro de uma única task (quebrar em tarefas menores).

## 7) Checklist de adoção no projeto

1. Confirmar plugin carregado e classes disponíveis (`LimboHSM`, `BTPlayer`, `LimboState`).
2. Definir pasta de tasks (`res://ai/tasks`) e convenção de nomes.
3. Criar BlackboardPlan base por domínio (combate/movimento/percepção).
4. Criar HSM macro + BT por estado.
5. Adicionar logs de transição + validação em playtest.
6. Criar smoke test de IA (spawn + transições principais + ausência de erro no output).

## 8) Próximo passo prático sugerido

No seu projeto, a sequência robusta é:
1. Criar um `LimboHSM` no `Player` ou agente NPC raiz.
2. Definir 2-3 `LimboState` iniciais (ex.: `Idle`, `Chase`, `Attack`).
3. Em cada estado que exige decisão fina, usar `BTPlayer` com `BehaviorTree` dedicado.
4. Centralizar dados compartilhados em `BlackboardPlan` com mapping explícito.

---

## Referências oficiais usadas

- https://limboai.readthedocs.io/en/latest/index.html
- https://limboai.readthedocs.io/en/latest/classes/class_behaviortree.html
- https://limboai.readthedocs.io/en/latest/classes/class_btplayer.html
- https://limboai.readthedocs.io/en/latest/behavior-trees/using-blackboard.html
- https://limboai.readthedocs.io/en/stable/classes/class_limbohsm.html
- https://limboai.readthedocs.io/en/stable/classes/class_limbostate.html
- https://limboai.readthedocs.io/en/latest/behavior-trees/custom-tasks.html
