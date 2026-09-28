# Next each (this slice)

## MagiMDM
`src/lists.zig` now has `auditJson`.
After `wire_main.sh`, add:

```zig
if (GET /api/parent/audit) {
    const out = try lists.auditJson(a, conn);
    defer a.free(out);
    return reply(... out);
}
```

```bash
cd ~/magimdm && git pull && ./tools/wire_main.sh && ./tools/seed_lab.sh
/opt/zig/zig build   # restart
```

## Arcis
`src/api/rag_scan.zig` keyword-scans `data/library` (copy OpenStax txt here).
POST `/rag` {"query":"algebra"} — wire handleRag to `rag_scan.run` if still stub.

```bash
cd ~/arcis && git pull && mkdir -p data/library
# copy *.txt from MagiMDM data/library if you fetched OER
zig build && ./zig-out/bin/arcis --tier forma
```
