# Workflow Obrigatorio: Doc-First (Godot + LimboAI)

Objetivo:
Padronizar que toda criacao, edicao ou correcao de logica seja precedida por estudo rapido da documentacao oficial.

## Regra Geral
Antes de alterar codigo ou cena:
1. Consultar docs oficiais relevantes do tema atual.
2. Confirmar API/classe/metodo na versao usada no projeto.
3. So depois implementar e testar.
4. Nao usar tentativa/erro de API sem pesquisa previa em docs oficiais.

## Checklist Operacional (sempre)
1. Definir o escopo da mudanca em 1-3 linhas.
2. Abrir referencias oficiais (Godot + LimboAI).
3. Extrair regras tecnicas aplicaveis (nomes de propriedades, ciclo de vida, eventos, limites).
4. Aplicar mudanca minima necessaria (sem over-engineering).
5. Testar no editor/cena alvo.
6. Registrar no doc de progresso o que foi feito e por que.
7. Confirmar telemetria/log da logica nova (evento/sinal esperado no output).

## Fontes oficiais prioritarias
Godot:
- https://docs.godotengine.org/en/stable/
- https://docs.godotengine.org/en/stable/classes/class_navigationagent2d.html
- https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html
- https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html
- https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html

LimboAI:
- https://limboai.readthedocs.io/en/stable/
- https://limboai.readthedocs.io/en/stable/classes/class_btplayer.html
- https://limboai.readthedocs.io/en/stable/classes/class_behaviortree.html
- https://limboai.readthedocs.io/en/stable/behavior-trees/custom-tasks.html
- https://limboai.readthedocs.io/en/stable/behavior-trees/using-blackboard.html
- https://limboai.readthedocs.io/en/stable/hierarchical-state-machines/create-hsm.html

## Regras de qualidade para este projeto
- LimboAI e core de comportamento: priorizar BT/HSM antes de logica ad-hoc.
- Evitar acoplamento com input direto em regras de gameplay.
- Preferir configuracao por Resource/export vars (data-driven).
- Manter mudancas pequenas, testaveis e reversiveis.
- Para multiplayer/co-op: cliente envia intencao, estado oficial vem do host.
- Em combate melee, garantir paridade de composicao nas cenas (Health + Hurtbox + AttackHitbox) para todo ator combatente.
- Padrão de Feedback Visual (Orb UI): Usar `CombatOrbPresenter` com suporte a trail (barra branca) e vibração para todo ator com `HealthComponent`.
- Posicionamento de UI Flutuante: Utilizar `top_level = true` e interpolação global (`lerp`) para evitar artefatos de transform do pai e implementar separação lateral automática para evitar overlap.
- Feedback de Impacto (Game Feel): Evitar Tweens isolados para tremores de UI. Implementar **Sistemas de Trauma** (Trauma-based shake) com movimento quadrático e decaimento temporal para suportar acúmulo de hits em combos. O trauma deve alimentar diretamente os shaders de distorção (Dampening Envelope).
- Armadilha GDScript 2.0: Ao animar variáveis no `_process`, lembre-se que chamadas diretas a variáveis locais NÃO invocam suas funções `set(v):` automaticamente. Utilize `self.variavel` ou faça o update manual para garantir sincronia com os shaders.
- Em bugs de morte/respawn, auditar primeiro overrides da cena instanciadora (ex.: `mundo.tscn`) antes de mexer no script base.

## Saida minima esperada por tarefa
- Contexto consultado (links usados).
- Mudanca aplicada.
- Evidencia de teste (cena/teste executado e resultado).
- Evidencia de telemetria/log da logica nova (quando aplicavel, obrigatorio).
- Riscos remanescentes (se houver).

## Lei de aceite tecnico
- Logica nova sem teste + telemetria comprovada nao e considerada concluida.
- Auditoria periodica de saude (docs do projeto + docs web oficiais) e obrigatoria ao abrir nova fase.
- Em alteracao de lifecycle/combat, validar no log ao menos: `target_died`, `chase_canceled` com motivo e `respawned` (quando aplicavel).

## Regra de evidencia (obrigatoria)
- Toda mudanca tecnica deve citar pelo menos 1 fonte oficial (Godot ou LimboAI) no doc de estudo/status da entrega.
- Se tocar BT/HSM/Navigation/Animation/Input, citar a pagina especifica da classe/metodo.
- Em fase de tuning, registrar tambem o eixo da iteracao (Targeting/Approach/Cadence/Survivability) e o resultado de telemetria.

## Observacao
Este workflow nao bloqueia entregas rapidas.
Ele reduz retrabalho e erro de API, mantendo velocidade com previsibilidade.
