import requests
import json
import os
from datetime import datetime
from typing import Dict, List, Any, Optional
import pandas as pd

class TransactionTraceAnalyzer:
    def __init__(self, rpc_url: str, etherscan_api_key: str = "R372Q85V9MM66IB33P5P5HTIWU8FZG2QKP"):
        self.rpc_url = rpc_url
        self.headers = {'Content-Type': 'application/json'}
        self.log_dir = "log"
        self.etherscan_api_key = etherscan_api_key
        self.etherscan_base_url = "https://api.etherscan.io/v2/api"
        self._ensure_log_directory()
    
    def _ensure_log_directory(self):
        """确保log目录存在"""
        if not os.path.exists(self.log_dir):
            os.makedirs(self.log_dir)
    
    def get_contract_info_from_etherscan(self, address: str) -> Dict[str, Any]:
        """从Etherscan获取合约信息"""
        try:
            # 获取源代码
            source_url = f"{self.etherscan_base_url}?chainid=1&module=contract&action=getsourcecode&address={address}&apikey={self.etherscan_api_key}"
            
            response = requests.get(source_url, timeout=15)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('status') == '1' and data.get('result'):
                    contract_info = data['result'][0]
                    
                    # 如果有源代码，直接返回
                    if contract_info.get('SourceCode') and contract_info['SourceCode'] != '':
                        return {
                            'address': address,
                            'has_source_code': True,
                            'source_code': contract_info.get('SourceCode'),
                            'abi': contract_info.get('ABI'),
                            'contract_name': contract_info.get('ContractName'),
                            'compiler_version': contract_info.get('CompilerVersion'),
                            'optimization_used': contract_info.get('OptimizationUsed'),
                            'runs': contract_info.get('Runs'),
                            'constructor_arguments': contract_info.get('ConstructorArguments'),
                            'evm_version': contract_info.get('EVMVersion'),
                            'library': contract_info.get('Library'),
                            'license_type': contract_info.get('LicenseType'),
                            'proxy': contract_info.get('Proxy'),
                            'implementation': contract_info.get('Implementation'),
                            'bytecode': None
                        }
                    else:
                        # 如果没有源代码，获取字节码
                        bytecode = self._get_contract_bytecode(address)
                        return {
                            'address': address,
                            'has_source_code': False,
                            'source_code': None,
                            'abi': contract_info.get('ABI') if contract_info.get('ABI') else None,
                            'contract_name': contract_info.get('ContractName') if contract_info.get('ContractName') else 'Unknown',
                            'compiler_version': None,
                            'optimization_used': None,
                            'runs': None,
                            'constructor_arguments': None,
                            'evm_version': None,
                            'library': None,
                            'license_type': None,
                            'proxy': contract_info.get('Proxy'),
                            'implementation': contract_info.get('Implementation'),
                            'bytecode': bytecode
                        }
            
            return {
                'address': address,
                'has_source_code': False,
                'source_code': None,
                'abi': None,
                'contract_name': 'Unknown',
                'error': 'Failed to fetch contract info',
                'bytecode': self._get_contract_bytecode(address)
            }
            
        except Exception as e:
            print(f"获取合约信息失败 {address}: {e}")
            return {
                'address': address,
                'has_source_code': False,
                'source_code': None,
                'abi': None,
                'contract_name': 'Unknown',
                'error': str(e),
                'bytecode': self._get_contract_bytecode(address)
            }
    
    def _get_contract_bytecode(self, address: str) -> Optional[str]:
        """获取合约字节码"""
        try:
            bytecode_url = f"{self.etherscan_base_url}?chainid=1&module=proxy&action=eth_getCode&address={address}&tag=latest&apikey={self.etherscan_api_key}"
            
            response = requests.get(bytecode_url, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('status') == '1' and data.get('result'):
                    return data['result']
            
            return None
            
        except Exception as e:
            print(f"获取字节码失败 {address}: {e}")
            return None
    
    def get_function_signature_from_api(self, method_id: str) -> str:
        """通过openchain.xyz API查询函数签名"""
        try:
            # 确保method_id格式正确
            if not method_id.startswith('0x'):
                method_id = '0x' + method_id
            
            url = f"https://api.openchain.xyz/signature-database/v1/lookup?filter=false&function={method_id}"
            
            response = requests.get(url, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('ok') and data.get('result', {}).get('function', {}).get(method_id):
                    functions = data['result']['function'][method_id]
                    if functions:
                        # 返回第一个匹配的函数签名
                        return functions[0]['name']
            
            return method_id  # 如果查询失败，返回原始method_id
            
        except Exception as e:
            print(f"查询函数签名失败 {method_id}: {e}")
            return method_id
    
    def get_transaction_trace(self, tx_hash: str) -> Dict[str, Any]:
        """获取交易追踪数据"""
        payload = json.dumps({
            "method": "trace_transaction",
            "params": [tx_hash],
            "id": 1,
            "jsonrpc": "2.0"
        })
        
        response = requests.post(self.rpc_url, headers=self.headers, data=payload)
        return response.json()
    
    def parse_trace_data(self, trace_response: Dict[str, Any]) -> Dict[str, Any]:
        """解析交易追踪数据"""
        if 'result' not in trace_response:
            return {"error": "无效的追踪数据"}
        
        traces = trace_response['result']
        
        # 解析基本信息
        if not traces:
            return {"error": "空的追踪数据"}
        
        main_trace = traces[0]
        
        parsed_data = {
            "transaction_info": {
                "hash": main_trace.get('transactionHash'),
                "block_number": int(main_trace.get('blockNumber', '0x0'), 16) if isinstance(main_trace.get('blockNumber'), str) else main_trace.get('blockNumber', 0),
                "block_hash": main_trace.get('blockHash'),
                "position": main_trace.get('transactionPosition'),
                "total_gas_used": int(main_trace.get('result', {}).get('gasUsed', '0x0'), 16)
            },
            "call_tree": [],
            "addresses_involved": set(),
            "value_transfers": [],
            "gas_analysis": {
                "total_gas_used": 0,
                "gas_by_call": []
            },
            "function_calls": [],
            "contract_info": {},  # 新增：存储合约信息
            "summary": {
                "total_calls": len(traces),
                "call_types": {},
                "total_value_transferred": 0
            }
        }
        
        # 收集所有涉及的合约地址
        contract_addresses = set()
        
        # 解析每个调用
        for i, trace in enumerate(traces):
            call_info = self._parse_single_trace(trace, i)
            parsed_data["call_tree"].append(call_info)
            
            # 收集地址
            parsed_data["addresses_involved"].add(call_info["from"])
            parsed_data["addresses_involved"].add(call_info["to"])
            
            # 收集合约地址（to地址通常是合约地址）
            if call_info["to"]:
                contract_addresses.add(call_info["to"])
            
            # 收集价值转移
            if call_info["value"] > 0:
                parsed_data["value_transfers"].append({
                    "from": call_info["from"],
                    "to": call_info["to"],
                    "value": call_info["value"],
                    "value_eth": call_info["value"] / 10**18,
                    "trace_index": i
                })
                parsed_data["summary"]["total_value_transferred"] += call_info["value"]
            
            # Gas分析
            parsed_data["gas_analysis"]["gas_by_call"].append({
                "trace_index": i,
                "gas_used": call_info["gas_used"],
                "call_type": call_info["call_type"],
                "function": call_info["function_signature"]
            })
            parsed_data["gas_analysis"]["total_gas_used"] += call_info["gas_used"]
            
            # 统计调用类型
            call_type = call_info["call_type"]
            parsed_data["summary"]["call_types"][call_type] = parsed_data["summary"]["call_types"].get(call_type, 0) + 1
            
            # 收集函数调用
            if call_info["function_signature"]:
                parsed_data["function_calls"].append({
                    "trace_index": i,
                    "function": call_info["function_signature"],
                    "from": call_info["from"],
                    "to": call_info["to"],
                    "gas_used": call_info["gas_used"]
                })
        
        # 获取合约信息
        print(f"正在获取 {len(contract_addresses)} 个合约的信息...")
        for address in contract_addresses:
            if address:  # 确保地址不为空
                print(f"获取合约信息: {address}")
                contract_info = self.get_contract_info_from_etherscan(address)
                parsed_data["contract_info"][address] = contract_info
        
        # 转换set为list用于JSON序列化
        parsed_data["addresses_involved"] = list(parsed_data["addresses_involved"])
        parsed_data["summary"]["total_value_transferred_eth"] = parsed_data["summary"]["total_value_transferred"] / 10**18
        
        return parsed_data
    
    def _parse_single_trace(self, trace: Dict[str, Any], index: int) -> Dict[str, Any]:
        """解析单个追踪记录"""
        action = trace.get('action', {})
        result = trace.get('result', {})
        
        # 解析输入数据中的函数签名
        input_data = action.get('input', '')
        function_signature = self._extract_function_signature(input_data)
        
        return {
            "trace_index": index,
            "trace_address": trace.get('traceAddress', []),
            "call_type": action.get('callType', ''),
            "from": action.get('from', ''),
            "to": action.get('to', ''),
            "value": int(action.get('value', '0x0'), 16),
            "value_eth": int(action.get('value', '0x0'), 16) / 10**18,
            "gas": int(action.get('gas', '0x0'), 16),
            "gas_used": int(result.get('gasUsed', '0x0'), 16),
            "input": input_data,
            "function_signature": function_signature,
            "output": result.get('output', ''),
            "subtraces": trace.get('subtraces', 0),
            "success": 'error' not in result
        }
    
    def _extract_function_signature(self, input_data: str) -> str:
        """从输入数据中提取函数签名"""
        if not input_data or input_data == '0x':
            return ""
        
        # 常见的函数签名映射（作为备用）
        function_signatures = {
            "0xe11013dd": "depositTransaction(address,uint256,uint64,bool,bytes)",
            "0xb7947262": "paused()",
            "0x3dbb202b": "relayMessage(uint256,address,address,uint256,uint256,bytes)",
            "0x1635f5fd": "bridgeETH(uint32,bytes)",
            "0xbf40fac1": "resolve(bytes32)",
            "0xe9e05c42": "sendMessage(address,bytes,uint32)",
            "0xd764ad0b": "depositTransaction(address,uint256,uint64,bool,bytes)",
            "0xcc731b02": "config()"
        }
        
        if len(input_data) >= 10:
            method_id = input_data[:10]
            
            # 首先尝试从API查询
            api_signature = self.get_function_signature_from_api(method_id)
            if api_signature != method_id:
                return api_signature
            
            # 如果API查询失败，使用本地映射
            return function_signatures.get(method_id, method_id)
        
        return ""
    
    def save_to_json(self, data: Dict[str, Any], filename: str = None) -> str:
        """保存数据到JSON文件"""
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            tx_hash = data.get('transaction_info', {}).get('hash', 'unknown')[:10]
            filename = f"tx_trace_{tx_hash}_{timestamp}.json"
        
        filepath = os.path.join(self.log_dir, filename)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        
        return filepath
    
    def save_to_csv(self, data: Dict[str, Any], filename: str = None) -> str:
        """保存调用数据到CSV文件"""
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            tx_hash = data.get('transaction_info', {}).get('hash', 'unknown')[:10]
            filename = f"tx_calls_{tx_hash}_{timestamp}.csv"
        
        filepath = os.path.join(self.log_dir, filename)
        
        # 创建DataFrame
        calls_data = []
        for call in data.get('call_tree', []):
            calls_data.append({
                'trace_index': call['trace_index'],
                'call_type': call['call_type'],
                'from': call['from'],
                'to': call['to'],
                'value_eth': call['value_eth'],
                'gas_used': call['gas_used'],
                'function': call['function_signature'],
                'success': call['success']
            })
        
        df = pd.DataFrame(calls_data)
        df.to_csv(filepath, index=False)
        
        return filepath
    
    def save_contract_info_to_json(self, data: Dict[str, Any], filename: str = None) -> str:
        """保存合约信息到单独的JSON文件"""
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            tx_hash = data.get('transaction_info', {}).get('hash', 'unknown')[:10]
            filename = f"tx_contracts_{tx_hash}_{timestamp}.json"
        
        filepath = os.path.join(self.log_dir, filename)
        
        contract_info = data.get('contract_info', {})
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(contract_info, f, indent=2, ensure_ascii=False)
        
        return filepath
    
    def generate_summary_report(self, data: Dict[str, Any]) -> str:
        """生成交易摘要报告"""
        tx_info = data.get('transaction_info', {})
        summary = data.get('summary', {})
        gas_analysis = data.get('gas_analysis', {})
        contract_info = data.get('contract_info', {})
        
        report = f"""
=== 交易追踪分析报告 ===

基本信息:
- 交易哈希: {tx_info.get('hash', 'N/A')}
- 区块号: {tx_info.get('block_number', 'N/A')}
- 总Gas使用: {tx_info.get('total_gas_used', 0):,}
- 交易位置: {tx_info.get('position', 'N/A')}

调用统计:
- 总调用数: {summary.get('total_calls', 0)}
- 调用类型分布: {summary.get('call_types', {})}
- 总转账金额: {summary.get('total_value_transferred_eth', 0):.6f} ETH

Gas分析:
- 总Gas消耗: {gas_analysis.get('total_gas_used', 0):,}
- 平均每次调用Gas: {gas_analysis.get('total_gas_used', 0) // max(summary.get('total_calls', 1), 1):,}

涉及地址数量: {len(data.get('addresses_involved', []))}
价值转移次数: {len(data.get('value_transfers', []))}
函数调用次数: {len(data.get('function_calls', []))}

=== 合约信息 ===
"""
        
        for address, info in contract_info.items():
            report += f"\n合约地址: {address}\n"
            report += f"  合约名称: {info.get('contract_name', 'Unknown')}\n"
            report += f"  有源代码: {'是' if info.get('has_source_code') else '否'}\n"
            
            if info.get('has_source_code'):
                report += f"  编译器版本: {info.get('compiler_version', 'N/A')}\n"
                report += f"  优化: {info.get('optimization_used', 'N/A')}\n"
                report += f"  许可证: {info.get('license_type', 'N/A')}\n"
                report += f"  是否代理: {info.get('proxy', 'N/A')}\n"
            else:
                bytecode_length = len(info.get('bytecode', '')) if info.get('bytecode') else 0
                report += f"  字节码长度: {bytecode_length} 字符\n"
            
            if info.get('error'):
                report += f"  错误: {info['error']}\n"
        
        report += f"\n=== 详细调用链 ===\n"
        
        for i, call in enumerate(data.get('call_tree', [])):
            indent = "  " * len(call.get('trace_address', []))
            report += f"{indent}{i}. {call['call_type']}: {call['from'][:10]}... -> {call['to'][:10]}...\n"
            report += f"{indent}   函数: {call['function_signature']}\n"
            report += f"{indent}   Gas: {call['gas_used']:,}, 价值: {call['value_eth']:.6f} ETH\n"
            
            # 添加合约信息
            if call['to'] in contract_info:
                contract = contract_info[call['to']]
                report += f"{indent}   合约: {contract.get('contract_name', 'Unknown')}\n"
        
        return report
    
    def save_report(self, report: str, filename: str = None) -> str:
        """保存报告到文件"""
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"tx_report_{timestamp}.txt"
        
        filepath = os.path.join(self.log_dir, filename)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(report)
        
        return filepath


# 使用示例
if __name__ == "__main__":
    # 初始化分析器
    url = "https://intensive-dry-borough.quiknode.pro/da011c0dec7ae5443cd470af983f25af9e100678/"
    analyzer = TransactionTraceAnalyzer(url)
    
    # 示例交易哈希
    tx_hash = "0x16a3806192c8983581f1fb1abda0e0ee2bca51e3b8320bd65841c5a9979f6a26"
    
    # 获取并解析交易追踪数据
    print("正在获取交易追踪数据...")
    trace_data = analyzer.get_transaction_trace(tx_hash)
    
    print("正在解析数据...")
    parsed_data = analyzer.parse_trace_data(trace_data)
    
    if "error" in parsed_data:
        print(f"错误: {parsed_data['error']}")
    else:
        # 保存数据
        json_file = analyzer.save_to_json(parsed_data)
        csv_file = analyzer.save_to_csv(parsed_data)
        contract_file = analyzer.save_contract_info_to_json(parsed_data)
        
        print(f"数据已保存到: {json_file}")
        print(f"调用数据已保存到: {csv_file}")
        print(f"合约信息已保存到: {contract_file}")
        
        # 生成并显示摘要报告
        report = analyzer.generate_summary_report(parsed_data)
        print(report)
        
        # 保存报告
        report_file = analyzer.save_report(report, f"tx_report_{tx_hash[:10]}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt")
        print(f"报告已保存到: {report_file}")
        
        print("\n分析完成！")
