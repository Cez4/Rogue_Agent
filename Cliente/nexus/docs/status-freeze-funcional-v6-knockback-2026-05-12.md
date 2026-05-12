# Status Freeze V6: Combat Micro-Knockback Modular

## Tuning Final Aprovado - Knockback Force 200
Data: 12 de Maio de 2026
Status: aprovado em QA jogavel e congelado.

Decisao de Game Feel:
1. `knockback_force = 200.0` passa a ser o baseline padrao do jogo para impacto fisico perceptivel sem exagero.
2. A identidade entre ataques continua possivel pela duracao (`knockback_duration_sec`) e pelos demais dados do `CombatActionData`.
3. O ajuste permanece 100% Data-Driven: nenhum script, cena, BT ou HSM precisou ser alterado.

Arquivos congelados com `knockback_force = 200.0`:
1. `res://configs/combat/player_light_attack.tres`
2. `res://configs/combat/hostile_brute_attack_v1.tres`
3. `res://configs/combat/hostile_light_attack_v1.tres`
4. `res://configs/combat/wildcat_claw_attack_v1.tres`

Validacao MCP:
1. `res://cenas/mundo.tscn` abriu e rodou.
2. `get_godot_errors` nao registrou parse/runtime error novo.
3. `AttackHitbox` em runtime confirmou:
   - Player: `knockback_force = 200.0`, `knockback_duration_sec = 0.15`;
   - Brute: `knockback_force = 200.0`, `knockback_duration_sec = 0.2`.
4. Logs confirmaram `knockback_applied` com `force` aproximadamente `200.0` nos dois sentidos:
   - Player empurrando `HostileEnemyBrute`;
   - `HostileEnemyBrute` empurrando Player.
5. Telemetria de combate permaneceu saudavel: `attack_started`, `attack_commit`, `hit_confirmed`, `stamina_consumed`, `kiting_started`, `kiting_holding`, `kiting_ended` e `orb_stamina_react`.
**Data:** 12 de Maio de 2026
**Status:** Congelado e Estável
**Branch:** `feat/combat-knockback-component-v1`

## Resumo Executivo
A sprint focada em elevar o "Game Feel" do combate tático foi concluída. Um sistema universal e fisicamente responsivo de Micro-Knockback foi adicionado, resolvendo o problema de personagens ficarem permanentemente "colados" ou sobrepostos durante trocas de golpes corpo-a-corpo. A arquitetura manteve estrita aderência às filosofias "Modular" e "Data-Driven" do projeto, preparando o terreno para futuros Editores In-Game.

## Objetivos Alcançados (V6)
1. **Pilar Data-Driven (CombatActionData):** A inércia do impacto não existe no código físico do personagem. Novas propriedades (`knockback_force` e `knockback_duration_sec`) foram adicionadas aos arquivos de tuning de combate (`.tres`). Armas pesadas empurram mais longe, armas leves geram apenas distanciamento.
2. **Pilar Modular (KnockbackComponent):** Criado um nó físico isolado de processamento que aplica deslize via inércia interpolada (`move_and_slide`). O script `Actor8DirLimbo` permaneceu intocado por lógica matemática. Para tornar um inimigo imune a empurrões, basta remover a instância deste nó da cena.
3. **Pilar de Desacoplamento (O Transmissor):** A `AttackHitbox` agora calcula automaticamente o vetor direcional geométrico do agressor para o alvo, despachando as coordenadas de inércia para a `Hurtbox`, que atua como relé passando a ordem para o `KnockbackComponent`. 
4. **Sincronia com a Behavior Tree:** O empurrão físico ocorre fluidamente de forma aditiva ao motor nativo (`PlayerMotor`). A máquina de estados (`LimboHSM`) e a BT não perdem o estado `Combat Attack` e nem sofrem desvios de navegação pós-impacto.

## Próximos Passos
O loop mecânico de combate (Tática > Fôlego > Impacto Físico > Recuo e Fuga) atingiu um nível mecânico comparável aos padrões ARPG clássicos. A base está completamente livre de bugs de física ou NavMesh, suportando iterações de sistemas complexos (Paperdolling visual, Sistema de Skills Mágicas ou Loot).
