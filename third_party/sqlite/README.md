# SQLite amalgamation (Windows bundle)

Not committed (large C file). Fetch:

```
powershell -File tools/windows/fetch_sqlite.ps1
```

Produces `sqlite3.c` and `sqlite3.h` here. Linux stays on system `libsqlite3-dev` unless you pass `-Dbundle-sqlite=true`.
