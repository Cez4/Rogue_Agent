# Status Freeze V5: Actor Social Profiles & Decoupling
**Data:** 12 de Maio de 2026
**Status:** Congelado e Estável
**Branch:** `feat/actor-export-profile-organization-v1`

## Resumo Executivo
A sprint focada em organizar os perfis do `Actor8DirLimbo` foi concluída com sucesso (Fases A até E3). 
Seguindo a filosofia "The Sims-like" do projeto, nós modularizamos a Identidade Social, Comportamento de Deslocamento Livre (Wander) e Expressões Visuais (Emotes) de todos os atores (Players e NPCs) em um único modelo de dados compartilhado: o `ActorSocialProfile`.

A fachada principal (`Actor8DirLimbo`) foi despoluída permanentemente, perdendo o acúmulo de mais de 30 variáveis exportadas.

## Objetivos Alcançados (V5)
1. **Padronização de Perfis Sociais:** Criados `.tres` isolados para os atores do mundo:
   - `villager_social_profile_v1.tres` (aplicado ao Villager1).
   - `hostile_social_profile_v1.tres` (compartilhado entre Wildcat, Base, Light e Brute).
   - `player_social_profile_v1.tres` (aplicado ao Player).
2. **Filosofia The Sims Aplicada:** O Player agora compartilha a mesma fundação biológica/social dos NPCs. Mesmo que funções autônomas (Wander) estejam desligadas para o Player por padrão, a infraestrutura garante paridade comportamental total, permitindo controle delegado no futuro (AFK/BT).
3. **Limpeza de Overrides (Tuning Fantasma):** Todos os ajustes em cena soltos (Overrides de Instância) presentes em `mundo.tscn` que afetavam look/wander foram removidos via Godot Editor API. A única fonte da verdade comportamental agora é o arquivo `.tres` vinculado.
4. **Desacoplamento Completo da Fachada (Fase E3):** O script principal do ator (`Actor8DirLimbo`) teve todos os exports redundantes (`look_*`, `wander_*`, `stamina_exhausted_emote_*`) deletados do código-fonte.
5. **Runtime Resiliente:** `ActorSocialProfileRuntime` foi refatorado para utilizar uma constante estrutural (Default Profile) no lugar do fallback técnico, garantindo que o código não crasha mesmo que um ator nasça sem perfil assinado.

## Integridade do Combate Mantida
As extensas refatorações visuais e sociais não afetaram as Árvores de Comportamento (LimboAI) ou o Combate Tático (HSM). Testes rigorosos na fase de Kiting (resolvidos no patch do NavAgent) seguem intactos e perfeitamente fluidos.

## Próximos Passos
Com o `Actor8DirLimbo` extremamente enxuto e o comportamento Data-Driven provado, a fundação está livre para escalar para Sistemas Visuais Modulares (ex: Paperdolling, Separação de Gênero Masculino/Feminino, Armaduras).