# Documentação Técnica e Arquitetural: Sistema Universal de Stamina e Stagger

## 1. Visão Geral
O sistema de Stamina foi projetado para ser um componente universal (Data-Driven), aplicável tanto ao Player quanto aos Inimigos. Ele introduz ritmo e penalidade ao combate, evitando o "spam" contínuo de ataques e criando janelas táticas de vulnerabilidade através da mecânica de **Stagger (Atordoamento/Exaustão)**.

## 2. Arquitetura Orientada a Componentes
O sistema é desacoplado do ator principal e reside no `StaminaComponent` (`Scripts/stats/stamina_component.gd`).
- **Data-Driven Cost:** O custo de stamina de cada ataque NÃO é hardcoded no script do ator. Ele reside no Resource `CombatActionData` (`@export var stamina_cost: float`).
- **Autogestão:** O componente possui lógica autônoma de regeneração (`regen_rate`, `regen_delay_sec`) acionada no `_process`, caso não esteja exausto.
- **Sinais:** Emite `stamina_changed`, `exhausted` (quando chega a 0), e `recovered` (quando regenera até um nível seguro, por padrão 50%).

## 3. O Fluxo de Combate (Drenagem Justa)
Para evitar o bug do "dreno fantasma" (onde a stamina é gasta apenas por spammar o botão, mesmo em cooldown), o sistema foi integrado diretamente no **LimboHSM**:
- O `Actor8DirLimbo` valida no `request_attack()` se há stamina disponível, mas **NÃO** drena a stamina ali.
- A drenagem real só ocorre dentro do `_enter()` do `StateAttack8Dir` (`stamina.consume(cost)`), *após* a validação de que o ataque saiu do cooldown. Isso garante sincronia 1:1 entre a animação tocada e o custo pago.

## 4. O Castigo: StaggerState
Quando o `StaminaComponent` emite o sinal `exhausted`, o `Actor8DirLimbo` capta e envia um evento forçado (`&"stagger!"`) para o LimboHSM.
- **Interrupção Imediata:** A máquina transita para o `StaggerState` (`Scripts/actors/states/stagger_state.gd`), abortando imediatamente qualquer ataque em andamento e parando o motor de movimento.
- **Retenção de Aggro (Design Rule):** Ao contrário do que a intuição dita, o `StaggerState` **NÃO DEVE** limpar o alvo de combate (`clear_combat_target()`). Manter a memória do alvo durante o "Stun/Exhaustion" garante que, assim que o timer do stagger acabar, a Behavior Tree (BT) retome a caçada (Chase) fluidamente. Limpar o alvo causaria "amnésia" na IA, arruinando o Game Feel.
- **Duração:** A duração do atordoamento é definida no estado (`stagger_duration_sec`), mantendo o ator vulnerável enquanto a stamina se recupera no background.

## 5. Telemetria Integrada
O sistema é 100% rastreável. Eventos emitidos para auditoria:
- `stamina_consumed`: Registra o `amount` e `remaining`.
- `stamina_exhausted`: Registra o exato frame em que o tanque zerou.
- `actor_staggered`: Registra a entrada no estado de punição e a `duration`.
- `stamina_recovered`: Acionado apenas quando o ator sai da zona de exaustão (>50%).