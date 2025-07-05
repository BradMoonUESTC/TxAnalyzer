# TxAnalyzer - Blockchain Transaction Analysis Tool

TxAnalyzer is a tool for analyzing blockchain transactions that supports multiple networks (Ethereum, Base, Polygon, Arbitrum, Optimism, BSC, etc.), capable of in-depth analysis of transaction call chains, contract interactions, and potential attack behaviors.

## Features

- 🔍 **Multi-Network Support**: Supports Ethereum, Base, Polygon, Arbitrum, Optimism, BSC, and other blockchain networks
- 📊 **Transaction Tracing**: Complete transaction call chain analysis, including internal and external calls
- 🔧 **Contract Information**: Automatically retrieves contract source code, ABI, and bytecode information. If contract has no source code, automatically decompiles based on bytecode and attempts to recover source code using large language models
- 📈 **Visualization Reports**: Generates detailed transaction analysis reports
- 🛡️ **Attack Analysis**: Specialized in-depth analysis functionality for attack transactions
- 💾 **Caching Mechanism**: Function signature caching to improve analysis efficiency
- 🤖 **AI-Driven Analysis**: Provides professional prompt templates for automatic transaction root cause analysis in Cursor, supporting vulnerability analysis, attack path reconstruction, POC generation, and other intelligent features

## Important Notes

Currently, this tool simply outputs trace and contract data for analysis by Cursor. The actual analysis process has some file retrieval errors that need optimization of file organization.

No automated agent development has been implemented as it's quite complex. Those interested can continue development.

Anyway, all data has been collected. We need to create a good file layout that allows Cursor agent to effectively search and analyze files.

**Note for Native English Speakers**: The original Chinese comments mention not implementing overly automated agent scripts unless intended as a commercial product. The main issue is that file search and analysis sometimes fail because the call tree structure is too large, with hundreds or thousands of calls at once, requiring guidance on how to search effectively.

## Installation and Environment Setup

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Configure Network Information

Copy the configuration template and configure your network information:

```bash
cp config_template.json config.json
```

Edit the `config.json` file and fill in your API keys and RPC node information:

```json
{
  "networks": {
    "ethereum": {
      "name": "Ethereum Mainnet",
      "rpc_url": "Your_Ethereum_RPC_URL",
      "etherscan_api_key": "Your_Etherscan_API_KEY",
      "etherscan_base_url": "https://api.etherscan.io/v2/api",
      "chain_id": 1
    },
    "bsc": {
      "name": "BSC Mainnet",
      "rpc_url": "Your_BSC_RPC_URL",
      "etherscan_api_key": "Your_BscScan_API_KEY",
      "etherscan_base_url": "https://api.bscscan.com/api",
      "chain_id": 56
    }
  },
  "default_network": "ethereum"
}
```

## Usage

### Step 1: Analyze Transaction

Use `tx_analyzer.py` to analyze target transactions:

```python
from tx_analyzer import TransactionTraceAnalyzer

# Initialize analyzer (using default network)
analyzer = TransactionTraceAnalyzer()

# Or specify a specific network
analyzer = TransactionTraceAnalyzer(network='bsc')

# Analyze transaction
tx_hash = "0x_your_transaction_hash"
trace_data = analyzer.get_transaction_trace(tx_hash)
parsed_data = analyzer.parse_trace_data(trace_data)

# Save analysis results
analyzer.save_to_json(parsed_data, f"tx_trace_{tx_hash[:10]}")
analyzer.save_contract_info_to_json(parsed_data, f"tx_contracts_{tx_hash[:10]}")

# Generate analysis report
report = analyzer.generate_summary_report(parsed_data)
analyzer.save_report(report, f"tx_report_{tx_hash[:10]}")
```

### Step 2: Process Analysis Results

Use `transaction_processor.py` to process and organize analysis results:

```python
from transaction_processor import TransactionProcessor

# Initialize processor
processor = TransactionProcessor()

# Process all files for a specific transaction
processor.process_transaction(tx_hash)

# Or process all transactions
processor.process_all_transactions()

# View available transactions
available_transactions = processor.list_available_transactions()
print("Available transactions:", available_transactions)
```

After execution, files will be organized in the `transactions/` directory with the following structure:

```
transactions/
└── 0x_your_transaction_hash/
    ├── contracts/           # Contract information
    │   ├── contract_address1.json
    │   └── contract_address2.json
    ├── trace/              # Transaction call chain
    │   ├── transaction_info.json
    │   ├── 0.json          # 1st call
    │   ├── 1_0.json        # 1st sub-call of 2nd call
    │   └── ...
    └── tx_report.txt       # Transaction analysis report
```

### Step 3: Analyze Attack Transactions

Use the analysis template in `prompt.md` for in-depth analysis of attack transactions. You can provide the following information to Cursor:

**Note for Native English Speakers**: The original prompt.md is in Chinese and contains detailed analysis templates. Native English speakers could help translate these prompts for better international usage.

## Detailed Usage Examples

### Complete Analysis Workflow

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from tx_analyzer import TransactionTraceAnalyzer
from transaction_processor import TransactionProcessor

def analyze_attack_transaction(tx_hash, network='ethereum'):
    """Complete workflow for analyzing attack transactions"""
    
    print(f"Starting analysis of transaction: {tx_hash}")
    print(f"Using network: {network}")
    
    # Step 1: Initialize analyzer
    analyzer = TransactionTraceAnalyzer(network=network)
    
    # Step 2: Get transaction trace data
    print("Retrieving transaction trace data...")
    trace_data = analyzer.get_transaction_trace(tx_hash)
    
    # Step 3: Parse trace data
    print("Parsing transaction data...")
    parsed_data = analyzer.parse_trace_data(trace_data)
    
    # Step 4: Save analysis results
    print("Saving analysis results...")
    analyzer.save_to_json(parsed_data, f"tx_trace_{tx_hash[:10]}")
    analyzer.save_contract_info_to_json(parsed_data, f"tx_contracts_{tx_hash[:10]}")
    
    # Step 5: Generate analysis report
    print("Generating analysis report...")
    report = analyzer.generate_summary_report(parsed_data)
    analyzer.save_report(report, f"tx_report_{tx_hash[:10]}")
    
    # Step 6: Process and organize results
    print("Processing and organizing results...")
    processor = TransactionProcessor()
    processor.process_transaction(tx_hash)
    
    print(f"Analysis complete! Results saved in: transactions/{tx_hash}/")
    print("You can now use AI assistant and prompt.md template for in-depth attack transaction analysis")

# Usage example
if __name__ == "__main__":
    # Analyze attack transaction on BSC network
    attack_tx = "0x_your_attack_transaction_hash"
    analyze_attack_transaction(attack_tx, network='bsc')
```

## Output Files Description

### Transaction Trace Files (trace/)
- `transaction_info.json`: Basic transaction information
- `number.json`: Detailed information for each call, numbered by call order
- `number_number.json`: Nested calls, format: `parent_call_index_child_call_index`

### Contract Information Files (contracts/)
- `contract_address.json`: Contains contract source code, ABI, bytecode, and other information

### Analysis Report (tx_report.txt)
- Transaction overview
- Call chain analysis
- Value transfer analysis
- Function call statistics
- Potential risk identification

## Supported Networks

- **Ethereum**: Ethereum Mainnet
- **Base**: Base Mainnet
- **Polygon**: Polygon Mainnet
- **Arbitrum**: Arbitrum One
- **Optimism**: Optimism Mainnet
- **BSC**: Binance Smart Chain

## Frequently Asked Questions

### Q: How to get API keys?
A: 
- **Etherscan**: Visit https://etherscan.io/apis
- **BscScan**: Visit https://bscscan.com/apis
- **Other networks**: Visit corresponding blockchain explorers

### Q: How to get RPC nodes?
A: 
- Use public RPC nodes (with limitations)
- Register with Infura, Alchemy, QuickNode, etc.
- Run your own node

### Q: How is performance when analyzing large transactions?
A: 
- Tool includes caching mechanism, repeated analysis will be faster
- Large transactions may take several minutes
- Recommend using high-performance RPC nodes

### Q: How to analyze contracts without source code?
A: 
- Tool automatically retrieves bytecode
- Supports decompilation analysis (requires additional tool heimdall)
- Can infer functionality through function signatures

**Note for Native English Speakers**: The original Chinese version contains more detailed explanations and nuanced descriptions that could benefit from native English translation to improve clarity and readability.

## Contributing

Issues and Pull Requests are welcome to improve this tool!

## License

MIT License 