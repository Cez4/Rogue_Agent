# Godot MCP Setup - Nexus

Configuracao aplicada para este projeto (`Cliente/nexus`) com plugin `gdai-mcp-plugin-godot`.

## Estado aplicado

- Projeto Godot: `C:/Users/ceza/Documents/Rogue_agent/Cliente/nexus`
- Plugin: `C:/Users/ceza/Documents/Rogue_agent/Cliente/nexus/addons/gdai-mcp-plugin-godot`
- `uv`: validado (`uv 0.11.7`)
- Portas configuradas:
  - `GDAI_MCP_SERVER_PORT=3571`
  - `GDAI_RUNTIME_SERVER_PORT=3572`
- Cache `uv`:
  - `C:/Users/ceza/Documents/Rogue_agent/Cliente/nexus/.runtime/uv-cache`

## Arquivo do projeto Godot

Arquivo: `Cliente/nexus/gdai_mcp_project_config.json`

```json
{
  "GDAI_MCP_SERVER_PORT": "3571",
  "GDAI_RUNTIME_SERVER_PORT": "3572",
  "UV_CACHE_DIR": "C:/Users/ceza/Documents/Rogue_agent/Cliente/nexus/.runtime/uv-cache"
}
```

## Config MCP para Claude Desktop / Cursor / Windsurf

```json
{
  "mcpServers": {
    "godot-mcp": {
      "command": "uv",
      "args": [
        "run",
        "C:/Users/ceza/Documents/Rogue_agent/Cliente/nexus/addons/gdai-mcp-plugin-godot/gdai_mcp_server.py"
      ],
      "env": {
        "GDAI_MCP_SERVER_PORT": "3571",
        "GDAI_RUNTIME_SERVER_PORT": "3572",
        "UV_CACHE_DIR": "C:/Users/ceza/Documents/Rogue_agent/Cliente/nexus/.runtime/uv-cache"
      }
    }
  }
}
```

## Config MCP para VS Code (Copilot/Cline/Roo)

Arquivo: `Cliente/nexus/.vscode/mcp.json`

Obs.: no VS Code a chave raiz e `servers` (nao `mcpServers`).

## Validacao rapida

1. Abrir `Cliente/nexus` no Godot.
2. Confirmar plugin `GDAI MCP` ativo em `Project -> Project Settings -> Plugins`.
3. Reiniciar o Godot apos alterar `gdai_mcp_project_config.json`.
4. Reiniciar seu cliente MCP (Claude/Cursor/Windsurf/VSCode) apos alterar a config.
5. Testar uma tool simples (ex: leitura de erros/logs).

## Referencias oficiais

- https://gdaimcp.com/docs/installation
- https://gdaimcp.com/docs/configuration
