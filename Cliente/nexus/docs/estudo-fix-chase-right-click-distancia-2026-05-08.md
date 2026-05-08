# Estudo Tecnico - Fix de Chase por Clique Direito a Distancia

Data: 2026-05-08  
Escopo: Player combate (LimboAI BT + Intent Resolver)  
Cena de validacao: `res://cenas/mundo.tscn`

## Sintoma reportado
- No primeiro clique direito distante em inimigo: chase iniciava.
- Apos cancelar (ex: clique no chao) e tentar de novo de longe: chase nao iniciava.
- De perto (melee/media distancia): ataque/chase funcionava.

## Causa raiz consolidada
Foram encontrados 3 pontos combinados:

1. Cancelamento agressivo em intent `none`
- `PlayerController` chamava `_cancel_all_intents()` quando resolver retornava `none`.
- Em cliques sem alvo preciso, isso limpava estado de combate em momentos errados.

2. Picking muito estrito para clique em alvo pequeno
- Se o clique nao acertasse exatamente collider/pixel esperado, resolver retornava `none`.
- Isso piorava no clique distante.

3. Condicao de percepcao no ramo de ataque
- A condicao de percepcao na sequencia de ataque podia invalidar lock manual em cenarios fora de alcance imediato.
- Resultado: comportamento instavel apos ciclo cancelar -> retentar.

## Correcoes aplicadas
1. Intent `none` virou no-op
- Arquivo: `Scripts/player/player_controller.gd`
- Mudanca: no `match &"none"`, nao cancelar tudo automaticamente.

2. Tolerancia de picking aumentada
- Arquivo: `Scripts/interaction/interaction_resolver.gd`
- Mudanca: `PICK_RADIUS` de `18.0` para `36.0`.
- Efeito: clique direito distante fica menos dependente de pixel-perfect.

3. Remocao de condicao de percepcao da sequencia de ataque do player
- Arquivo: `ai/trees/player/player_combat_bt.tres`
- Mudanca: ataque permanece orientado por alvo lockado + range + face + request_attack.
- Nota: percepcao continua como conceito de stat para evolucao, mas sem interferir nesse loop de chase/attack do MVP.

## Fluxo final esperado (MVP)
1. `interact_secondary` em hostil -> `chase_attack`
2. `set_combat_target(target)`
3. BT player:
   - `pull_combat_target`
   - `validate_alive`
   - se em range: `face` + `request_attack`
   - senao: `chase_combat_target`
4. Cancelamento por movimento no chao limpa chase de forma explicita.

## Regressao validada
Checklist manual executado:
- [x] Clique direito longe inicia chase.
- [x] Clique esquerdo no chao cancela chase e move.
- [x] Novo clique direito longe reinicia chase corretamente.
- [x] Sem erro novo de parse/runtime no Godot MCP.

## Arquivos alterados no fix
- `Cliente/nexus/Scripts/player/player_controller.gd`
- `Cliente/nexus/Scripts/interaction/interaction_resolver.gd`
- `Cliente/nexus/ai/trees/player/player_combat_bt.tres`

## Licao de arquitetura
- Em input contextual, `none` nao deve destruir estado global por padrao.
- Cancelamento de combate deve ser intencional e explicito.
- Validacao de alvo em jogo isometrico mouse-first precisa tolerancia de picking.

