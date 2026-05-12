# Status Freeze V6: Combat Micro-Knockback Modular
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