# ZigMDM tools

## Mock agent

[`mock_agent.py`](./mock_agent.py) — enrolls, polls, and acks without Android.

### Requirements

- Python 3.10+ (stdlib only)
- Running ZigMDM server (default `http://127.0.0.1:8787`)

### Usage

```bash
python3 tools/mock_agent.py --auto --uuid mock-agent-1
python3 tools/mock_agent.py --auto --uuid mock-agent-1 --interval 3
python3 tools/mock_agent.py --auto --uuid mock-agent-1 --once
python3 tools/mock_agent.py --token <HEX_TOKEN> --uuid my-device-1
python3 tools/mock_agent.py --auto --server http://192.168.1.10:8787
```

### Related docs

- [Main README](../README.md)
- [Deploy / TLS](../docs/DEPLOY.md)
- [Android agent](../agent/README.md)
