# Plano Sprint - Combat Knockback Component v1

Data: 2026-05-12
Status: ABERTA
Branch Recomendada: `feat/combat-knockback-component-v1`

## 1) Objetivo
Implementar um sistema de Micro-Knockback (empurrão físico por impacto) para elevar o "Game Feel" do combate e evitar que entidades fiquem permanentemente coladas.
A arquitetura exige **Modularidade Extrema (Plug-and-Play)** e **Data-Driven (Guiada por Dados)** para suportar a futura criação de um Editor In-Game de montagem de NPCs/Itens.

## 2) Visão Arquitetural (Editor-Ready)
1. **O Recurso (Data):** O script `CombatActionData.gd` (`.tres`) receberá as propriedades de impacto (`knockback_force`). Uma marreta terá alto knockback, uma adaga terá baixo.
2. **O Transmissor:** A `AttackHitbox` lerá o `.tres` da arma e transmitirá o vetor de impacto + força para a `Hurtbox` do alvo.
3. **O Receptor (Modular):** Um novo nó autônomo `KnockbackComponent.gd`. Se um ator possuir esse nó, ele sofre o empurrão. Chefes pesados podem simplesmente não ter o nó (ou ter uma resistência no nó) e serão imunes. O script principal do ator (`Actor8DirLimbo`) **NÃO** deve conter lógica de knockback.

## 3) Guardrails Obrigatórios
1. **Sem Hardcode:** Força e duração nunca podem ser hardcoded no script. Sempre ler do Resource da arma/ataque.
2. **Desacoplamento:** O `KnockbackComponent` não deve assumir que o pai é um `Actor8DirLimbo`. Ele deve interagir com física básica (`CharacterBody2D`).
3. **Imunidade a Paredes:** O knockback deve usar `move_and_slide()` na física para deslizar nas paredes da NavMesh sem atravessá-las ou travar a engine.
4. **Prioridade de Animação:** O Knockback não deve interromper a máquina de estados (`LimboHSM`) a não ser que a força passe de um limite de "Stagger" (Fora de escopo para V1, manteremos apenas o deslize físico por inércia enquanto o ator continua sua animação de ataque/dano).

## 4) Estado de Partida
1. Atores possuem `HurtboxComponent` e `HitboxComponent`.
2. Armas usam `CombatActionData` (`.tres`).
3. Movimento atual é gerenciado pelo `PlayerMotor` ou `NavigationAgent2D` (no caso da BT).
4. O NavAgent foi estabilizado recentemente (sem Clamps manuais e com Anti-Spam), o que garante que empurrões não vão quebrar a navegação no frame seguinte.

## 5) Plano de Execução

### Fase A - Estrutura de Dados (Data-Driven)
- [ ] Editar `Scripts/combat/combat_action_data.gd` para incluir:
  - `@export var knockback_force: float = 0.0`
  - `@export var knockback_duration_sec: float = 0.1`
- [ ] Atualizar os arquivos `.tres` existentes (adaga do player, garras do wildcat, soco do brute) com valores iniciais seguros de teste.

### Fase B - O Componente Modular (Plug-and-Play)
- [ ] Criar `Scripts/combat/knockback_component.gd`.
- [ ] O componente deve exportar `target_body: CharacterBody2D` (o corpo que será empurrado).
- [ ] Criar o método público `apply_knockback(force_vector: Vector2, duration: float)`.
- [ ] Implementar um `_physics_process` interno no componente que, quando ativado, sobrescreve/soma a `velocity` do corpo e chama `move_and_slide()` isoladamente pelo tempo determinado, caindo a zero suavemente (lerp).

### Fase C - O Fluxo de Transmissão (Hitbox -> Hurtbox)
- [ ] Modificar `HitboxComponent` para calcular a direção do impacto (De quem bateu para quem apanhou).
- [ ] Enviar o vetor de Knockback via sinal ou chamada de método junto com a requisição de Dano para o `HurtboxComponent` do alvo.
- [ ] O `HurtboxComponent` (ou o próprio ator via Bridge) repassa o vetor para o `KnockbackComponent` se ele existir na árvore do alvo.

### Fase D - Integração e QA
- [ ] Injetar o nó `KnockbackComponent` no `player.tscn` e nas cenas de Inimigos (`hostile_enemy_brute.tscn`, etc).
- [ ] Plugar as referências do nó via Inspector/Godot API.
- [ ] Jogar na arena: Validar se golpes empurram o alvo.
- [ ] Validar colisão contra parede: O alvo deve deslizar ou bater na parede sem bugar o NavAgent.
- [ ] Telemetria: Adicionar emissão de log `knockback_applied` com a força para facilitar o balanceamento.

## 6) Critérios de Aceite
- [ ] Knockback funciona bidirecionalmente (Player empurra NPCs, NPCs empurram Player).
- [ ] A distância do empurrão respeita o valor configurado no `.tres` do atacante.
- [ ] Nenhuma linha de lógica matemática de empurrão foi adicionada ao `Actor8DirLimbo` (apenas o wire do Bridge, se necessário).
- [ ] Atores não perdem o `combat_target` durante o micro-knockback.
- [ ] Smoke MCP Limpo (`get_godot_errors` = Vazio).

## 7) Próximo Passo Imediato
Criar a nova branch `feat/combat-knockback-component-v1` e iniciar a **Fase A (Estrutura de Dados)**.