# Wire desk APIs on tank

```bash
cd ~/magimdm
git pull
chmod +x tools/wire_main.sh
./tools/wire_main.sh
/opt/zig/zig build
# restart zig-mdm
```

After that `/api/parent/devices` uses SQLite. A seed row `lab-android` appears once schema INSERT OR IGNORE is in db.zig (pull this commit's WIRE + next db seed if present).
