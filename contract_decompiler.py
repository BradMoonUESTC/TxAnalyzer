#!/usr/bin/env python3
"""
合约反编译组件
功能：输入合约地址，输出优化后的Solidity源代码
"""

import os
import requests
import json
import tempfile
from datetime import datetime
from typing import Dict, Any, Optional, Tuple
from tx_analyzer import TransactionTraceAnalyzer
from heimdall_api import decompile

class ContractDecompiler:
    """合约反编译器类"""
    
    def __init__(self, etherscan_api_key: str = "R372Q85V9MM66IB33P5P5HTIWU8FZG2QKP"):
        """
        初始化反编译器
        
        Args:
            etherscan_api_key: Etherscan API密钥
        """
        self.etherscan_api_key = etherscan_api_key
        self.analyzer = TransactionTraceAnalyzer("", etherscan_api_key)
        
    def ask_vul(self, prompt: str) -> str:
        """
        调用大模型API进行代码优化
        
        Args:
            prompt: 发送给大模型的提示
            
        Returns:
            大模型返回的优化后代码
        """
        model = os.environ.get('VUL_MODEL', 'gpt-4o-mini')
        api_key = os.environ.get('OPENAI_API_KEY')
        api_base = os.environ.get('OPENAI_API_BASE')
        
        if not api_key or not api_base:
            print("错误: 请设置OPENAI_API_KEY和OPENAI_API_BASE环境变量")
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
            print(f"大模型API调用失败。错误: {str(e)}")
            return ""
    
    def get_contract_bytecode(self, contract_address: str) -> Optional[str]:
        """
        获取合约bytecode
        
        Args:
            contract_address: 合约地址
            
        Returns:
            合约bytecode，如果失败返回None
        """
        print(f"正在获取合约 {contract_address} 的bytecode...")
        
        try:
            # 使用etherscan API获取bytecode
            bytecode_url = f"https://api.etherscan.io/v2/api?chainid=1&module=proxy&action=eth_getCode&address={contract_address}&tag=latest&apikey={self.etherscan_api_key}"
            response = requests.get(bytecode_url, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('result') and data['result'] != '0x':
                    bytecode = data['result']
                    print(f"成功获取bytecode，长度: {len(bytecode)} 字符")
                    return bytecode
                else:
                    print("合约可能不存在或没有代码")
                    return None
            else:
                print(f"HTTP请求失败，状态码: {response.status_code}")
                return None
                
        except Exception as e:
            print(f"获取bytecode失败: {e}")
            return None
    
    def get_contract_info(self, contract_address: str) -> Dict[str, Any]:
        """
        获取合约基本信息
        
        Args:
            contract_address: 合约地址
            
        Returns:
            合约信息字典
        """
        print(f"正在获取合约 {contract_address} 的基本信息...")
        
        try:
            contract_info = self.analyzer.get_contract_info_from_etherscan(contract_address)
            return contract_info
        except Exception as e:
            print(f"获取合约信息失败: {e}")
            return {
                'address': contract_address,
                'contract_name': 'Unknown',
                'has_source_code': False,
                'error': str(e)
            }
    
    def heimdall_decompile(self, contract_address: str, bytecode: str) -> Tuple[Optional[str], Optional[str]]:
        """
        使用Heimdall反编译合约
        
        Args:
            contract_address: 合约地址
            bytecode: 合约bytecode
            
        Returns:
            (反编译的sol代码, ABI代码) 的元组，失败时返回 (None, None)
        """
        print("正在使用Heimdall反编译合约...")
        
        try:
            # 创建临时文件保存bytecode
            with tempfile.NamedTemporaryFile(mode='w', suffix='.bin', delete=False) as temp_file:
                temp_file.write(bytecode)
                temp_file_path = temp_file.name
            
            # 获取合约名称
            contract_info = self.get_contract_info(contract_address)
            contract_name = contract_info.get('contract_name', 'DecompiledContract')
            
            # 执行反编译
            result = decompile(
                target=temp_file_path,
                name=contract_name,
                include_sol=True,
                include_yul=False
            )
            
            # 清理临时文件
            os.unlink(temp_file_path)
            
            # 检查输出文件
            sol_file = f"output/local/{contract_name}-decompiled.sol"
            abi_file = f"output/local/{contract_name}-abi.json"
            
            sol_code = None
            abi_code = None
            
            if os.path.exists(sol_file):
                with open(sol_file, 'r', encoding='utf-8') as f:
                    sol_code = f.read()
                print(f"成功读取反编译的Solidity代码: {sol_file}")
            else:
                print(f"警告: 未找到反编译的Solidity文件: {sol_file}")
            
            if os.path.exists(abi_file):
                with open(abi_file, 'r', encoding='utf-8') as f:
                    abi_code = f.read()
                print(f"成功读取ABI文件: {abi_file}")
            else:
                print(f"警告: 未找到ABI文件: {abi_file}")
            
            return sol_code, abi_code
            
        except Exception as e:
            print(f"Heimdall反编译失败: {e}")
            # 清理临时文件
            try:
                os.unlink(temp_file_path)
            except:
                pass
            return None, None
    
    def optimize_with_ai(self, raw_sol_code: str, abi_code: str, contract_address: str) -> str:
        """
        使用大模型优化反编译的代码
        
        Args:
            raw_sol_code: 原始反编译的Solidity代码
            abi_code: ABI代码
            contract_address: 合约地址
            
        Returns:
            优化后的Solidity代码
        """
        print("正在使用大模型优化反编译代码...")
        
        prompt = f"""
你是一个专业的Solidity智能合约开发者和代码审计师。我有一个通过反编译工具(Heimdall)从字节码还原的智能合约代码，需要你帮助优化和重构，使其更加清晰、专业和易于理解。

合约地址: {contract_address}

原始反编译代码:
```solidity
{raw_sol_code}
```

ABI信息:
```json
{abi_code}
```

请帮我完成以下任务：

1. **代码清理和优化**：
   - 将所有 `var_a`, `var_b` 等通用变量名替换为有意义的变量名
   - 优化复杂的逻辑判断，使其更易读
   - 移除不必要的代码和重复逻辑
   - 添加适当的注释说明

2. **函数重构**：
   - 为所有函数添加清晰的功能描述注释
   - 优化函数的参数命名
   - 整理函数的逻辑流程

3. **合约结构优化**：
   - 添加适当的状态变量注释
   - 优化存储布局
   - 添加事件和错误定义的注释

4. **安全性分析**：
   - 识别并注释关键的安全机制
   - 标注潜在的安全问题（如果有的话）
   - 解释复杂的权限控制逻辑

5. **业务逻辑分析**：
   - 分析并注释核心业务逻辑
   - 识别代币的特殊功能和机制
   - 解释与其他合约的交互逻辑

请输出一个完整的、优化后的Solidity合约代码，包含：
- 清晰的合约名称和描述
- 完整的导入语句
- 详细的注释说明
- 优化后的变量和函数命名
- 清晰的代码结构

请确保代码的可读性和专业性，同时保持原有的功能逻辑不变。
"""
        
        try:
            optimized_code = self.ask_vul(prompt)
            if optimized_code:
                print("大模型优化完成！")
                return optimized_code
            else:
                print("大模型优化失败，返回原始代码")
                return raw_sol_code
        except Exception as e:
            print(f"大模型优化过程中出错: {e}")
            return raw_sol_code
    
    def decompile_contract(self, contract_address: str, save_to_file: bool = True) -> Dict[str, Any]:
        """
        完整的合约反编译流程
        
        Args:
            contract_address: 合约地址
            save_to_file: 是否保存结果到文件
            
        Returns:
            包含反编译结果的字典
        """
        print(f"开始反编译合约: {contract_address}")
        print("=" * 60)
        
        # 步骤1: 获取合约基本信息
        contract_info = self.get_contract_info(contract_address)
        
        # 步骤2: 获取bytecode
        bytecode = self.get_contract_bytecode(contract_address)
        if not bytecode:
            return {
                'success': False,
                'error': '无法获取合约bytecode',
                'contract_info': contract_info
            }
        
        # 步骤3: 使用Heimdall反编译
        raw_sol_code, abi_code = self.heimdall_decompile(contract_address, bytecode)
        if not raw_sol_code:
            return {
                'success': False,
                'error': 'Heimdall反编译失败',
                'contract_info': contract_info,
                'bytecode': bytecode
            }
        
        # 步骤4: 使用大模型优化
        optimized_sol_code = self.optimize_with_ai(raw_sol_code, abi_code or "", contract_address)
        
        # 步骤5: 保存结果
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
        print("反编译完成！")
        
        return result
    
    def save_results(self, result: Dict[str, Any]):
        """
        保存反编译结果到文件
        
        Args:
            result: 反编译结果字典
        """
        contract_address = result['contract_address']
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        # 创建输出目录
        output_dir = "decompiled_contracts"
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)
        
        # 保存优化后的Solidity代码
        sol_filename = f"{output_dir}/{contract_address.replace('0x', '')}_optimized_{timestamp}.sol"
        with open(sol_filename, 'w', encoding='utf-8') as f:
            f.write(result['optimized_sol_code'])
        print(f"优化后的Solidity代码已保存到: {sol_filename}")
        
        # 保存原始反编译代码
        raw_sol_filename = f"{output_dir}/{contract_address.replace('0x', '')}_raw_{timestamp}.sol"
        with open(raw_sol_filename, 'w', encoding='utf-8') as f:
            f.write(result['raw_sol_code'])
        print(f"原始反编译代码已保存到: {raw_sol_filename}")
        
        # 保存ABI
        if result.get('abi_code'):
            abi_filename = f"{output_dir}/{contract_address.replace('0x', '')}_abi_{timestamp}.json"
            with open(abi_filename, 'w', encoding='utf-8') as f:
                f.write(result['abi_code'])
            print(f"ABI已保存到: {abi_filename}")
        
        # 保存完整结果
        result_filename = f"{output_dir}/{contract_address.replace('0x', '')}_full_result_{timestamp}.json"
        with open(result_filename, 'w', encoding='utf-8') as f:
            # 创建一个不包含大文件内容的简化版本用于JSON保存
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
        print(f"完整结果信息已保存到: {result_filename}")


def main():
    """示例使用方法"""
    # 检查环境变量
    if not os.environ.get('OPENAI_API_KEY'):
        print("请设置OPENAI_API_KEY环境变量")
        return
    
    if not os.environ.get('OPENAI_API_BASE'):
        print("请设置OPENAI_API_BASE环境变量")
        return
    
    # 创建反编译器实例
    decompiler = ContractDecompiler()
    
    # 测试合约地址
    contract_address = "0x692df9e2C4f0F3e1AD055120CcaC3c7520f9C512"
    
    # 执行反编译
    result = decompiler.decompile_contract(contract_address)
    
    if result['success']:
        print("\n反编译成功！")
        print(f"合约地址: {result['contract_address']}")
        print(f"合约名称: {result['contract_info'].get('contract_name', 'Unknown')}")
        print(f"优化后代码长度: {len(result['optimized_sol_code'])} 字符")
    else:
        print(f"\n反编译失败: {result['error']}")


if __name__ == "__main__":
    main() 