# Godot MCP Setup - Spacetimedb

Configuracao oficial do `GDAI MCP` aplicada ao projeto `Spacetimedb`.

## Estado validado

- Projeto Godot: `Cliente/space-m-mo`
- Plugin presente em: `Cliente/space-m-mo/addons/gdai-mcp-plugin-godot`
- Plugin habilitado no `project.godot`
- `uv` instalado: `uv 0.11.7`
- Servidor MCP ativo em `http://localhost:3571/tools` (HTTP 200)
- Prompt MCP ativo em `http://localhost:3571/prompts` (HTTP 200)

## Arquivo de configuracao do projeto Godot

Arquivo:

- `Cliente/space-m-mo/gdai_mcp_project_config.json`

Conteudo:

```json
{
  "GDAI_MCP_SERVER_PORT": "3571",
  "GDAI_RUNTIME_SERVER_PORT": "3572",
  "UV_CACHE_DIR": "C:/Users/ceza/Documents/Spacetimedb/.runtime/uv-cache"
}
```

Pasta de cache criada:

- `C:/Users/ceza/Documents/Spacetimedb/.runtime/uv-cache`

## Configuracao do Codex MCP

Servidor global adicionado no Codex:

- `godot-mcp-spacemmo`

Comando equivalente:

```powershell
codex mcp add godot-mcp-spacemmo `
  --env GDAI_MCP_SERVER_PORT=3571 `
  --env GDAI_RUNTIME_SERVER_PORT=3572 `
  --env UV_CACHE_DIR=C:/Users/ceza/Documents/Spacetimedb/.runtime/uv-cache `
  -- C:/Users/ceza/.local/bin/uv.exe run C:/Users/ceza/Documents/Spacetimedb/Cliente/space-m-mo/addons/gdai-mcp-plugin-godot/gdai_mcp_server.py
```

## Validacao rapida

1. Abrir `Cliente/space-m-mo` no Godot.
2. Confirmar plugin `GDAI MCP` ativo em `Project -> Project Settings -> Plugins`.
3. Confirmar no painel `GDAI MCP` que o server esta ativo.
4. Rodar:

```powershell
codex mcp list
```

Deve aparecer `godot-mcp-spacemmo` como `enabled`.

## Diagnostico oficial por logs (padrao de uso)

Sempre usar `get_godot_errors` como primeira verificacao.

Leitura obrigatoria:
1. `Session Runtime Error`:
   - `Sessao de depuracao fechada` indica apenas que nao ha cena em execucao.
2. `Recent output logs`:
   - Confirmar bootstrap (`SpacetimeManager/EntityManager/InputHandler instanced`).
   - Confirmar conexao (`connection_state_changed => connected`).
   - Confirmar eventos (`EntityManager joined/moved/left`).

Ruido esperado:
- `Runtime server skipped: port 3572 already in use` durante teste local com duas instancias.

Classificacao final:
- `funcional`, `funcional com ruido`, ou `com bug`.

## Referencias

- https://gdaimcp.com/docs/installation
- https://gdaimcp.com/docs/configuration
