# Status Freeze V3: Arquitetura Modular LimboAI (BT)
**Data:** 11-05-2026

## O Que Foi Congelado
A fundação da Inteligência Artificial do jogo foi oficialmente transicionada de "Scripts Monolíticos" para o padrão "Composição Visual" nativo da Demo do LimboAI.
A árvore do Player (`player_combat_bt.tres`) serve agora como a "Árvore Dourada" de homologação.

## Regras Arquiteturais Fundamentais (V3)
1. **Fim dos "God Scripts":** Foi banida a prática de criar scripts complexos de `BTAction` que controlam tempo (`now_ms < limit`), matemática de vetores e execução motora simultaneamente (ex: o extinto `bt_low_stamina_tactical.gd`).
2. **Tasks Atômicas:** A partir de agora, toda task em GDScript deve ser atômica e minúscula (fazer apenas uma coisa). Ex: `bt_is_stamina_low.gd` (apenas checa), `bt_get_kite_position.gd` (apenas injeta a coordenada no Blackboard).
3. **Gerenciamento de Tempo por Decorators:** Pausas táticas, "Breathing Rooms", Kiting e Recuos **DEVEM** ser gerenciados utilizando os nós nativos do LimboAI (`BTTimeLimit` para limitar a execução de movimento, `BTRandomWait` para impor pausas de respiração e cadência). Isso mantém a árvore legível e Data-Driven pelo painel do Godot.
4. **Cinemática de Combate (Game Feel):** Incorporado como padrão visual que todo recuo tático (Kiting) deve terminar com uma ação de `bt_face_combat_target_8dir` para que o ator encare o alvo antes de entrar no estado de respiro (`BTRandomWait`).

## Consequência Direta
O combate agora ostenta cadência fluida (Soulslike) livre da "patinação" (Yo-Yo effect) induzida por loops falsos de scripts anteriores. O código está descentralizado, e a manipulação do combate pertence aos recursos `.tres`.