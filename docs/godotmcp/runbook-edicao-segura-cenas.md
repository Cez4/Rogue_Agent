# Runbook - Edição Segura de Cenas com Godot Aberto

## Problema
Quando um `.tscn` é modificado por fora do editor (ex.: patch/script/terminal), o Godot mostra:
`Arquivos foram modificados fora do Godot`.

Isso não é bug de gameplay; é conflito de origem de edição.

## Objetivo
Evitar perda de trabalho, conflito de cena e comportamento inconsistente durante testes.

## Regra operacional
1. **Não editar `.tscn` externamente enquanto a cena estiver aberta e em uso ativo no editor.**
2. Preferir:
- ajustes em `.gd` (scripts) durante play;
- quando precisar alterar `.tscn`, parar a execução e aplicar fluxo controlado.

## Fluxo seguro (padrão)
1. Parar `play` da cena.
2. Aplicar alterações de arquivo.
3. No popup do Godot, clicar **`Recarregar do disco`**.
4. Revisar visualmente a cena.
5. Salvar (`Ctrl+S`).
6. Rodar novamente e validar.

## Quando aparecer o popup
Escolhas:
- **`Recarregar do disco`**: aceita mudanças externas (recomendado no nosso fluxo).
- **`Ignorar mudanças externas`**: mantém a versão carregada no editor e descarta o que veio do disco.

## Checklist rápido antes de commit
- Cena abre sem popup pendente.
- Sem erros críticos no debugger.
- Estado funcional reproduzível após reabrir projeto/cena.

## Observação
Este projeto usa MCP + edição automatizada. Portanto, este runbook é obrigatório para manter consistência entre:
- arquivo no disco,
- cena aberta no editor,
- estado de runtime.


## Validacao MCP apos refactor
1. open_scene(res://cenas/mundo.tscn)
2. play_scene(current)
3. get_godot_errors sem parse/runtime novo


## Lei do fluxo (obrigatoria)
1. Godot MCP e obrigatorio em toda alteracao de logica/comportamento.
2. MCP e a validacao em tempo real (nossos olhos e maos): abrir cena, rodar e ler erros/logs apos cada bloco.
3. Nao fechar refactor sem validacao MCP.
4. Checklist minimo MCP: open_scene -> play_scene -> get_godot_errors -> conferir telemetria.
5. Estudo tecnico e obrigatorio antes de codar: ler docs internos relevantes + docs oficiais Godot + docs oficiais LimboAI do tema da tarefa.
6. Se houver duvida de API/comportamento, pesquisar primeiro nas docs oficiais e registrar as fontes no doc de estudo/estado.
7. Toda logica nova exige teste funcional + evidencia de telemetria/log como criterio de aceite (lei do projeto).


## Fluxo oficial do projeto (obrigatorio)
1. Estudar contexto antes de alterar: docs do projeto + scripts afetados + estado atual.
2. Estudar referencia oficial antes de alterar: Godot docs + LimboAI docs do topico (BT/HSM/Nav/Animation/Input).
3. Alterar em blocos pequenos e desacoplados (um runtime/uma responsabilidade por vez).
4. Validar cada bloco no Godot MCP imediatamente: open_scene -> play_scene -> get_godot_errors.
5. Conferir comportamento e telemetria no log (chase/attack/death/respawn) antes de seguir.
6. Atualizar docs de estado quando houver mudanca estrutural.
7. Fluxo Git obrigatorio: git add -> git commit -> git status -sb (ahead 1) -> git push origin <branch> -> git status -sb final (sincronizado).
8. Nao inverter ordem de commit/push e nao considerar concluido enquanto o push nao confirmar envio do commit local.
9. Nao considerar entrega concluida sem teste reproduzivel + telemetria conferida.
10. Nao executar comandos Git em paralelo (sempre serial).
11. Se houver duvida de sync, validar com:
   - `git rev-list --left-right --count origin/<branch>...HEAD`
   - esperado em sync: `0 0`.
12. Se ocorrer `index.lock: Permission denied`, tratar como problema operacional de permissao/sessao:
   - repetir comando em modo elevado;
   - manter fluxo normal (sem comandos destrutivos).
13. Se ocorrer erro SSH intermitente (ex.: `couldn't create signal pipe`):
   - repetir push explicito da branch;
   - confirmar sincronizacao com `rev-list` + `status -sb`.


## Workflow de desacoplamento seguro (aprovado no projeto)
1. Mapear contrato usado por BT/HSM/Controller antes de alterar.
2. Extrair responsabilidade para runtime pequeno (uma responsabilidade por vez).
3. Evitar acesso direto a campo privado do actor dentro dos runtimes.
4. Usar bridge/contrato explicito para integracao tecnica entre runtimes e actor.
5. Validar em MCP a cada bloco: open_scene -> play_scene -> get_godot_errors.
6. So consolidar (remover wrappers) depois que MCP estiver limpo.
7. Atualizar docs de estado na mesma entrega.


## Regra critica (cenas instanciadas)
1. Alterar `res://cenas/player.tscn` nao garante efeito em `res://cenas/mundo.tscn` se houver override no nodo instanciado.
2. Sempre auditar overrides no mapa principal para propriedades criticas:
   - `die_prefix`
   - `enable_respawn`
   - `respawn_delay_sec`
3. Em bug de "travou", confirmar primeiro no log se houve `target_died` (morte real) antes de tratar como freeze.
4. Auditoria de UI: Ao adicionar novos atores combatentes, confirmar se o nodo `CombatOrb` está presente e configurado com o `follow_offset` correto.

## Prova de conceito data-driven (fechado)
1. Conceito validado com 2 hostis reais (`Light` e `Brute`) sem criar script novo por inimigo.
2. Mesmo core para ambos:
   - `actor_8dir_limbo.gd`
   - BT/HSM e pipeline de combate iguais.
3. Diferenca de comportamento vem somente de dados:
   - `combat_perception_profile` (.tres)
   - `combat_action_data` (.tres)
4. Critério de aceite:
   - telemetria confirma variacao por dados (`attack_stop_distance`, `damage`, cadence),
   - sem erro novo em `get_godot_errors`.

## Freeze total de combate tatico (2026-05-11)
1. Antes de alterar `mundo.tscn`, `player.tscn`, `hostile_enemy_*` ou NavPolygon, ler:
   - `Cliente/nexus/docs/status-freeze-total-combate-tatico-2026-05-11.md`
2. Ajustes atuais aprovados nao sao drift:
   - NavMesh/NavPolygon da arena de teste;
   - regen de stamina para forcar reposicionamento;
   - `Walk_Unarmed_*` do Player sem loop;
   - tuning atual do Brute/Light/Player.
3. Nao reverter esses pontos sem reproduzir regressao em MCP e registrar telemetria.
4. Se uma cena instancia outra cena, auditar override local antes de concluir que o script base esta errado.

## Sequenciamento de sprints pos-freeze (obrigatorio)
1. `Cliente/nexus/docs/plano-sprint-health-regen-datadriven-v1-2026-05-11.md` esta congelado.
2. A sprint estrutural ativa e `Cliente/nexus/docs/plano-sprint-actor8dir-facade-slimming-v1-2026-05-11.md`.
3. Refatorar `Scripts/actors/actor_8dir_limbo.gd` somente em blocos pequenos, preservando wrappers publicos usados por BT/HSM/Controller.
4. Durante o slimming, nao alterar cena, BT/HSM, kiting, stamina, Orb ou Health Regen sem bug comprovado e novo QA.

## Sequenciamento Actor Export/Profile Organization v1
1. `Cliente/nexus/docs/plano-sprint-actor-export-profile-organization-v1-2026-05-11.md` e a sprint ativa de organizacao de exports/perfis.
2. Fases A-D estao congeladas: profile social/wander criado, Villager migrado e hostis migrados com QA aprovado.
3. Fase E nao pode comecar removendo exports do `Actor8DirLimbo` diretamente.
4. Ordem obrigatoria da Fase E:
   - E0: auditar cobertura de `social_profile` e classificar valores antigos como `fallback_real`, `override_aprovado`, `tuning_fantasma` ou `remover_depois`;
   - E1: limpar apenas overrides antigos de cenas ja migradas;
   - E2: decidir Player/restantes com profile proprio, profile default ou fallback tecnico;
   - E3: remover exports somente com cobertura total comprovada.
5. Qualquer limpeza em `.tscn`/`.tres` deve ser feita via Godot/editor API, nunca por texto.
6. Se uma entidade ainda nao tiver `social_profile`, os exports antigos devem ser tratados como fallback real ate prova contraria.

## Sequenciamento Universal Hit Reaction Component v1
1. `Cliente/nexus/docs/plano-sprint-universal-hit-reaction-component-v1-2026-05-12.md` esta concluido e congelado no V7 para o Player.
2. `Cliente/nexus/docs/status-freeze-funcional-v9-hostile-hit-reaction-2026-05-12.md` e o baseline atual da cobertura visual de Hit Reaction em hostis.
3. Baselines por camada:
   - V7: Player.
   - V8: Wildcat.
   - V9: HostileEnemyBase, HostileEnemyLight e HostileEnemyBrute.
4. A sprint implementou:
   - `HitReactionComponent`;
   - `HitReactionProfile`;
   - `HitReactionState`;
   - Player com `Dagger01_TakeDamage_*` tocando inteiro e orientado para a origem do golpe.
5. Novas propagacoes para NPCs/hostis devem preservar o contrato plug-and-play e validar telemetria.

## Sequenciamento Combat Clash / Parry Window v1
1. `Cliente/nexus/docs/plano-sprint-combat-clash-parry-v1-2026-05-12.md` e a sprint atual apos V9.
2. Nao implementar Parry direto: a Fase A e somente telemetria, sem mudanca de gameplay.
3. O custo de stamina do ataque interrompido ja e o primeiro "stamina damage" aprovado; nao duplicar punicao antes de QA.
4. Eventos minimos da Fase A:
   - `attack_phase_started`;
   - `attack_window_opened`;
   - `attack_window_closed`;
   - `attack_interrupted`;
   - `combat_clash_candidate` somente quando houver dados suficientes.
5. Toda correlacao deve usar `attack_sequence_id` para ligar stamina, fase, hit confirm e interrupcao.
6. Se criar `CombatClashComponent`/`ParryComponent`, ele deve ser plug-and-play como `KnockbackComponent` e `HitReactionComponent`.
7. Nao adicionar exports de Parry/Clash em `Actor8DirLimbo`.
8. Nao editar `.tscn`/`.tres` por texto; qualquer componente/profile em cena deve ser aplicado via Godot/editor API.
9. Validacao MCP obrigatoria antes de commit: `open_scene -> play_scene -> get_godot_errors -> conferir telemetria`.
10. Se houver mudanca funcional aprovada, criar freeze V10.

## Contrato Universal Hit Reaction Component v1
1. A decisao arquitetural obrigatoria e componente plug-and-play:
   - `HitReactionComponent` copiavel para Player, NPC amigavel ou inimigo;
   - `HitReactionProfile` em `.tres` para tuning;
   - estado HSM para executar a reacao corporal;
   - BT preservada como decisora de intencao, nao como dona da regra de dano.
2. Nao reengordar `Actor8DirLimbo`: o actor deve continuar como fachada fina.
3. Nao adicionar exports/tuning de Hit Reaction no actor.
4. Wrappers no actor so sao permitidos se forem contrato minimo para BT/HSM/Controller e devem delegar imediatamente para componente/service/state.
5. Cenas e resources devem ser alterados via Godot/editor API; nao editar `.tscn`/`.tres` estruturalmente por texto.
6. Validacao obrigatoria: MCP limpo + telemetria `hit_reaction_requested`, `hit_reaction_started`, `hit_reaction_animation`, `hit_reaction_finished`, alem de confirmar que `combat_target` nao foi limpo.

## Freeze intermediario Actor8Dir Slimming bloco 1
1. `ActorCombatResourceRuntime` esta aceito como primeiro corte estrutural.
2. `actor_8dir_limbo.gd` reduziu de 633 para 601 linhas sem alterar cenas.
3. Logs confirmaram ataque, kiting, morte, respawn e regen preservados.
4. Antes de nova edicao estrutural, revisar o ruido de telemetria `kiting_started` em spam.
5. Nao abrir Fase C (`actor_spatial_runtime`) enquanto essa decisao estiver pendente.
