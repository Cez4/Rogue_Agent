# Godot MCP Setup (Projeto Spacetimedb)

Configuracao oficial do `GDAI MCP` para este projeto.

## Estado canonico

- Projeto Godot: `C:/Users/ceza/Documents/Spacetimedb/Cliente/space-m-mo`
- Config MCP do projeto: `Cliente/space-m-mo/gdai_mcp_project_config.json`
- Plugin: `Cliente/space-m-mo/addons/gdai-mcp-plugin-godot`
- Portas padrao:
  - `GDAI_MCP_SERVER_PORT = 3571`
  - `GDAI_RUNTIME_SERVER_PORT = 3572`
- Cache `uv`:
  - `C:/Users/ceza/Documents/Spacetimedb/.runtime/uv-cache`

## Configuracao validada no projeto

Arquivo `Cliente/space-m-mo/gdai_mcp_project_config.json`:

```json
{
  "GDAI_MCP_SERVER_PORT": "3571",
  "GDAI_RUNTIME_SERVER_PORT": "3572",
  "UV_CACHE_DIR": "C:/Users/ceza/Documents/Spacetimedb/.runtime/uv-cache"
}
```

## Uso com Codex MCP

Com o projeto aberto no Godot:

```powershell
codex mcp add godot-mcp-spacetimedb `
  --env GDAI_MCP_SERVER_PORT=3571 `
  --env GDAI_RUNTIME_SERVER_PORT=3572 `
  --env UV_CACHE_DIR=C:/Users/ceza/Documents/Spacetimedb/.runtime/uv-cache `
  -- C:/Users/ceza/.local/bin/uv.exe run C:/Users/ceza/Documents/Spacetimedb/Cliente/space-m-mo/addons/gdai-mcp-plugin-godot/gdai_mcp_server.py
```

## Uso com Gemini CLI (Alternativa HTTP Direta)

Se as ferramentas MCP não aparecerem nativamente na CLI (ex: devido a bloqueios de trust no ambiente stdio), é obrigatório utilizar o bypass HTTP direto contra o servidor do plugin Godot.

**Regra de Payload JSON-RPC:**
A API `/call-tool` exige estritamente a chave `tool_args` (mesmo vazia), não `arguments` nem corpo vazio.

**Script Python de Bypass (Exemplo PowerShell):**
```powershell
python -c "import urllib.request, json; req = urllib.request.Request('http://localhost:3571/call-tool', data=json.dumps({'tool_name': 'get_godot_errors', 'tool_args': {}}).encode('utf-8'), headers={'Content-Type': 'application/json'}); print(urllib.request.urlopen(req).read().decode('utf-8'))"
```

## Duas instancias do Godot (teste multiplayer local)

- A primeira instancia sobe o runtime server na porta `3572`.
- A segunda instancia detecta que a porta esta ocupada e **pula o runtime server sem erro fatal**.
- Isso evita ruido do tipo:
  - `Runtime server failed to start: Port 3572 is already in use.`

Implementacao aplicada em:
- `Cliente/space-m-mo/addons/gdai-mcp-plugin-godot/gdai_mcp_runtime.gd`
- Pre-check de porta antes de instanciar `GDAIRuntimeServer`.

## Gate rapido de validacao

1. Abrir projeto no Godot.
2. Confirmar plugin habilitado em `Project > Project Settings > Plugins`.
3. Rodar duas instancias e validar:
   - Instancia 1: runtime sobe normalmente.
   - Instancia 2: log de `Runtime server skipped: port 3572 already in use.`
4. Validar tools MCP no cliente conectado a instancia principal.

## Modo padrao de diagnostico (obrigatorio)

Quando for analisar estado do jogo via MCP, usar este fluxo:

1. Chamar `get_godot_errors` antes de qualquer conclusao.
2. Ler `Session Runtime Error`:
   - `Sessao de depuracao fechada` = nao ha cena rodando agora.
3. Ler `Recent output logs` para sinais funcionais:
   - `[Main] ... instanced`
   - `connection_state_changed => connected`
   - `EntityManager joined/moved/left`
4. Tratar ruido conhecido:
   - `Runtime server skipped: port 3572 already in use` e esperado com 2 instancias locais.
5. Se logs antigos atrapalharem, executar `clear_output_logs` e repetir teste.

Resumo de interpretacao:
- `funcional`: sessao ativa + sinais esperados.
- `funcional com ruido`: fluxo ok + aviso de porta/runtime.
- `com bug`: falha funcional confirmada por log (sem conexao, crash, reducer/signal quebrado).

## Ordem obrigatoria (Spacetime + Godot)

Para evitar os erros `10061` e `404`:

1. Subir Spacetime local no `data-dir` padrao do projeto:
```powershell
cd C:\Users\ceza\Documents\Spacetimedb
spacetime start --listen-addr 127.0.0.1:3000 --data-dir .runtime/spacetimedb-data
```
2. Publicar banco `mmorpg-local` na mesma instancia:
```powershell
spacetime publish --server local -p rust/server mmorpg-local -y
```
3. Validar SQL:
```powershell
spacetime sql --server local mmorpg-local "SELECT * FROM player LIMIT 5"
```
4. So depois abrir cliente(s) no Godot.

Atalho recomendado:

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\ceza\Documents\Spacetimedb\tools\dev-up.ps1
```

Preflight obrigatorio antes do play:

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\ceza\Documents\Spacetimedb\tools\preflight-godot-runtime.ps1
```

Auto-correção de ambiente:

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\ceza\Documents\Spacetimedb\tools\preflight-godot-runtime.ps1 -AutoFix
```

Probe opcional de headless (diagnostico, sem bloquear a sessao):

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\ceza\Documents\Spacetimedb\tools\preflight-godot-runtime.ps1 -ProbeGodotHeadless
```

Modo estrito para validar headless como gate:

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\ceza\Documents\Spacetimedb\tools\preflight-godot-runtime.ps1 -ProbeGodotHeadless -RequireHeadlessHealthy
```

Probe em lote de clientes headless (Sprint C):

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\ceza\Documents\Spacetimedb\tools\godot-headless-batch-probe.ps1 -Instances 2
```

Warmup de readiness headless sem depender do runtime Spacetime:

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\ceza\Documents\Spacetimedb\tools\observability-warmup.ps1 -SkipSpacetimeProbes -HeadlessProbeInstances 2 -HeadlessProbeDryRun
```

Validacao unificada de sessao:

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\ceza\Documents\Spacetimedb\tools\session-validate.ps1 -ProbeHeadless -HeadlessDryRun -HeadlessInstances 1
```

Importante:
- Se `rust/target` foi apagado, a `mmorpg_client.dll` some.
- Sem DLL, o Godot acusa `SpacetimeManager class not found` / `GDExtension dynamic library not found`.
- Nessa situacao o passo minimo e:
```powershell
cargo build --manifest-path C:\Users\ceza\Documents\Spacetimedb\rust\Cargo.toml -p mmorpg-client
```

Interpretacao:
- `10061`: servidor nao esta aceitando conexao.
- `404` em `/v1/database/mmorpg-local/...`: banco nao publicado nessa instancia/data-dir.

## Referencias oficiais

- https://gdaimcp.com/docs/installation
- https://gdaimcp.com/docs/configuration
- https://gdaimcp.com/docs/common-issues
