# TxAnalyzer - 区块链交易分析工具

TxAnalyzer是一个用于分析区块链交易的工具，支持多个网络（以太坊、Base、Polygon、Arbitrum、Optimism、BSC等），能够深入分析交易的调用链路、合约交互和潜在的攻击行为。

## 功能特点

- 🔍 **多网络支持**: 支持以太坊、Base、Polygon、Arbitrum、Optimism、BSC等多个区块链网络
- 📊 **交易追踪**: 完整的交易调用链路分析，包括内部调用和外部调用
- 🔧 **合约信息**: 自动获取合约源码、ABI和字节码信息，如果合约没有源码，自动根据bytecode进行反编译，并尝试使用大模型进行恢复源代码
- 📈 **可视化报告**: 生成详细的交易分析报告
- 🛡️ **攻击分析**: 专门针对攻击交易的深度分析功能
- 💾 **缓存机制**: 函数签名缓存，提高分析效率
- 🤖 **AI驱动分析**: 提供专业的prompt模板，可在Cursor中自动分析交易根因，支持漏洞成因分析、攻击路径重现、POC生成等智能化功能

## 重要
当前是单纯的输出trace与contract，并交给cursor进行分析，实际分析过程出现不少文件获取错误的问题，还需要优化文件组织形式

没有进行自动化agent进行相关的开发，有点过于复杂了，感兴趣的可以继续开发

反正数据都收集齐了，要做一个好的文件排布，能够让cursor agent，有效的去搜索文件，分析

不做太自动的agent脚本，没啥必要性，除非想要做成对外的产品

主要是现在搜索文件分析有时候还会出现问题，因为call tree的那个结构太多，一次性几千几百的call，得指导下cursor怎么去搜索

## 安装与环境设置

### 1. 安装依赖包

```bash
pip install -r requirements.txt
```

### 2. 配置网络信息

复制配置模板并配置您的网络信息：

```bash
cp config_template.json config.json
```

编辑 `config.json` 文件，填入您的API密钥和RPC节点信息：

```json
{
  "networks": {
    "ethereum": {
      "name": "Ethereum Mainnet",
      "rpc_url": "您的以太坊RPC_URL",
      "etherscan_api_key": "您的Etherscan_API_KEY",
      "etherscan_base_url": "https://api.etherscan.io/v2/api",
      "chain_id": 1
    },
    "bsc": {
      "name": "BSC Mainnet",
      "rpc_url": "您的BSC_RPC_URL",
      "etherscan_api_key": "您的BscScan_API_KEY",
      "etherscan_base_url": "https://api.bscscan.com/api",
      "chain_id": 56
    }
  },
  "default_network": "ethereum"
}
```

## 使用方法

### 步骤1: 分析交易

使用 `tx_analyzer.py` 分析目标交易：

```python
from tx_analyzer import TransactionTraceAnalyzer

# 初始化分析器（使用默认网络）
analyzer = TransactionTraceAnalyzer()

# 或者指定特定网络
analyzer = TransactionTraceAnalyzer(network='bsc')

# 分析交易
tx_hash = "0x你的交易哈希"
trace_data = analyzer.get_transaction_trace(tx_hash)
parsed_data = analyzer.parse_trace_data(trace_data)

# 保存分析结果
analyzer.save_to_json(parsed_data, f"tx_trace_{tx_hash[:10]}")
analyzer.save_contract_info_to_json(parsed_data, f"tx_contracts_{tx_hash[:10]}")

# 生成分析报告
report = analyzer.generate_summary_report(parsed_data)
analyzer.save_report(report, f"tx_report_{tx_hash[:10]}")
```

### 步骤2: 处理分析结果

使用 `transaction_processor.py` 处理和组织分析结果：

```python
from transaction_processor import TransactionProcessor

# 初始化处理器
processor = TransactionProcessor()

# 处理特定交易的所有文件
processor.process_transaction(tx_hash)

# 或者处理所有交易
processor.process_all_transactions()

# 查看可用的交易
available_transactions = processor.list_available_transactions()
print("可用的交易:", available_transactions)
```

执行后，文件会被组织到 `transactions/` 目录下，结构如下：

```
transactions/
└── 0x你的交易哈希/
    ├── contracts/           # 合约信息
    │   ├── 合约地址1.json
    │   └── 合约地址2.json
    ├── trace/              # 交易调用链路
    │   ├── transaction_info.json
    │   ├── 0.json          # 第1个调用
    │   ├── 1_0.json        # 第2个调用的第1个子调用
    │   └── ...
    └── tx_report.txt       # 交易分析报告
```

### 步骤3: 分析攻击交易

使用 `prompt.md` 中的分析模板来深度分析攻击交易。您可以将以下信息提供给Cursor

## 详细使用示例

### 完整的分析流程

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from tx_analyzer import TransactionTraceAnalyzer
from transaction_processor import TransactionProcessor

def analyze_attack_transaction(tx_hash, network='ethereum'):
    """完整分析攻击交易的流程"""
    
    print(f"开始分析交易: {tx_hash}")
    print(f"使用网络: {network}")
    
    # 步骤1: 初始化分析器
    analyzer = TransactionTraceAnalyzer(network=network)
    
    # 步骤2: 获取交易追踪数据
    print("正在获取交易追踪数据...")
    trace_data = analyzer.get_transaction_trace(tx_hash)
    
    # 步骤3: 解析追踪数据
    print("正在解析交易数据...")
    parsed_data = analyzer.parse_trace_data(trace_data)
    
    # 步骤4: 保存分析结果
    print("正在保存分析结果...")
    analyzer.save_to_json(parsed_data, f"tx_trace_{tx_hash[:10]}")
    analyzer.save_contract_info_to_json(parsed_data, f"tx_contracts_{tx_hash[:10]}")
    
    # 步骤5: 生成分析报告
    print("正在生成分析报告...")
    report = analyzer.generate_summary_report(parsed_data)
    analyzer.save_report(report, f"tx_report_{tx_hash[:10]}")
    
    # 步骤6: 处理和组织结果
    print("正在处理和组织结果...")
    processor = TransactionProcessor()
    processor.process_transaction(tx_hash)
    
    print(f"分析完成！结果保存在: transactions/{tx_hash}/")
    print("您现在可以使用AI助手和prompt.md模板来深度分析攻击交易")

# 使用示例
if __name__ == "__main__":
    # 分析BSC网络上的攻击交易
    attack_tx = "0x你的攻击交易哈希"
    analyze_attack_transaction(attack_tx, network='bsc')
```

## 输出文件说明

### 交易追踪文件 (trace/)
- `transaction_info.json`: 交易基本信息
- `数字.json`: 每个调用的详细信息，按调用顺序编号
- `数字_数字.json`: 嵌套调用，格式为 `父调用index_子调用index`

### 合约信息文件 (contracts/)
- `合约地址.json`: 包含合约源码、ABI、字节码等信息

### 分析报告 (tx_report.txt)
- 交易概览
- 调用链路分析
- 价值转移分析
- 函数调用统计
- 潜在风险识别

## 支持的网络

- **Ethereum**: 以太坊主网
- **Base**: Base主网
- **Polygon**: Polygon主网
- **Arbitrum**: Arbitrum One
- **Optimism**: Optimism主网
- **BSC**: Binance Smart Chain

## 常见问题

### Q: 如何获取API密钥？
A: 
- **Etherscan**: 访问 https://etherscan.io/apis
- **BscScan**: 访问 https://bscscan.com/apis
- **其他网络**: 访问对应的区块链浏览器

### Q: 如何获取RPC节点？
A: 
- 使用公共RPC节点（有限制）
- 注册Infura、Alchemy、QuickNode等服务
- 运行自己的节点

### Q: 分析大型交易时性能如何？
A: 
- 工具包含缓存机制，重复分析会更快
- 大型交易可能需要几分钟时间
- 建议使用高性能的RPC节点

### Q: 如何分析没有源码的合约？
A: 
- 工具会自动获取字节码
- 支持反编译分析（需要额外工具heimdall）
- 可以通过函数签名推断功能



## 贡献

欢迎提交Issue和Pull Request来改进这个工具！

## 许可证

MIT License 