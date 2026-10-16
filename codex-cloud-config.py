import asyncio
import json
import sys


async def configure(playwright):
    process = await asyncio.create_subprocess_exec(
        "codex", "app-server", "--stdio",
        stdin=asyncio.subprocess.PIPE,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.DEVNULL,
    )

    async def request(request_id, method, params):
        process.stdin.write((json.dumps({"id": request_id, "method": method, "params": params}) + "\n").encode())
        await process.stdin.drain()
        while line := await process.stdout.readline():
            reply = json.loads(line)
            if reply.get("id") == request_id:
                if "error" in reply:
                    raise RuntimeError(reply["error"]["message"])
                return reply["result"]
        raise RuntimeError("Codex app-server exited before its reply")

    try:
        await asyncio.wait_for(request(1, "initialize", {
            "clientInfo": {"name": "claude-harness-cloud-setup", "version": "1"},
            "capabilities": {"experimentalApi": True},
        }), timeout=20)
        process.stdin.write(b'{"method":"initialized"}\n')
        await process.stdin.drain()
        await asyncio.wait_for(request(2, "config/batchWrite", {"edits": [
            {
                "keyPath": "mcp_servers.context7",
                "value": {"url": "https://mcp.context7.com/mcp"},
                "mergeStrategy": "replace",
            },
            {
                "keyPath": "mcp_servers.playwright",
                "value": {"command": playwright, "args": ["--headless", "--isolated", "--browser", "chromium"]},
                "mergeStrategy": "replace",
            },
        ]}), timeout=20)
    finally:
        if process.returncode is None:
            process.terminate()
            try:
                await asyncio.wait_for(process.wait(), timeout=3)
            except asyncio.TimeoutError:
                process.kill()
                await process.wait()


if __name__ == "__main__":
    try:
        asyncio.run(configure(sys.argv[1]))
    except (OSError, RuntimeError, asyncio.TimeoutError) as error:
        sys.exit(f"codex-cloud: MCP configuration failed: {error or type(error).__name__}")
    print("codex-cloud: MCP configuration written")
