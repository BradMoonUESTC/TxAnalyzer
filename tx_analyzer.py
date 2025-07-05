import requests
import json
import os
import tempfile
from datetime import datetime
from typing import Dict, List, Any, Optional, Tuple
import pandas as pd
import re
from web3 import Web3
from heimdall_api import decompile

class TransactionTraceAnalyzer:
    def __init__(self, network: str = None, config_file: str = "config.json"):
        """
        初始化交易追踪分析器
        
        Args:
            network: 网络名称 ('ethereum' 或 'base')，如果为None则使用配置文件中的默认网络
            config_file: 配置文件路径
        """
        self.config = self._load_config(config_file)
        
        # 确定使用的网络
        if network is None:
            network = self.config.get('default_network', 'ethereum')
        
        if network not in self.config['networks']:
            raise ValueError(f"不支持的网络: {network}。支持的网络: {list(self.config['networks'].keys())}")
        
        self.network = network
        self.network_config = self.config['networks'][network]
        
        self.rpc_url = self.network_config['rpc_url']
        self.etherscan_api_key = self.network_config['etherscan_api_key']
        self.etherscan_base_url = self.network_config['etherscan_base_url']
        self.chain_id = self.network_config['chain_id']
        
        self.headers = {'Content-Type': 'application/json'}
        self.log_dir = "log"
        self._ensure_log_directory()
        
        # 初始化函数签名缓存
        self.function_signature_cache = {}
        self.cache_file = os.path.join(self.log_dir, "function_signature_cache.json")
        self._load_function_signature_cache()
        
        # 初始化反编译相关配置
        self.decompile_enabled = True  # 默认启用反编译功能
        
        print(f"已初始化 {self.network_config['name']} 网络分析器")
        if self.function_signature_cache:
            print(f"加载了 {len(self.function_signature_cache)} 个函数签名缓存")
        print(f"反编译功能: {'启用' if self.decompile_enabled else '禁用'}")
    
    def _load_config(self, config_file: str) -> Dict[str, Any]:
        """加载配置文件"""
        try:
            with open(config_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        except FileNotFoundError:
            raise FileNotFoundError(f"配置文件 {config_file} 不存在")
        except json.JSONDecodeError:
            raise ValueError(f"配置文件 {config_file} 格式错误")
    
    def _load_function_signature_cache(self):
        """加载函数签名缓存"""
        try:
            if os.path.exists(self.cache_file):
                with open(self.cache_file, 'r', encoding='utf-8') as f:
                    self.function_signature_cache = json.load(f)
        except Exception as e:
            print(f"加载函数签名缓存失败: {e}")
            self.function_signature_cache = {}
    
    def _save_function_signature_cache(self):
        """保存函数签名缓存"""
        try:
            # 确保有必要的属性和函数可用
            if not hasattr(self, 'cache_file') or not hasattr(self, 'function_signature_cache'):
                return
            
            import builtins
            if not hasattr(builtins, 'open'):
                return
                
            with open(self.cache_file, 'w', encoding='utf-8') as f:
                json.dump(self.function_signature_cache, f, indent=2, ensure_ascii=False)
        except Exception as e:
            try:
                print(f"保存函数签名缓存失败: {e}")
            except:
                pass  # 如果连print都失败了，就静默处理
    
    def __del__(self):
        """析构函数，保存缓存"""
        try:
            # 只有在对象完全初始化后才尝试保存缓存
            if hasattr(self, '_save_function_signature_cache'):
                self._save_function_signature_cache()
        except:
            pass  # 析构函数中不应该抛出异常
    
    def get_cache_info(self) -> Dict[str, Any]:
        """获取缓存信息"""
        return {
            "cache_size": len(self.function_signature_cache),
            "cache_file": self.cache_file,
            "cache_exists": os.path.exists(self.cache_file),
            "sample_entries": dict(list(self.function_signature_cache.items())[:5])
        }
    
    def clear_cache(self):
        """清空缓存"""
        self.function_signature_cache.clear()
        if os.path.exists(self.cache_file):
            os.remove(self.cache_file)
        print("函数签名缓存已清空")
    
    def save_cache(self):
        """手动保存缓存"""
        self._save_function_signature_cache()
        print(f"函数签名缓存已保存，共 {len(self.function_signature_cache)} 个条目")
    
    def enable_decompile(self, enabled: bool = True):
        """启用或禁用反编译功能"""
        self.decompile_enabled = enabled
        print(f"反编译功能已{'启用' if enabled else '禁用'}")
    
    def disable_decompile(self):
        """禁用反编译功能"""
        self.enable_decompile(False)
    
    def _parse_function_signature(self, function_signature: str) -> Dict[str, Any]:
        """解析函数签名，提取函数名和参数类型"""
        try:
            # 使用正则表达式解析函数签名
            # 例如: "transfer(address,uint256)" -> {"name": "transfer", "inputs": ["address", "uint256"]}
            pattern = r'(\w+)\((.*)\)'
            match = re.match(pattern, function_signature)
            
            if not match:
                return {"name": function_signature, "inputs": []}
            
            function_name = match.group(1)
            params_str = match.group(2)
            
            # 解析参数类型
            if params_str.strip():
                # 简单的参数分割，处理常见情况
                params = [param.strip() for param in params_str.split(',') if param.strip()]
            else:
                params = []
            
            return {
                "name": function_name,
                "inputs": params
            }
        except Exception as e:
            print(f"解析函数签名失败 {function_signature}: {e}")
            return {"name": function_signature, "inputs": []}
    
    def _decode_function_input(self, input_data: str, function_signature: str) -> str:
        """解码函数输入参数，返回简化的字符串格式"""
        try:
            if not input_data or input_data == '0x' or len(input_data) < 10:
                return ""
            
            # 解析函数签名
            sig_info = self._parse_function_signature(function_signature)
            function_name = sig_info["name"]
            param_types = sig_info["inputs"]
            
            # 如果没有参数类型信息，返回函数名
            if not param_types:
                return f"{function_name}()"
            
            # 移除方法ID (前4字节)
            params_data = input_data[10:]  # 移除 "0x" 和 8位方法ID
            
            # 使用Web3解码参数
            try:
                # 构造ABI条目
                abi_entry = {
                    "name": function_name,
                    "type": "function",
                    "inputs": []
                }
                
                for i, param_type in enumerate(param_types):
                    abi_entry["inputs"].append({
                        "name": f"param_{i}",
                        "type": param_type
                    })
                
                # 解码参数
                decoded_params = Web3().codec.decode(
                    [input_spec["type"] for input_spec in abi_entry["inputs"]], 
                    bytes.fromhex(params_data)
                )
                
                # 格式化为简化字符串
                param_strings = []
                for param_type, value in zip(param_types, decoded_params):
                    formatted_value = self._format_param_value(value, param_type)
                    param_strings.append(f"{param_type}={formatted_value}")
                
                return f"{function_name}({','.join(param_strings)})"
                
            except Exception as decode_error:
                print(f"解码参数失败: {decode_error}")
                return f"{function_name}(?)"
        
        except Exception as e:
            print(f"解码函数输入失败: {e}")
            return ""
    
    def _format_param_value(self, value: Any, param_type: str) -> str:
        """格式化参数值"""
        try:
            if param_type.startswith('uint') or param_type.startswith('int'):
                return str(value)
            elif param_type == 'address':
                if isinstance(value, bytes):
                    return f"0x{value.hex()}"
                elif isinstance(value, str):
                    return value.lower()
                else:
                    return str(value)
            elif param_type == 'bool':
                return str(value).lower()
            elif param_type.startswith('bytes'):
                if isinstance(value, bytes):
                    return f"0x{value.hex()}"
                else:
                    return str(value)
            elif param_type == 'string':
                return str(value)
            else:
                return str(value)
        except Exception as e:
            return str(value)
    
    def _ensure_log_directory(self):
        """确保log目录存在"""
        if not os.path.exists(self.log_dir):
            os.makedirs(self.log_dir)
    
    def switch_network(self, network: str):
        """切换网络"""
        if network not in self.config['networks']:
            raise ValueError(f"不支持的网络: {network}。支持的网络: {list(self.config['networks'].keys())}")
        
        self.network = network
        self.network_config = self.config['networks'][network]
        
        self.rpc_url = self.network_config['rpc_url']
        self.etherscan_api_key = self.network_config['etherscan_api_key']
        self.etherscan_base_url = self.network_config['etherscan_base_url']
        self.chain_id = self.network_config['chain_id']
        
        print(f"已切换到 {self.network_config['name']} 网络")
    
    def get_contract_info_from_etherscan(self, address: str) -> Dict[str, Any]:
        """从Etherscan获取合约信息"""
        try:
            # 获取源代码
            # 根据不同网络使用不同的API参数
            if self.network == 'ethereum':
                source_url = f"{self.etherscan_base_url}?chainid={self.chain_id}&module=contract&action=getsourcecode&address={address}&apikey={self.etherscan_api_key}"
            else:
                # 对于Base网络，不需要chainid参数
                source_url = f"{self.etherscan_base_url}?module=contract&action=getsourcecode&address={address}&apikey={self.etherscan_api_key}"
            
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
                        # 如果没有源代码，获取字节码并尝试反编译
                        bytecode = self._get_contract_bytecode(address)
                        
                        # 创建基本的合约信息
                        contract_data = {
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
                        
                        # 如果有字节码且反编译功能启用，尝试反编译
                        if bytecode and self.decompile_enabled:
                            print(f"检测到合约 {address} 没有公开源代码，开始反编译...")
                            decompile_result = self._decompile_contract(address, bytecode)
                            
                            if decompile_result['success']:
                                # 添加反编译信息
                                contract_data['decompiled'] = True
                                contract_data['raw_sol_code'] = decompile_result['raw_sol_code']
                                contract_data['optimized_sol_code'] = decompile_result['optimized_sol_code']
                                contract_data['decompiled_abi'] = decompile_result['abi_code']
                                contract_data['decompiled_at'] = decompile_result['decompiled_at']
                                
                                # 如果反编译成功，将优化后的代码作为源代码
                                contract_data['source_code'] = decompile_result['optimized_sol_code']
                                print(f"合约 {address} 反编译成功！")
                            else:
                                contract_data['decompiled'] = False
                                contract_data['decompile_error'] = decompile_result['error']
                                print(f"合约 {address} 反编译失败: {decompile_result['error']}")
                        else:
                            contract_data['decompiled'] = False
                            if not bytecode:
                                contract_data['decompile_error'] = '无法获取字节码'
                            elif not self.decompile_enabled:
                                contract_data['decompile_error'] = '反编译功能已禁用'
                        
                        return contract_data
            
            # 获取字节码并尝试反编译
            bytecode = self._get_contract_bytecode(address)
            
            contract_data = {
                'address': address,
                'has_source_code': False,
                'source_code': None,
                'abi': None,
                'contract_name': 'Unknown',
                'error': 'Failed to fetch contract info',
                'bytecode': bytecode
            }
            
            # 如果有字节码且反编译功能启用，尝试反编译
            if bytecode and self.decompile_enabled:
                print(f"API获取失败，但检测到合约 {address} 有字节码，开始反编译...")
                decompile_result = self._decompile_contract(address, bytecode)
                
                if decompile_result['success']:
                    # 添加反编译信息
                    contract_data['decompiled'] = True
                    contract_data['raw_sol_code'] = decompile_result['raw_sol_code']
                    contract_data['optimized_sol_code'] = decompile_result['optimized_sol_code']
                    contract_data['decompiled_abi'] = decompile_result['abi_code']
                    contract_data['decompiled_at'] = decompile_result['decompiled_at']
                    
                    # 如果反编译成功，将优化后的代码作为源代码
                    contract_data['source_code'] = decompile_result['optimized_sol_code']
                    print(f"合约 {address} 反编译成功！")
                else:
                    contract_data['decompiled'] = False
                    contract_data['decompile_error'] = decompile_result['error']
                    print(f"合约 {address} 反编译失败: {decompile_result['error']}")
            else:
                contract_data['decompiled'] = False
                if not bytecode:
                    contract_data['decompile_error'] = '无法获取字节码'
                elif not self.decompile_enabled:
                    contract_data['decompile_error'] = '反编译功能已禁用'
            
            return contract_data
            
        except Exception as e:
            print(f"获取合约信息失败 {address}: {e}")
            
            # 获取字节码并尝试反编译
            bytecode = self._get_contract_bytecode(address)
            
            contract_data = {
                'address': address,
                'has_source_code': False,
                'source_code': None,
                'abi': None,
                'contract_name': 'Unknown',
                'error': str(e),
                'bytecode': bytecode
            }
            
            # 如果有字节码且反编译功能启用，尝试反编译
            if bytecode and self.decompile_enabled:
                print(f"API异常，但检测到合约 {address} 有字节码，开始反编译...")
                decompile_result = self._decompile_contract(address, bytecode)
                
                if decompile_result['success']:
                    # 添加反编译信息
                    contract_data['decompiled'] = True
                    contract_data['raw_sol_code'] = decompile_result['raw_sol_code']
                    contract_data['optimized_sol_code'] = decompile_result['optimized_sol_code']
                    contract_data['decompiled_abi'] = decompile_result['abi_code']
                    contract_data['decompiled_at'] = decompile_result['decompiled_at']
                    
                    # 如果反编译成功，将优化后的代码作为源代码
                    contract_data['source_code'] = decompile_result['optimized_sol_code']
                    print(f"合约 {address} 反编译成功！")
                else:
                    contract_data['decompiled'] = False
                    contract_data['decompile_error'] = decompile_result['error']
                    print(f"合约 {address} 反编译失败: {decompile_result['error']}")
            else:
                contract_data['decompiled'] = False
                if not bytecode:
                    contract_data['decompile_error'] = '无法获取字节码'
                elif not self.decompile_enabled:
                    contract_data['decompile_error'] = '反编译功能已禁用'
            
            return contract_data
    
    def _get_contract_bytecode(self, address: str) -> Optional[str]:
        """获取合约字节码"""
        try:
            # 直接使用RPC调用eth_getCode
            payload = json.dumps({
                "method": "eth_getCode",
                "params": [address, "latest"],
                "id": 1,
                "jsonrpc": "2.0"
            })
            
            response = requests.post(self.rpc_url, headers=self.headers, data=payload, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('result') and data['result'] != '0x':
                    return data['result']
            
            return None
            
        except Exception as e:
            print(f"获取字节码失败 {address}: {e}")
            return None
    
    def get_function_signature_from_api(self, method_id: str) -> str:
        """通过openchain.xyz API查询函数签名（带缓存）"""
        try:
            # 确保method_id格式正确
            if not method_id.startswith('0x'):
                method_id = '0x' + method_id
            
            # 检查缓存
            if method_id in self.function_signature_cache:
                print(f"使用缓存的函数签名: {method_id} -> {self.function_signature_cache[method_id]}")
                return self.function_signature_cache[method_id]
            
            print(f"正在查询函数签名: {method_id}")
            url = f"https://api.openchain.xyz/signature-database/v1/lookup?filter=false&function={method_id}"
            
            response = requests.get(url, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('ok') and data.get('result', {}).get('function', {}).get(method_id):
                    functions = data['result']['function'][method_id]
                    if functions:
                        # 返回第一个匹配的函数签名
                        function_signature = functions[0]['name']
                        # 保存到缓存
                        self.function_signature_cache[method_id] = function_signature
                        print(f"API查询成功，已缓存: {method_id} -> {function_signature}")
                        return function_signature
            
            # 如果查询失败，也缓存原始method_id，避免重复请求
            self.function_signature_cache[method_id] = method_id
            print(f"API查询失败，已缓存原始值: {method_id}")
            return method_id
            
        except Exception as e:
            print(f"查询函数签名失败 {method_id}: {e}")
            # 异常情况下也缓存原始method_id
            self.function_signature_cache[method_id] = method_id
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
                "position": main_trace.get('transactionPosition')
            },
            "call_tree": [],
            "addresses_involved": set(),
            "value_transfers": [],
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
        total_traces = len(traces)
        print(f"正在解析 {total_traces} 个追踪记录...")
        
        from tqdm import tqdm
        for i, trace in tqdm(enumerate(traces), total=len(traces), desc="解析追踪记录"):
            # 显示进度
            if total_traces > 10:  # 只在调用数量较多时显示进度
                if i % max(1, total_traces // 10) == 0 or i == total_traces - 1:
                    progress = (i + 1) / total_traces * 100
                    print(f"解析进度: {i + 1}/{total_traces} ({progress:.1f}%)")
            
            print(f"正在解析第 {i+1} 个调用...")
            call_info = self._parse_single_trace(trace, i)
            print(f"调用类型: {call_info['call_type']}")
            print(f"从地址: {call_info['from']}")
            print(f"到地址: {call_info['to']}")
            
            parsed_data["call_tree"].append(call_info)
            
            # 收集地址
            parsed_data["addresses_involved"].add(call_info["from"])
            parsed_data["addresses_involved"].add(call_info["to"])
            print(f"已收集地址: {call_info['from']}, {call_info['to']}")
            
            # 收集合约地址（from和to地址都可能是合约地址）
            if call_info["from"]:
                contract_addresses.add(call_info["from"])
            if call_info["to"]:
                contract_addresses.add(call_info["to"])
            
            # 收集价值转移
            if call_info["value"] > 0:
                print(f"检测到价值转移: {call_info['value'] / 10**18} ETH")
                parsed_data["value_transfers"].append({
                    "from": call_info["from"],
                    "to": call_info["to"],
                    "value": call_info["value"],
                    "value_eth": call_info["value"] / 10**18,
                    "trace_index": i
                })
                parsed_data["summary"]["total_value_transferred"] += call_info["value"]
            
            # 统计调用类型
            call_type = call_info["call_type"]
            parsed_data["summary"]["call_types"][call_type] = parsed_data["summary"]["call_types"].get(call_type, 0) + 1
            
            # 收集函数调用
            if call_info.get("decoded_input"):
                print(f"函数调用: {call_info['decoded_input']}")
                parsed_data["function_calls"].append({
                    "trace_index": i,
                    "function": call_info["decoded_input"],
                    "from": call_info["from"],
                    "to": call_info["to"]
                })
        
        # 获取合约信息
        valid_addresses = [addr for addr in contract_addresses if addr]
        total_contracts = len(valid_addresses)
        print(f"正在获取 {total_contracts} 个合约的信息...")
        
        for i, address in enumerate(valid_addresses):
            progress = (i + 1) / total_contracts * 100
            print(f"获取合约信息 ({i + 1}/{total_contracts}, {progress:.1f}%): {address}")
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
        
        # 解析函数参数
        decoded_input = ""
        if function_signature and function_signature != input_data[:10]:
            # 只有当函数签名不是原始方法ID时才解析
            decoded_input = self._decode_function_input(input_data, function_signature)
        
        call_info = {
            "trace_index": index,
            "trace_address": trace.get('traceAddress', []),
            "call_type": action.get('callType', ''),
            "from": action.get('from', ''),
            "to": action.get('to', ''),
            "value": int(action.get('value', '0x0'), 16),
            "value_eth": int(action.get('value', '0x0'), 16) / 10**18,
            "output": result.get('output', ''),
            "subtraces": trace.get('subtraces', 0)
        }
        
        # 如果成功解析了参数，添加到结果中
        if decoded_input:
            call_info["decoded_input"] = decoded_input
        
        return call_info
    
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
        # 确保log目录存在
        self._ensure_log_directory()
        
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
        # 确保log目录存在
        self._ensure_log_directory()
        
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
                'decoded_input': call.get('decoded_input', '')
            })
        
        df = pd.DataFrame(calls_data)
        df.to_csv(filepath, index=False)
        
        return filepath
    
    def save_contract_info_to_json(self, data: Dict[str, Any], filename: str = None) -> str:
        """保存合约信息到单独的JSON文件"""
        # 确保log目录存在
        self._ensure_log_directory()
        
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            tx_hash = data.get('transaction_info', {}).get('hash', 'unknown')[:10]
            filename = f"tx_contracts_{tx_hash}_{timestamp}.json"
        
        filepath = os.path.join(self.log_dir, filename)
        
        contract_info = data.get('contract_info', {})
        
        # 为反编译的合约创建单独的源代码文件
        for address, info in contract_info.items():
            if info.get('decompiled') and info.get('optimized_sol_code'):
                # 保存优化后的源代码
                sol_filename = f"decompiled_{address[2:12]}_{timestamp}.sol"
                sol_filepath = os.path.join(self.log_dir, sol_filename)
                
                with open(sol_filepath, 'w', encoding='utf-8') as f:
                    f.write(info['optimized_sol_code'])
                
                # 在合约信息中添加文件路径
                info['optimized_sol_file'] = sol_filepath
                print(f"反编译的源代码已保存到: {sol_filepath}")
                
                # 如果有原始反编译代码，也保存
                if info.get('raw_sol_code'):
                    raw_sol_filename = f"raw_decompiled_{address[2:12]}_{timestamp}.sol"
                    raw_sol_filepath = os.path.join(self.log_dir, raw_sol_filename)
                    
                    with open(raw_sol_filepath, 'w', encoding='utf-8') as f:
                        f.write(info['raw_sol_code'])
                    
                    info['raw_sol_file'] = raw_sol_filepath
                    print(f"原始反编译代码已保存到: {raw_sol_filepath}")
                
                # 如果有反编译的ABI，也保存
                if info.get('decompiled_abi'):
                    abi_filename = f"decompiled_abi_{address[2:12]}_{timestamp}.json"
                    abi_filepath = os.path.join(self.log_dir, abi_filename)
                    
                    with open(abi_filepath, 'w', encoding='utf-8') as f:
                        f.write(info['decompiled_abi'])
                    
                    info['decompiled_abi_file'] = abi_filepath
                    print(f"反编译的ABI已保存到: {abi_filepath}")
        
        # 保存合约信息JSON
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(contract_info, f, indent=2, ensure_ascii=False)
        
        return filepath
    
    def generate_summary_report(self, data: Dict[str, Any]) -> str:
        """生成交易摘要报告"""
        tx_info = data.get('transaction_info', {})
        summary = data.get('summary', {})
        contract_info = data.get('contract_info', {})
        
        report = f"""
=== 交易追踪分析报告 ===

网络信息:
- 网络: {self.network_config['name']}
- 链ID: {self.chain_id}

基本信息:
- 交易哈希: {tx_info.get('hash', 'N/A')}
- 区块号: {tx_info.get('block_number', 'N/A')}
- 交易位置: {tx_info.get('position', 'N/A')}

调用统计:
- 总调用数: {summary.get('total_calls', 0)}
- 调用类型分布: {summary.get('call_types', {})}
- 总转账金额: {summary.get('total_value_transferred_eth', 0):.6f} ETH

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
                
                # 添加反编译信息
                if info.get('decompiled') is not None:
                    report += f"  反编译状态: {'成功' if info.get('decompiled') else '失败'}\n"
                    
                    if info.get('decompiled'):
                        report += f"  反编译时间: {info.get('decompiled_at', 'N/A')}\n"
                        if info.get('optimized_sol_file'):
                            report += f"  优化代码文件: {info.get('optimized_sol_file')}\n"
                        if info.get('raw_sol_file'):
                            report += f"  原始代码文件: {info.get('raw_sol_file')}\n"
                        if info.get('decompiled_abi_file'):
                            report += f"  ABI文件: {info.get('decompiled_abi_file')}\n"
                    else:
                        if info.get('decompile_error'):
                            report += f"  反编译错误: {info.get('decompile_error')}\n"
            
            if info.get('error'):
                report += f"  错误: {info['error']}\n"
        
        report += f"\n=== 详细调用链 ===\n"
        
        for i, call in enumerate(data.get('call_tree', [])):
            indent = "  " * len(call.get('trace_address', []))
            report += f"{indent}{i}. {call['call_type']}: {call['from'][:10]}... -> {call['to'][:10]}...\n"
            
            # 如果有解析后的参数，显示参数信息
            if call.get('decoded_input'):
                report += f"{indent}   函数: {call['decoded_input']}\n"
            
            report += f"{indent}   价值: {call['value_eth']:.6f} ETH\n"
            
            # 添加合约信息
            if call['to'] in contract_info:
                contract = contract_info[call['to']]
                report += f"{indent}   合约: {contract.get('contract_name', 'Unknown')}\n"
        
        return report
    
    def save_report(self, report: str, filename: str = None) -> str:
        """保存报告到文件"""
        # 确保log目录存在
        self._ensure_log_directory()
        
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"tx_report_{timestamp}.txt"
        
        filepath = os.path.join(self.log_dir, filename)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(report)
        
        return filepath
    
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
    
    def heimdall_decompile(self, contract_address: str, bytecode: str) -> Tuple[Optional[str], Optional[str]]:
        """
        使用Heimdall反编译合约
        
        Args:
            contract_address: 合约地址
            bytecode: 合约bytecode
            
        Returns:
            (反编译的sol代码, ABI代码) 的元组，失败时返回 (None, None)
        """
        print(f"正在使用Heimdall反编译合约 {contract_address}...")
        
        try:
            # 创建临时文件保存bytecode
            with tempfile.NamedTemporaryFile(mode='w', suffix='.bin', delete=False) as temp_file:
                temp_file.write(bytecode)
                temp_file_path = temp_file.name
            
            # 生成合约名称
            contract_name = f"Contract_{contract_address[2:12]}"  # 使用地址的前10个字符
            
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
            print(f"Heimdall反编译失败 {contract_address}: {e}")
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
        print(f"正在使用大模型优化反编译代码: {contract_address}")
        
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
    
    def _decompile_contract(self, address: str, bytecode: str) -> Dict[str, Any]:
        """
        执行合约反编译流程
        
        Args:
            address: 合约地址
            bytecode: 合约字节码
            
        Returns:
            反编译结果字典
        """
        if not self.decompile_enabled:
            return {
                'success': False,
                'error': '反编译功能已禁用'
            }
        
        try:
            # 使用Heimdall反编译
            raw_sol_code, abi_code = self.heimdall_decompile(address, bytecode)
            
            if not raw_sol_code:
                return {
                    'success': False,
                    'error': 'Heimdall反编译失败'
                }
            
            # 使用大模型优化
            optimized_sol_code = self.optimize_with_ai(raw_sol_code, abi_code or "", address)
            
            return {
                'success': True,
                'raw_sol_code': raw_sol_code,
                'abi_code': abi_code,
                'optimized_sol_code': optimized_sol_code,
                'decompiled_at': datetime.now().isoformat()
            }
            
        except Exception as e:
            print(f"反编译过程中出错 {address}: {e}")
            return {
                'success': False,
                'error': f'反编译过程中出错: {str(e)}'
            }


# 使用示例
if __name__ == "__main__":
    # 初始化分析器 - 使用Base网络（默认）
    # analyzer = TransactionTraceAnalyzer()
    
    # 或者显式指定网络
    analyzer = TransactionTraceAnalyzer(network='bsc')    # 使用Base网络
    # analyzer = TransactionTraceAnalyzer(network='ethereum') # 使用以太坊网络
    
    # 也可以在运行时切换网络
    # analyzer.switch_network('ethereum')  # 切换到以太坊网络
    
    # 反编译功能控制（默认启用）
    # analyzer.enable_decompile(True)   # 启用反编译功能
    # analyzer.disable_decompile()      # 禁用反编译功能
    
    print("=== 交易追踪分析器 ===")
    print("功能说明:")
    print("- 自动获取交易追踪数据")
    print("- 解析合约信息")
    print("- 对于没有公开源代码的合约，自动进行反编译")
    print("- 使用Heimdall进行字节码反编译")
    print("- 使用大模型优化反编译后的代码")
    print("- 生成详细的分析报告")
    print()
    
    # 示例交易哈希 - 请替换为实际的交易哈希
    tx_hash = "0x2d9c1a00cf3d2fda268d0d11794ad2956774b156355e16441d6edb9a448e5a99"
    
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
        
        # 统计反编译结果
        decompiled_count = 0
        total_contracts = 0
        
        for address, info in parsed_data.get('contract_info', {}).items():
            total_contracts += 1
            if info.get('decompiled'):
                decompiled_count += 1
        
        print(f"\n=== 反编译统计 ===")
        print(f"总合约数量: {total_contracts}")
        print(f"成功反编译: {decompiled_count}")
        print(f"反编译率: {decompiled_count/total_contracts*100:.1f}%" if total_contracts > 0 else "N/A")
        
        # 生成并显示摘要报告
        report = analyzer.generate_summary_report(parsed_data)
        print(report)
        
        # 保存报告
        report_file = analyzer.save_report(report, f"tx_report_{tx_hash[:10]}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt")
        print(f"报告已保存到: {report_file}")
        
        # 保存函数签名缓存
        analyzer._save_function_signature_cache()
        print(f"函数签名缓存已保存，共 {len(analyzer.function_signature_cache)} 个条目")
        
        print("\n分析完成！")
        print("注意：反编译功能需要设置以下环境变量：")
        print("- OPENAI_API_KEY: OpenAI API密钥")
        print("- OPENAI_API_BASE: OpenAI API基础URL")
        print("- VUL_MODEL: 使用的模型（可选，默认为gpt-4o-mini）")
