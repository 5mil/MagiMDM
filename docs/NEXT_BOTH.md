# Next both stacks (apply on tank after git pull)

## MagiMDM
`src/lists.zig` is on main. `src/main.zig` on GitHub may still stub devices until you paste:

```zig
const lists = @import("lists.zig");
```

Gate `/ai` with the other pages.

```zig
const out = try lists.devicesJson(a, conn);
defer a.free(out);
return reply(w, "200 OK", "application/json", "", out);
```

same for `commsJson`.

GET `/ai` → `page(..., "web/ai.html")`.

POST `/devices/bulk`: INSERT device_policies / commands (see local patch if present).

Then: `git pull && /opt/zig/zig build` restart zig-mdm. Desk fleet should list enrolled rows.

## Arcis
`src/dashboard/static_index.html` is on main. Wire GET `/` in `tier.zig` to serve it (`@embedFile` from handlers). `./tools/pull_gguf.sh r1-1.5b-q4` then:

```bash
./zig-out/bin/arcis --tier forma --port 9090 --model models/gguf/DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf
```

Open http://192.168.50.143:9090/
