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


## Workflow de desacoplamento seguro (aprovado no projeto)
1. Mapear contrato usado por BT/HSM/Controller antes de alterar.
2. Extrair responsabilidade para runtime pequeno (uma responsabilidade por vez).
3. Evitar acesso direto a campo privado do actor dentro dos runtimes.
4. Usar bridge/contrato explicito para integracao tecnica entre runtimes e actor.
5. Validar em MCP a cada bloco: open_scene -> play_scene -> get_godot_errors.
6. So consolidar (remover wrappers) depois que MCP estiver limpo.
7. Atualizar docs de estado na mesma entrega.

