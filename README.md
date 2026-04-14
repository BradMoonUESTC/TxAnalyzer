# TxAnalyzer

区块链交易分析工具。一键拉取交易产物（trace、合约源码、opcode），并通过 Codex 自动化分析攻击交易。

## 快速开始

```bash
source venv/bin/activate
pip install -r requirements.txt
python scripts/pull_artifacts.py --network bsc --tx 0xYOUR_TX_HASH
```

## 前置配置：`config.json`

把 `config_template.json` 复制为 `config.json` 并填入 API Key：

```json
{
  "networks": {
    "bsc": {
      "name": "BSC Mainnet",
      "rpc_url": "https://bnb-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_API_KEY",
      "etherscan_api_key": "YOUR_BSCSCAN_API_KEY",
      "etherscan_base_url": "https://api.etherscan.io/v2/api",
      "chain_id": 56
    }
  },
  "default_network": "bsc"
}
```

## 项目结构

```
TxAnalyzer/
├── docs/                  # 分析方法论与规范
│   ├── ATTACK_TX_ANALYSIS_METHODOLOGY.md
│   ├── ATTACK_TX_ANALYSIS_MODULES.md
│   ├── ATTACK_TX_ANALYSIS_SPEC.md
│   └── codex_usage.md
├── txanalyzer/            # 核心分析库
│   ├── tx_analyzer.py     # TransactionTraceAnalyzer
│   ├── transaction_processor.py
│   └── heimdall_api.py
├── codex/                 # Codex CLI 集成
│   ├── client.py          # Codex CLI 封装
│   └── analysis.py        # 全流程编排（拉取 → 分析）
├── scripts/               # CLI 入口脚本
│   ├── pull_artifacts.py  # 拉取交易产物
│   ├── analyze.py         # Codex 一键分析
│   ├── backfill_opcodes.py
│   ├── cleanup.py         # 清理交易产物
│   └── decompile.py       # 合约反编译
├── script/                # Foundry Solidity 脚本
├── lib/forge-std/         # Foundry 依赖
├── config.json            # 网络配置（不提交）
├── config_template.json   # 配置模板
├── foundry.toml           # Foundry 配置
└── requirements.txt
```

## CLI 用法

### 拉取交易产物

```bash
python scripts/pull_artifacts.py --network bsc --tx 0x...
```

常用参数：
- `--tx`：必填，交易哈希
- `--network`：可选，默认 `bsc`
- `--timeout`：可选，默认 `120`
- `--skip-opcode`：跳过 `debug_traceTransaction`
- `--reuse-log`：复用已有 log 文件

### Codex 一键分析

```bash
python scripts/analyze.py --network bsc --tx 0x...
```

### 清理交易产物

```bash
python scripts/cleanup.py --tx 0x... --dry-run
python scripts/cleanup.py --tx 0x...
```

### 合约反编译

```bash
python scripts/decompile.py
```

## 输出位置

执行完成后生成目录：`transactions/<tx_hash>/`（目录内自带 `README.md` 说明各子目录含义）。
