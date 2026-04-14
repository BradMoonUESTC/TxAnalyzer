#!/usr/bin/env python3
"""
Contract decompilation module.
Takes a contract address as input, outputs optimized Solidity source code.

Usage (from repo root):
  source venv/bin/activate
  python scripts/decompile.py
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import os
import requests
import json
import tempfile
from datetime import datetime
from typing import Dict, Any, Optional, Tuple
from txanalyzer.tx_analyzer import TransactionTraceAnalyzer
from txanalyzer.heimdall_api import decompile

class ContractDecompiler:
    """Contract decompiler class"""
    
    def __init__(self, network: str = "bsc", *, output_local_dir: str = "output/local"):
        self.analyzer = TransactionTraceAnalyzer(network)
        self.etherscan_api_key = self.analyzer.etherscan_api_key
        self.output_local_dir = output_local_dir
        
    def ask_vul(self, prompt: str) -> str:
        """Call LLM API for code optimization"""
        model = os.environ.get('VUL_MODEL', 'gpt-4o-mini')
        api_key = os.environ.get('OPENAI_API_KEY')
        api_base = os.environ.get('OPENAI_API_BASE')
        
        if not api_key or not api_base:
            print("Error: please set OPENAI_API_KEY and OPENAI_API_BASE environment variables")
            return ""
        
        headers = {
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {api_key}'
        }

        data = {
            'model': model,
            'messages': [
                {
                    'role': 'user',
                    'content': prompt
                }
            ]
        }

        try:
            response = requests.post(f'https://{api_base}/v1/chat/completions', 
                                   headers=headers, 
                                   json=data)
            response.raise_for_status()
            response_data = response.json()
            if 'choices' in response_data and len(response_data['choices']) > 0:
                return response_data['choices'][0]['message']['content']
            else:
                return ""
        except requests.exceptions.RequestException as e:
            print(f"LLM API call failed. Error: {str(e)}")
            return ""
    
    def get_contract_bytecode(self, contract_address: str) -> Optional[str]:
        """Retrieve contract bytecode"""
        print(f"Fetching bytecode for contract {contract_address}...")
        
        try:
            bytecode = self.analyzer._get_contract_bytecode(contract_address)
            if bytecode:
                print(f"Successfully fetched bytecode, length: {len(bytecode)} characters")
                return bytecode
            print("Contract may not exist or has no code")
            return None
                
        except Exception as e:
            print(f"Failed to fetch bytecode: {e}")
            return None
    
    def get_contract_info(self, contract_address: str) -> Dict[str, Any]:
        """Retrieve basic contract information"""
        print(f"Fetching basic info for contract {contract_address}...")
        
        try:
            contract_info = self.analyzer.get_contract_info_from_etherscan(contract_address)
            return contract_info
        except Exception as e:
            print(f"Failed to fetch contract info: {e}")
            return {
                'address': contract_address,
                'contract_name': 'Unknown',
                'has_source_code': False,
                'error': str(e)
            }
    
    def heimdall_decompile(self, contract_address: str, bytecode: str) -> Tuple[Optional[str], Optional[str]]:
        """Decompile contract using Heimdall"""
        print("Decompiling contract with Heimdall...")
        
        try:
            try:
                os.makedirs(self.output_local_dir, exist_ok=True)
            except Exception:
                pass

            with tempfile.NamedTemporaryFile(mode='w', suffix='.bin', delete=False) as temp_file:
                temp_file.write(bytecode)
                temp_file_path = temp_file.name
            
            contract_info = self.get_contract_info(contract_address)
            contract_name = contract_info.get('contract_name', 'DecompiledContract')
            
            result = decompile(
                target=temp_file_path,
                name=contract_name,
                include_sol=True,
                include_yul=False
            )
            
            os.unlink(temp_file_path)
            
            sol_file_default = f"output/local/{contract_name}-decompiled.sol"
            abi_file_default = f"output/local/{contract_name}-abi.json"
            sol_file = os.path.join(self.output_local_dir, f"{contract_name}-decompiled.sol")
            abi_file = os.path.join(self.output_local_dir, f"{contract_name}-abi.json")

            if self.output_local_dir != "output/local":
                try:
                    if os.path.exists(sol_file_default) and not os.path.exists(sol_file):
                        os.replace(sol_file_default, sol_file)
                    if os.path.exists(abi_file_default) and not os.path.exists(abi_file):
                        os.replace(abi_file_default, abi_file)
                except Exception:
                    pass
            
            sol_code = None
            abi_code = None
            
            if os.path.exists(sol_file):
                with open(sol_file, 'r', encoding='utf-8') as f:
                    sol_code = f.read()
                print(f"Successfully read decompiled Solidity code: {sol_file}")
            else:
                if os.path.exists(sol_file_default):
                    with open(sol_file_default, 'r', encoding='utf-8') as f:
                        sol_code = f.read()
                    print(f"Successfully read decompiled Solidity code (default dir): {sol_file_default}")
                else:
                    print(f"Warning: decompiled Solidity file not found: {sol_file} or {sol_file_default}")
            
            if os.path.exists(abi_file):
                with open(abi_file, 'r', encoding='utf-8') as f:
                    abi_code = f.read()
                print(f"Successfully read ABI file: {abi_file}")
            else:
                if os.path.exists(abi_file_default):
                    with open(abi_file_default, 'r', encoding='utf-8') as f:
                        abi_code = f.read()
                    print(f"Successfully read ABI file (default dir): {abi_file_default}")
                else:
                    print(f"Warning: ABI file not found: {abi_file} or {abi_file_default}")
            
            return sol_code, abi_code
            
        except Exception as e:
            print(f"Heimdall decompilation failed: {e}")
            try:
                os.unlink(temp_file_path)
            except:
                pass
            return None, None
    
    def optimize_with_ai(self, raw_sol_code: str, abi_code: str, contract_address: str) -> str:
        """Optimize decompiled code using LLM"""
        print("Optimizing decompiled code with LLM...")
        
        prompt = f"""
You are a professional Solidity smart contract developer and code auditor. I have a smart contract that was recovered from bytecode using the Heimdall decompiler. Please help optimize and refactor it to make it clearer, more professional, and easier to understand.

Contract address: {contract_address}

Raw decompiled code:
```solidity
{raw_sol_code}
```

ABI information:
```json
{abi_code}
```

Please complete the following tasks:

1. **Code cleanup and optimization**:
   - Replace all generic variable names like `var_a`, `var_b` with meaningful names
   - Simplify complex logic for readability
   - Remove unnecessary code and duplicate logic
   - Add appropriate comments

2. **Function refactoring**:
   - Add clear functional description comments to all functions
   - Optimize function parameter naming
   - Clean up function logic flow

3. **Contract structure optimization**:
   - Add appropriate state variable comments
   - Optimize storage layout
   - Add comments for event and error definitions

4. **Security analysis**:
   - Identify and annotate key security mechanisms
   - Flag potential security issues (if any)
   - Explain complex access control logic

5. **Business logic analysis**:
   - Analyze and annotate core business logic
   - Identify special token features and mechanisms
   - Explain interaction logic with other contracts

Please output a complete, optimized Solidity contract including:
- Clear contract name and description
- Complete import statements
- Detailed comments
- Optimized variable and function naming
- Clean code structure

Ensure code readability and professionalism while preserving the original functional logic.
"""
        
        try:
            optimized_code = self.ask_vul(prompt)
            if optimized_code:
                print("LLM optimization complete!")
                return optimized_code
            else:
                print("LLM optimization failed, returning raw code")
                return raw_sol_code
        except Exception as e:
            print(f"Error during LLM optimization: {e}")
            return raw_sol_code
    
    def decompile_contract(self, contract_address: str, save_to_file: bool = True) -> Dict[str, Any]:
        """Full contract decompilation pipeline"""
        print(f"Starting decompilation for contract: {contract_address}")
        print("=" * 60)
        
        contract_info = self.get_contract_info(contract_address)
        
        bytecode = self.get_contract_bytecode(contract_address)
        if not bytecode:
            return {
                'success': False,
                'error': 'Failed to fetch contract bytecode',
                'contract_info': contract_info
            }
        
        raw_sol_code, abi_code = self.heimdall_decompile(contract_address, bytecode)
        if not raw_sol_code:
            return {
                'success': False,
                'error': 'Heimdall decompilation failed',
                'contract_info': contract_info,
                'bytecode': bytecode
            }
        
        optimized_sol_code = self.optimize_with_ai(raw_sol_code, abi_code or "", contract_address)
        
        result = {
            'success': True,
            'contract_address': contract_address,
            'contract_info': contract_info,
            'bytecode': bytecode,
            'raw_sol_code': raw_sol_code,
            'abi_code': abi_code,
            'optimized_sol_code': optimized_sol_code,
            'timestamp': datetime.now().isoformat()
        }
        
        if save_to_file:
            self.save_results(result)
        
        print("=" * 60)
        print("Decompilation complete!")
        
        return result
    
    def save_results(self, result: Dict[str, Any]):
        """Save decompilation results to files"""
        contract_address = result['contract_address']
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        output_dir = "decompiled_contracts"
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)
        
        sol_filename = f"{output_dir}/{contract_address.replace('0x', '')}_optimized_{timestamp}.sol"
        with open(sol_filename, 'w', encoding='utf-8') as f:
            f.write(result['optimized_sol_code'])
        print(f"Optimized Solidity code saved to: {sol_filename}")
        
        raw_sol_filename = f"{output_dir}/{contract_address.replace('0x', '')}_raw_{timestamp}.sol"
        with open(raw_sol_filename, 'w', encoding='utf-8') as f:
            f.write(result['raw_sol_code'])
        print(f"Raw decompiled code saved to: {raw_sol_filename}")
        
        if result.get('abi_code'):
            abi_filename = f"{output_dir}/{contract_address.replace('0x', '')}_abi_{timestamp}.json"
            with open(abi_filename, 'w', encoding='utf-8') as f:
                f.write(result['abi_code'])
            print(f"ABI saved to: {abi_filename}")
        
        result_filename = f"{output_dir}/{contract_address.replace('0x', '')}_full_result_{timestamp}.json"
        with open(result_filename, 'w', encoding='utf-8') as f:
            simplified_result = {
                'success': result['success'],
                'contract_address': result['contract_address'],
                'contract_info': result['contract_info'],
                'timestamp': result['timestamp'],
                'files': {
                    'optimized_sol': sol_filename,
                    'raw_sol': raw_sol_filename,
                    'abi': abi_filename if result.get('abi_code') else None
                }
            }
            json.dump(simplified_result, f, indent=2, ensure_ascii=False)
        print(f"Full result info saved to: {result_filename}")


def main():
    if not os.environ.get('OPENAI_API_KEY'):
        print("Please set the OPENAI_API_KEY environment variable")
        return
    
    if not os.environ.get('OPENAI_API_BASE'):
        print("Please set the OPENAI_API_BASE environment variable")
        return
    
    decompiler = ContractDecompiler()
    
    contract_address = "0x7212de58f97ad6c28623752479acaeb6b15ad006"
    
    result = decompiler.decompile_contract(contract_address)
    
    if result['success']:
        print("\nDecompilation succeeded!")
        print(f"Contract address: {result['contract_address']}")
        print(f"Contract name: {result['contract_info'].get('contract_name', 'Unknown')}")
        print(f"Optimized code length: {len(result['optimized_sol_code'])} characters")
    else:
        print(f"\nDecompilation failed: {result['error']}")


if __name__ == "__main__":
    main()
