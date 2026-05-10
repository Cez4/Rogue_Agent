# Documentação Técnica e Arquitetural: Sistema de Orb UI Contextual (V3 - Final)

## 1. Visão Geral
A Orb UI é o componente definitivo de feedback visual flutuante para saúde (HP) no Rogue Agent. Projetada para altíssima legibilidade tática em combates frenéticos, ela abandona UIs estáticas em favor de **Shaders Dinâmicos** e **Sistemas de Trauma Físico**.

## 2. Arquitetura de Movimento e Espaço
O `CombatOrbPresenter` atua como o controlador raiz:
- **Independência Espacial (`top_level = true`):** A orb desvincula-se das transformações do pai (escala/rotação do Actor), evitando distorções visuais quando o inimigo inverte a direção ou muda de escala.
- **Interpolação Global (`lerp`):** Movimenta-se em direção ao `follow_offset` do ator pai de forma fluida (usando `delta * 12.0`).
- **Anti-Overlap Contextual:** Para evitar orbs coladas umas nas outras em melee, o sistema aplica um offset lateral automático: Player para a Esquerda (`-35.0px`), Alvo para a Direita (`+35.0px`).

## 3. Feedback Tátil: O Sistema de Trauma (Shake)
Em vez de usar `Tweens` básicos que se anulam em combos rápidos, a Orb implementa o **Trauma-based Shake** (padrão da indústria para Game Feel):
- **Acúmulo:** Cada hit adiciona `0.5` ao `_trauma` (max `1.0`).
- **Decaimento:** O trauma diminui via `trauma_decay` no `_process`.
- **Movimento Quadrático:** A potência do tremor é `_trauma * _trauma`.
- **Independência Visual:** O tremor é aplicado exclusivamente na propriedade `offset` do `Sprite2D`. Isso permite que a Orb continue seu movimento suave de `lerp` pela tela enquanto vibra violentamente por dentro, garantindo que o shake seja perfeitamente visível independente da escala local.

## 4. O Segredo do Shader: Dampening Envelope e Slosh
O `orb_health_shader.gdshader` não apenas exibe cores, ele simula a física de um líquido confinado:
- **Slosh (Espirro/Balanço):** Em vez de usar `TIME` para controlar a onda de impacto (o que causa aliasing e paradas bruscas), o shader usa a própria variável `vibration` (alimentada diretamente pelo `_trauma` do presenter).
  ```glsl
  // O "vibration" atua como Amplitude E Frequência, garantindo que a água pare horizontalmente.
  float slosh = uv.x * sin(vibration * 25.0) * vibration * 1.5;
  ```
- Essa técnica garante sincronia 1:1 entre a tremedeira física da Sprite e a rebelião do líquido dentro do vidro.

## 5. Identidade Visual (RPG Standard)
Para eliminar a confusão de "De quem é esse HP?", adotamos regras estritas de legibilidade:
- **Saúde:** Líquido Verde Esmeralda (`#26d933`).
- **Dano Perdidio (Fundo):** Fundo Vermelho Escuro/Opaco (`#660505` com alpha `0.85`) e bordas grossas (`0.12`).
- **Target Lock (Mira):** Inimigos selecionados ganham um anel externo Dourado Pulsante com 4 marcas de mira (crosshair).
- **Aggro Alert:** O anel do inimigo muda para Vermelho se ele estiver no estado `attack` do LimboHSM.
- **Danger Alert (Player):** Se a vida do Player cair para < 25%, o líquido fica vermelho e um anel de vinheta vermelha pulsa por dentro.
- **Damage Trail:** Rastro de perda de HP é em tom translúcido, caindo via `move_toward` para nunca "travar" com hits rápidos.

## 6. Lições Aprendidas (Armadilhas Evitadas)
1. **O Bug do Setter no GDScript 2.0:** Modificar propriedades internas (`_current_trail = ...`) de dentro de um loop de `_process` **NÃO** aciona a função `set(v):` atrelada à variável. É mandatório chamar `set_shader_parameter` explicitamente no loop de animação, ou usar `self._current_trail = ...`.
2. **Escala de Offset:** Um tremor (`max_shake_offset`) de `4.0` pixels em um Sprite com escala de `0.15` resulta em `0.6` pixels na tela (invisível). Valores de offset em Sprites devem ser multiplicados para compensar escalas baixas (ex: `65.0`).
