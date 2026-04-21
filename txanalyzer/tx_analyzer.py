import requests
import json
import os
import tempfile
from datetime import datetime
from typing import Dict, List, Any, Optional, Tuple
import pandas as pd
import re
from pathlib import Path
from web3 import Web3
from .heimdall_api import decompile

class TransactionTraceAnalyzer:
    def __init__(self, network: str = None, config_file: str = "config.json", *, log_dir: str = "log", cache_dir: str = "log"):
        """
        Initialize the transaction trace analyzer.
        
        Args:
            network: Network name (currently recommended: 'bsc' only). Uses default from config if None.
            config_file: Path to configuration file.
            log_dir: Output directory for this run's artifacts (trace/calls/contracts/report/sources, etc.).
            cache_dir: Shared cache directory (function signature cache, etc.); decoupled from log_dir to avoid per-tx duplication.
        """
        self.config = self._load_config(config_file)
        
        if network is None:
            network = self.config.get('default_network', 'bsc')
        
        if network not in self.config['networks']:
            raise ValueError(f"Unsupported network: {network}. Supported networks: {list(self.config['networks'].keys())}")
        
        self.network = network
        self.network_config = self.config['networks'][network]
        
        self.rpc_url = self.network_config['rpc_url']
        self.etherscan_api_key = self.network_config['etherscan_api_key']
        self.etherscan_base_url = self.network_config['etherscan_base_url']
        self.chain_id = self.network_config['chain_id']
        
        self.headers = {'Content-Type': 'application/json'}
        self.log_dir = str(log_dir) if log_dir else "log"
        self.cache_dir = str(cache_dir) if cache_dir else self.log_dir
        self._ensure_log_directory()

        # Heimdall output directory:
        # - Legacy: always writes to output/local/
        # - New: if log_dir looks like log/<tx_hash>/, move Heimdall artifacts to output/local/<tx_hash>/
        self.output_local_dir = self._infer_output_local_dir()
        
        # Initialize function signature cache
        self.function_signature_cache = {}
        self.cache_file = os.path.join(self.cache_dir, "function_signature_cache.json")
        self._load_function_signature_cache()
        
        # Initialize decompilation config
        self.decompile_enabled = True
        
        print(f"Initialized analyzer for {self.network_config['name']} network")
        if self.function_signature_cache:
            print(f"Loaded {len(self.function_signature_cache)} function signature cache entries")
        print(f"Decompilation: {'enabled' if self.decompile_enabled else 'disabled'}")

    def _infer_output_local_dir(self) -> Path:
        """
        Infer the output directory for Heimdall decompilation artifacts.

        Rules:
        - Default: output/local/
        - If log_dir ends with a tx_hash (0x + 64 hex chars), use output/local/<tx_hash>/
        """
        base = (Path("output") / "local").resolve()
        try:
            tail = Path(self.log_dir).resolve().name
            if isinstance(tail, str) and tail.startswith("0x") and len(tail) == 66:
                return (base / tail).resolve()
        except Exception:
            pass
        return base

    def _unwrap_alchemy_nested_result(self, resp: Any) -> Any:
        """
        Handle Alchemy Trace API responses where result contains a nested JSON-RPC response.

        Example (from Alchemy docs):
        {
          "jsonrpc": "2.0",
          "id": "1",
          "result": { "jsonrpc": "2.0", "id": 0, "result": [ ... ] }
        }
        Extracts the inner response to produce a standard JSON-RPC response structure.
        """
        try:
            if not isinstance(resp, dict):
                return resp
            inner = resp.get("result")
            if isinstance(inner, dict) and inner.get("jsonrpc") == "2.0" and "result" in inner:
                return inner
            return resp
        except Exception:
            return resp

    def _rpc_call(
        self,
        method: str,
        params: List[Any],
        *,
        timeout: int = 10,
        allow_params_only_fallback: bool = False,
        unwrap_alchemy_nested_result: bool = False
    ) -> Dict[str, Any]:
        """
        Unified RPC call entry point.

        - Sends standard JSON-RPC format by default: {"jsonrpc":"2.0","id":1,"method":..., "params":[...]}
        - Some Alchemy Trace/Debug API docs show a params-only call style; if fallback is enabled and
          the standard JSON-RPC returns Invalid Request, automatically retries with params-only.
        - Provides auto-unwrapping for Alchemy Trace API nested JSON-RPC response structures.
        """
        # 1) Standard JSON-RPC
        body_jsonrpc = {"jsonrpc": "2.0", "id": 1, "method": method, "params": params}
        response = requests.post(self.rpc_url, headers=self.headers, json=body_jsonrpc, timeout=timeout)
        resp_json = response.json()

        if unwrap_alchemy_nested_result:
            resp_json = self._unwrap_alchemy_nested_result(resp_json)

        # 2) Optional fallback: params-only array
        if allow_params_only_fallback and isinstance(resp_json, dict) and "error" in resp_json:
            err = resp_json.get("error") or {}
            message = (err.get("message") or "") if isinstance(err, dict) else str(err)
            code = err.get("code") if isinstance(err, dict) else None
            # -32600: Invalid Request (common when JSON-RPC format is rejected)
            if code == -32600 or "invalid request" in message.lower():
                response2 = requests.post(self.rpc_url, headers=self.headers, json=params, timeout=timeout)
                resp_json = response2.json()
                if unwrap_alchemy_nested_result:
                    resp_json = self._unwrap_alchemy_nested_result(resp_json)

        return resp_json
    
    def _load_config(self, config_file: str) -> Dict[str, Any]:
        """Load configuration file"""
        try:
            with open(config_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        except FileNotFoundError:
            raise FileNotFoundError(f"Config file {config_file} not found")
        except json.JSONDecodeError:
            raise ValueError(f"Config file {config_file} has invalid format")
    
    def _load_function_signature_cache(self):
        """Load function signature cache"""
        try:
            if os.path.exists(self.cache_file):
                with open(self.cache_file, 'r', encoding='utf-8') as f:
                    self.function_signature_cache = json.load(f)
        except Exception as e:
            print(f"Failed to load function signature cache: {e}")
            self.function_signature_cache = {}
    
    def _save_function_signature_cache(self):
        """Save function signature cache"""
        try:
            # Ensure required attributes are available
            if not hasattr(self, 'cache_file') or not hasattr(self, 'function_signature_cache'):
                return

            with open(self.cache_file, 'w', encoding='utf-8') as f:
                json.dump(self.function_signature_cache, f, indent=2, ensure_ascii=False)
        except Exception as e:
            # During interpreter shutdown, various import/IO exceptions are common; silently ignore to avoid polluting output
            pass
    
    def __del__(self):
        """Destructor: persist cache"""
        try:
            if hasattr(self, '_save_function_signature_cache'):
                self._save_function_signature_cache()
        except:
            pass  # Destructors must not raise exceptions
    
    def get_cache_info(self) -> Dict[str, Any]:
        """Get cache information"""
        return {
            "cache_size": len(self.function_signature_cache),
            "cache_file": self.cache_file,
            "cache_exists": os.path.exists(self.cache_file),
            "sample_entries": dict(list(self.function_signature_cache.items())[:5])
        }
    
    def clear_cache(self):
        """Clear cache"""
        self.function_signature_cache.clear()
        if os.path.exists(self.cache_file):
            os.remove(self.cache_file)
        print("Function signature cache cleared")
    
    def save_cache(self):
        """Manually save cache"""
        self._save_function_signature_cache()
        print(f"Function signature cache saved, {len(self.function_signature_cache)} entries")
    
    def enable_decompile(self, enabled: bool = True):
        """Enable or disable decompilation"""
        self.decompile_enabled = enabled
        print(f"Decompilation {'enabled' if enabled else 'disabled'}")
    
    def disable_decompile(self):
        """Disable decompilation"""
        self.enable_decompile(False)
    
    def _parse_function_signature(self, function_signature: str) -> Dict[str, Any]:
        """Parse function signature to extract function name and parameter types"""
        try:
            def _split_top_level_commas(s: str) -> List[str]:
                """
                Split parameter list by top-level commas, handling nested tuples/arrays.

                Examples:
                - "uint256,address" -> ["uint256", "address"]
                - "(uint8,address,uint256),uint256" -> ["(uint8,address,uint256)", "uint256"]
                - "((uint256,address),bytes)[],uint256" -> ["((uint256,address),bytes)[]", "uint256"]
                """
                out: List[str] = []
                buf: List[str] = []
                paren = 0
                bracket = 0
                for ch in s:
                    if ch == "(":
                        paren += 1
                    elif ch == ")":
                        paren = max(0, paren - 1)
                    elif ch == "[":
                        bracket += 1
                    elif ch == "]":
                        bracket = max(0, bracket - 1)

                    if ch == "," and paren == 0 and bracket == 0:
                        part = "".join(buf).strip()
                        if part:
                            out.append(part)
                        buf = []
                        continue
                    buf.append(ch)

                tail = "".join(buf).strip()
                if tail:
                    out.append(tail)
                return out

            # Parse function signature with regex
            # e.g.: "transfer(address,uint256)" -> {"name": "transfer", "inputs": ["address", "uint256"]}
            pattern = r'(\w+)\((.*)\)'
            match = re.match(pattern, function_signature)
            
            if not match:
                return {"name": function_signature, "inputs": []}
            
            function_name = match.group(1)
            params_str = match.group(2)
            
            # Parse parameter types
            if params_str.strip():
                # Cannot simply split by comma: tuple parameters contain internal commas
                params = _split_top_level_commas(params_str)
            else:
                params = []
            
            return {
                "name": function_name,
                "inputs": params
            }
        except Exception as e:
            print(f"Failed to parse function signature {function_signature}: {e}")
            return {"name": function_signature, "inputs": []}
    
    def _decode_function_input(self, input_data: str, function_signature: str) -> str:
        """Decode function input parameters, return simplified string format"""
        try:
            if not input_data or input_data == '0x' or len(input_data) < 10:
                return ""
            
            # Parse function signature
            sig_info = self._parse_function_signature(function_signature)
            function_name = sig_info["name"]
            param_types = sig_info["inputs"]
            
            # No parameter type info available, return function name
            if not param_types:
                return f"{function_name}()"
            
            # Remove method ID (first 4 bytes)
            params_data = input_data[10:]  # Remove "0x" prefix and 8-char method ID
            
            # Decode parameters using Web3
            try:
                # Construct ABI entry
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
                
                # Decode parameters
                decoded_params = Web3().codec.decode(
                    [input_spec["type"] for input_spec in abi_entry["inputs"]], 
                    bytes.fromhex(params_data)
                )
                
                # Format as simplified string
                param_strings = []
                for param_type, value in zip(param_types, decoded_params):
                    formatted_value = self._format_param_value(value, param_type)
                    param_strings.append(f"{param_type}={formatted_value}")
                
                return f"{function_name}({','.join(param_strings)})"
                
            except Exception as decode_error:
                print(f"Failed to decode parameters: {decode_error}")
                return f"{function_name}(?)"
        
        except Exception as e:
            print(f"Failed to decode function input: {e}")
            return ""
    
    def _format_param_value(self, value: Any, param_type: str) -> str:
        """Format parameter value"""
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
        """Ensure log directory exists"""
        if self.log_dir and not os.path.exists(self.log_dir):
            os.makedirs(self.log_dir, exist_ok=True)
        if self.cache_dir and not os.path.exists(self.cache_dir):
            os.makedirs(self.cache_dir, exist_ok=True)
    
    def switch_network(self, network: str):
        """Switch network"""
        if network not in self.config['networks']:
            raise ValueError(f"Unsupported network: {network}. Supported networks: {list(self.config['networks'].keys())}")
        
        self.network = network
        self.network_config = self.config['networks'][network]
        
        self.rpc_url = self.network_config['rpc_url']
        self.etherscan_api_key = self.network_config['etherscan_api_key']
        self.etherscan_base_url = self.network_config['etherscan_base_url']
        self.chain_id = self.network_config['chain_id']
        
        print(f"Switched to {self.network_config['name']} network")
    
    def get_contract_info_from_etherscan(self, address: str) -> Dict[str, Any]:
        """Fetch contract info from Etherscan"""
        try:
            # Fetch source code (compatible with Etherscan v2 unified API & legacy per-chain endpoints)
            #
            # - Etherscan v2 unified endpoint: https://api.etherscan.io/v2/api?chainid=56&module=contract&action=getsourcecode...
            # - BscScan legacy endpoint: https://api.bscscan.com/api?module=contract&action=getsourcecode...
            base = self.etherscan_base_url
            query_common = f"module=contract&action=getsourcecode&address={address}&apikey={self.etherscan_api_key}"
            if "/v2/api" in base:
                source_url = f"{base}?chainid={self.chain_id}&{query_common}"
            else:
                source_url = f"{base}?{query_common}"
            
            response = requests.get(source_url, timeout=15)
            
            if response.status_code == 200:
                data = response.json()
                status = str(data.get('status', ''))
                result = data.get('result')

                # Normal success: status=1, result is a list with objects
                if status == '1' and result:
                    contract_info = data['result'][0]
                    
                    # Has source code, return directly
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
                        # Verified but no source code (rare), treat as unverified
                        bytecode = self._get_contract_bytecode(address)
                        
                        # Build basic contract info
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
                            'bytecode': bytecode,
                            'explorer_message': data.get('message'),
                            'explorer_result': data.get('result')
                        }
                        
                        # If bytecode exists and decompilation is enabled, try to decompile
                        if bytecode and self.decompile_enabled:
                            print(f"Contract {address} has no public source code, starting decompilation...")
                            decompile_result = self._decompile_contract(address, bytecode)
                            
                            if decompile_result['success']:
                                # Add decompilation info
                                contract_data['decompiled'] = True
                                contract_data['raw_sol_code'] = decompile_result['raw_sol_code']
                                contract_data['optimized_sol_code'] = decompile_result['optimized_sol_code']
                                contract_data['decompiled_abi'] = decompile_result['abi_code']
                                contract_data['decompiled_at'] = decompile_result['decompiled_at']
                                
                                # Use optimized code as source if decompilation succeeded
                                contract_data['source_code'] = decompile_result['optimized_sol_code']
                                print(f"Contract {address} decompilation succeeded!")
                            else:
                                contract_data['decompiled'] = False
                                contract_data['decompile_error'] = decompile_result['error']
                                print(f"Contract {address} decompilation failed: {decompile_result['error']}")
                        else:
                            contract_data['decompiled'] = False
                            if not bytecode:
                                contract_data['decompile_error'] = 'Failed to fetch bytecode'
                            elif not self.decompile_enabled:
                                contract_data['decompile_error'] = 'Decompilation disabled'
                        
                        return contract_data

                # Common case: contract not verified / no source code
                # Typical response:
                # status: "0", message: "NOTOK", result: "Contract source code not verified"
                if status == '0':
                    bytecode = self._get_contract_bytecode(address)

                    contract_data = {
                        'address': address,
                        'has_source_code': False,
                        'source_code': None,
                        'abi': None,
                        'contract_name': 'Unknown',
                        'bytecode': bytecode,
                        'verified': False,
                        'explorer_message': data.get('message'),
                        'explorer_result': data.get('result')
                    }

                    # If bytecode exists and decompilation is enabled, try to decompile
                    if bytecode and self.decompile_enabled:
                        print(f"Contract {address} has no public source code, starting decompilation...")
                        decompile_result = self._decompile_contract(address, bytecode)

                        if decompile_result['success']:
                            contract_data['decompiled'] = True
                            contract_data['raw_sol_code'] = decompile_result['raw_sol_code']
                            contract_data['optimized_sol_code'] = decompile_result['optimized_sol_code']
                            contract_data['decompiled_abi'] = decompile_result['abi_code']
                            contract_data['decompiled_at'] = decompile_result['decompiled_at']
                            contract_data['source_code'] = decompile_result['optimized_sol_code']
                            print(f"Contract {address} decompilation succeeded!")
                        else:
                            contract_data['decompiled'] = False
                            contract_data['decompile_error'] = decompile_result['error']
                            print(f"Contract {address} decompilation failed: {decompile_result['error']}")
                    else:
                        contract_data['decompiled'] = False
                        if not bytecode:
                            contract_data['decompile_error'] = 'Failed to fetch bytecode'
                        elif not self.decompile_enabled:
                            contract_data['decompile_error'] = 'Decompilation disabled'

                    return contract_data
            
            # Non-200 HTTP or unexpected response structure: treat as explorer API failure, still try to get bytecode
            bytecode = self._get_contract_bytecode(address)
            
            contract_data = {
                'address': address,
                'has_source_code': False,
                'source_code': None,
                'abi': None,
                'contract_name': 'Unknown',
                'error': f'Explorer API failed (http={response.status_code})',
                'bytecode': bytecode
            }
            
            # If bytecode exists and decompilation is enabled, try to decompile
            if bytecode and self.decompile_enabled:
                print(f"API fetch failed, but contract {address} has bytecode, starting decompilation...")
                decompile_result = self._decompile_contract(address, bytecode)
                
                if decompile_result['success']:
                    # Add decompilation info
                    contract_data['decompiled'] = True
                    contract_data['raw_sol_code'] = decompile_result['raw_sol_code']
                    contract_data['optimized_sol_code'] = decompile_result['optimized_sol_code']
                    contract_data['decompiled_abi'] = decompile_result['abi_code']
                    contract_data['decompiled_at'] = decompile_result['decompiled_at']
                    
                    # Use optimized code as source if decompilation succeeded
                    contract_data['source_code'] = decompile_result['optimized_sol_code']
                    print(f"Contract {address} decompilation succeeded!")
                else:
                    contract_data['decompiled'] = False
                    contract_data['decompile_error'] = decompile_result['error']
                    print(f"Contract {address} decompilation failed: {decompile_result['error']}")
            else:
                contract_data['decompiled'] = False
                if not bytecode:
                    contract_data['decompile_error'] = 'Failed to fetch bytecode'
                elif not self.decompile_enabled:
                    contract_data['decompile_error'] = 'Decompilation disabled'
            
            return contract_data
            
        except Exception as e:
            print(f"Failed to fetch contract info for {address}: {e}")
            
            # Fetch bytecode and try decompilation
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
            
            # If bytecode exists and decompilation is enabled, try to decompile
            if bytecode and self.decompile_enabled:
                print(f"API error, but contract {address} has bytecode, starting decompilation...")
                decompile_result = self._decompile_contract(address, bytecode)
                
                if decompile_result['success']:
                    # Add decompilation info
                    contract_data['decompiled'] = True
                    contract_data['raw_sol_code'] = decompile_result['raw_sol_code']
                    contract_data['optimized_sol_code'] = decompile_result['optimized_sol_code']
                    contract_data['decompiled_abi'] = decompile_result['abi_code']
                    contract_data['decompiled_at'] = decompile_result['decompiled_at']
                    
                    # Use optimized code as source if decompilation succeeded
                    contract_data['source_code'] = decompile_result['optimized_sol_code']
                    print(f"Contract {address} decompilation succeeded!")
                else:
                    contract_data['decompiled'] = False
                    contract_data['decompile_error'] = decompile_result['error']
                    print(f"Contract {address} decompilation failed: {decompile_result['error']}")
            else:
                contract_data['decompiled'] = False
                if not bytecode:
                    contract_data['decompile_error'] = 'Failed to fetch bytecode'
                elif not self.decompile_enabled:
                    contract_data['decompile_error'] = 'Decompilation disabled'
            
            return contract_data
    
    def _get_contract_bytecode(self, address: str) -> Optional[str]:
        """Fetch contract bytecode"""
        try:
            data = self._rpc_call("eth_getCode", [address, "latest"], timeout=10)
            if isinstance(data, dict) and data.get("result") and data["result"] != "0x":
                return data["result"]
            return None
            
        except Exception as e:
            print(f"Failed to fetch bytecode for {address}: {e}")
            return None
    
    def get_function_signature_from_api(self, method_id: str) -> str:
        """Query function signature via openchain.xyz API (with cache)"""
        try:
            # Ensure method_id format is correct
            if not method_id.startswith('0x'):
                method_id = '0x' + method_id
            
            # Check cache
            if method_id in self.function_signature_cache:
                print(f"Using cached function signature: {method_id} -> {self.function_signature_cache[method_id]}")
                return self.function_signature_cache[method_id]
            
            print(f"Querying function signature: {method_id}")
            url = f"https://api.openchain.xyz/signature-database/v1/lookup?filter=false&function={method_id}"
            
            response = requests.get(url, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('ok') and data.get('result', {}).get('function', {}).get(method_id):
                    functions = data['result']['function'][method_id]
                    if functions:
                        # Return the first matching function signature
                        function_signature = functions[0]['name']
                        # Save to cache
                        self.function_signature_cache[method_id] = function_signature
                        print(f"API query succeeded, cached: {method_id} -> {function_signature}")
                        return function_signature
            
            # Cache raw method_id on failure to avoid repeated requests
            self.function_signature_cache[method_id] = method_id
            print(f"API query failed, cached raw value: {method_id}")
            return method_id
            
        except Exception as e:
            print(f"Failed to query function signature {method_id}: {e}")
            # Also cache raw method_id on exception
            self.function_signature_cache[method_id] = method_id
            return method_id
    
    def get_transaction_trace(self, tx_hash: str) -> Dict[str, Any]:
        """Fetch transaction trace data"""
        # Alchemy Trace API docs show two request forms:
        # 1) Standard JSON-RPC (recommended / best compatibility)
        # 2) Body with only params array (docs may omit the method field)
        # We attempt a fallback and unwrap the response to ensure parse_trace_data gets the result list directly.
        return self._rpc_call(
            "trace_transaction",
            [tx_hash],
            timeout=30,
            allow_params_only_fallback=True,
            unwrap_alchemy_nested_result=True
        )

    def get_transaction_opcode_trace(
        self,
        tx_hash: str,
        *,
        timeout: int = 120,
        disable_storage: bool = False,
        disable_stack: bool = False,
        disable_memory: bool = False,
        enable_return_data: bool = True,
    ) -> Dict[str, Any]:
        """
        Fetch instruction-level trace (debug_traceTransaction structLogs).

        Typical use cases:
        - Output each opcode step (pc/op/gas/gasCost/depth)
        - Combine with stack/memory/storage for write-object-level forensics

        Notes:
        - Output can be very large; disable memory/stack/storage as needed.
        - Different node implementations may vary in tracerConfig/field support.
        """
        opts: Dict[str, Any] = {
            "disableStorage": disable_storage,
            "disableStack": disable_stack,
            "disableMemory": disable_memory,
        }
        # Some implementations support enableReturnData; unsupported ones will ignore or error (handled by caller)
        if enable_return_data:
            opts["enableReturnData"] = True

        return self._rpc_call(
            "debug_traceTransaction",
            [tx_hash, opts],
            timeout=timeout,
            allow_params_only_fallback=True,
        )

    def export_transaction_assembly(
        self,
        tx_hash: str,
        *,
        out_dir: str = "log/assembly",
        timeout: int = 120,
        include_json: bool = True,
        include_text: bool = True,
        disable_storage: bool = False,
        disable_stack: bool = False,
        disable_memory: bool = True,
        enable_return_data: bool = True,
        text_max_stack_items: int = 6,
        text_max_lines: Optional[int] = None,
    ) -> Dict[str, str]:
        """
        Export transaction-level assembly/instruction log to files.

        - JSON: full structLogs for programmatic analysis
        - TXT: human-readable opcode listing (pc/op/gas/depth + stack snippet)
        """
        from datetime import datetime

        os.makedirs(out_dir, exist_ok=True)
        ts = datetime.now().strftime("%Y%m%d_%H%M%S")
        tx_short = tx_hash[:10]

        resp = self.get_transaction_opcode_trace(
            tx_hash,
            timeout=timeout,
            disable_storage=disable_storage,
            disable_stack=disable_stack,
            disable_memory=disable_memory,
            enable_return_data=enable_return_data,
        )

        if not isinstance(resp, dict) or ("result" not in resp and "error" in resp):
            raise RuntimeError(f"debug_traceTransaction failed: {resp.get('error') if isinstance(resp, dict) else resp}")

        result = resp.get("result")
        if result is None:
            raise RuntimeError("debug_traceTransaction returned result=null")

        paths: Dict[str, str] = {}

        if include_json:
            json_path = os.path.join(out_dir, f"tx_assembly_{tx_short}_{ts}.json")
            with open(json_path, "w", encoding="utf-8") as f:
                json.dump(
                    {
                        "tx_hash": tx_hash,
                        "exported_at": ts,
                        "debug_traceTransaction": result,
                    },
                    f,
                    indent=2,
                    ensure_ascii=False,
                )
            paths["json"] = json_path

        if include_text:
            # Handle common response structure: {"structLogs":[...], "gas":..., "failed":..., "returnValue":...}
            struct_logs = result.get("structLogs") if isinstance(result, dict) else None
            if not isinstance(struct_logs, list):
                # Fallback: treat result directly as structLogs
                struct_logs = result if isinstance(result, list) else []

            txt_path = os.path.join(out_dir, f"tx_assembly_{tx_short}_{ts}.asm.txt")
            with open(txt_path, "w", encoding="utf-8") as f:
                f.write(f"tx_hash: {tx_hash}\n")
                f.write(f"exported_at: {ts}\n")
                f.write(
                    "columns: idx depth pc op gas gasCost | stack_top...\n"
                )
                f.write("-" * 100 + "\n")

                n = len(struct_logs)
                limit = min(n, text_max_lines) if isinstance(text_max_lines, int) else n

                for i in range(limit):
                    row = struct_logs[i]
                    if not isinstance(row, dict):
                        continue
                    depth = row.get("depth")
                    pc = row.get("pc")
                    op = row.get("op")
                    gas = row.get("gas")
                    gas_cost = row.get("gasCost")
                    stack = row.get("stack") if not disable_stack else None

                    stack_preview = ""
                    if isinstance(stack, list) and stack:
                        # Stack top is usually the last item
                        tail = stack[-text_max_stack_items:] if text_max_stack_items > 0 else []
                        stack_preview = " ".join(tail)

                    f.write(
                        f"{i:07d} d={depth} pc={pc} op={op} gas={gas} cost={gas_cost}"
                        + (f" | {stack_preview}" if stack_preview else "")
                        + "\n"
                    )

            paths["text"] = txt_path

        return paths
    
    def debug_transaction_trace(self, tx_hash: str) -> Dict[str, Any]:
        """Debug the transaction trace fetching process"""
        print(f"=== Debug Transaction Trace: {tx_hash} ===")
        print(f"Current network: {self.network} ({self.network_config['name']})")
        print(f"RPC URL: {self.rpc_url}")
        
        payload_preview = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "trace_transaction",
            "params": [tx_hash],
        }
        print(f"Request payload: {json.dumps(payload_preview, ensure_ascii=False)}")
        
        try:
            result = self._rpc_call(
                "trace_transaction",
                [tx_hash],
                timeout=30,
                allow_params_only_fallback=True,
                unwrap_alchemy_nested_result=True
            )
            print(f"Response content: {json.dumps(result, indent=2)}")
            
            # Check response format
            if 'result' in result:
                if result['result'] is None:
                    print("Warning: result field is null")
                    return {"error": "Trace data is empty - transaction may not exist or RPC node does not support tracing"}
                elif isinstance(result['result'], list):
                    print(f"Success: fetched {len(result['result'])} trace records")
                else:
                    print(f"Warning: unexpected result field type: {type(result['result'])}")
            elif 'error' in result:
                error_info = result['error']
                print(f"RPC error: {error_info}")
                
                # Check common errors
                if isinstance(error_info, dict):
                    error_code = error_info.get('code')
                    error_message = error_info.get('message', '')
                    
                    if error_code == -32601:
                        print("Error analysis: RPC node does not support trace_transaction method")
                        return {"error": "RPC node does not support trace_transaction method", "suggestion": "Try using an RPC node that supports tracing"}
                    elif error_code == -32602:
                        print("Error analysis: invalid parameters")
                        return {"error": "Invalid transaction hash", "suggestion": "Check the transaction hash format"}
                    elif "not found" in error_message.lower():
                        print("Error analysis: transaction not found")
                        return {"error": "Transaction does not exist", "suggestion": "Verify the transaction hash is correct"}
                    else:
                        return {"error": f"RPC error: {error_message}"}
                else:
                    return {"error": f"RPC error: {error_info}"}
            else:
                print("Warning: response has neither result nor error field")
                return {"error": "Invalid RPC response format"}
            
            return result
            
        except requests.exceptions.Timeout:
            print("Error: request timed out")
            return {"error": "Request timed out", "suggestion": "Check network connection or try another RPC node"}
        except requests.exceptions.ConnectionError:
            print("Error: connection failed")
            return {"error": "Connection failed", "suggestion": "Check that the RPC URL is correct and network is reachable"}
        except json.JSONDecodeError as e:
            print(f"Error: JSON parsing failed - {e}")
            return {"error": "Invalid response format", "suggestion": "RPC node did not return valid JSON"}
        except Exception as e:
            print(f"Unknown error: {e}")
            return {"error": f"Unknown error: {str(e)}"}
    
    def check_rpc_capabilities(self) -> Dict[str, Any]:
        """Check RPC node capabilities"""
        print(f"=== Check RPC Node Capabilities ===")
        print(f"Current network: {self.network} ({self.network_config['name']})")
        print(f"RPC URL: {self.rpc_url}")
        
        capabilities = {
            "basic_rpc": False,
            "trace_transaction": False,
            "trace_block": False,
            "debug_traceTransaction": False
        }
        
        # Test basic RPC functionality
        try:
            result = self._rpc_call("eth_blockNumber", [], timeout=10)
            if isinstance(result, dict) and 'result' in result:
                capabilities["basic_rpc"] = True
                print(f"✓ Basic RPC working - current block: {int(result['result'], 16)}")
            else:
                print("✗ Basic RPC not working")
        except Exception as e:
            print(f"✗ Basic RPC test failed: {e}")
        
        # Test trace_transaction
        try:
            result = self._rpc_call(
                "trace_transaction",
                ["0x0000000000000000000000000000000000000000000000000000000000000000"],
                timeout=10,
                allow_params_only_fallback=True,
                unwrap_alchemy_nested_result=True
            )
            if isinstance(result, dict) and 'error' in result and isinstance(result['error'], dict) and result['error'].get('code') == -32601:
                print("✗ trace_transaction method not supported")
            elif isinstance(result, dict) and ('result' in result or ('error' in result and (not isinstance(result['error'], dict) or result['error'].get('code') != -32601))):
                capabilities["trace_transaction"] = True
                print("✓ trace_transaction method supported")
        except Exception as e:
            print(f"✗ trace_transaction test error: {e}")
        
        # Test debug_traceTransaction
        try:
            result = self._rpc_call(
                "debug_traceTransaction",
                ["0x0000000000000000000000000000000000000000000000000000000000000000"],
                timeout=10,
                allow_params_only_fallback=True
            )
            if isinstance(result, dict) and 'error' in result and isinstance(result['error'], dict) and result['error'].get('code') == -32601:
                print("✗ debug_traceTransaction method not supported")
            elif isinstance(result, dict) and ('result' in result or ('error' in result and (not isinstance(result['error'], dict) or result['error'].get('code') != -32601))):
                capabilities["debug_traceTransaction"] = True
                print("✓ debug_traceTransaction method supported")
        except Exception as e:
            print(f"✗ debug_traceTransaction test error: {e}")
        
        print(f"\nNode capabilities summary: {capabilities}")
        
        # Provide suggestions
        if not capabilities["trace_transaction"]:
            print("\nSuggestions:")
            print("- Current RPC node does not support trace_transaction method")
            print("- Try using one of these tracing-capable RPC providers:")
            print("  - Alchemy (supports trace_* methods)")
            print("  - QuickNode (supports trace_* methods)")
        
        return capabilities
    
    def parse_trace_data(self, trace_response: Dict[str, Any]) -> Dict[str, Any]:
        """Parse transaction trace data"""
        if 'result' not in trace_response:
            return {"error": "Invalid trace data"}
        
        traces = trace_response['result']
        
        # Parse basic info
        if not traces:
            return {"error": "Empty trace data"}
        
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
            "contract_addresses": set(),  # Collect addresses only, not detailed info
            "summary": {
                "total_calls": len(traces),
                "call_types": {},
                "total_value_transferred": 0
            }
        }
        
        # Parse each call
        total_traces = len(traces)
        print(f"Parsing {total_traces} trace records...")
        
        from tqdm import tqdm
        for i, trace in tqdm(enumerate(traces), total=len(traces), desc="Parsing trace records"):
            # Show progress
            if total_traces > 10:  # Only show progress when call count is large
                if i % max(1, total_traces // 10) == 0 or i == total_traces - 1:
                    progress = (i + 1) / total_traces * 100
                    print(f"Parsing progress: {i + 1}/{total_traces} ({progress:.1f}%)")
            
            print(f"Parsing call {i+1}...")
            call_info = self._parse_single_trace(trace, i)
            print(f"Call type: {call_info['call_type']}")
            print(f"From address: {call_info['from']}")
            print(f"To address: {call_info['to']}")
            
            parsed_data["call_tree"].append(call_info)
            
            # Collect addresses
            parsed_data["addresses_involved"].add(call_info["from"])
            parsed_data["addresses_involved"].add(call_info["to"])
            print(f"Collected addresses: {call_info['from']}, {call_info['to']}")
            
            # Collect contract addresses (both from and to may be contract addresses)
            if call_info["from"]:
                parsed_data["contract_addresses"].add(call_info["from"])
            if call_info["to"]:
                parsed_data["contract_addresses"].add(call_info["to"])
            
            # Collect value transfers
            if call_info["value"] > 0:
                print(f"Value transfer detected: {call_info['value'] / 10**18} ETH")
                parsed_data["value_transfers"].append({
                    "from": call_info["from"],
                    "to": call_info["to"],
                    "value": call_info["value"],
                    "value_eth": call_info["value"] / 10**18,
                    "trace_index": i
                })
                parsed_data["summary"]["total_value_transferred"] += call_info["value"]
            
            # Count call types
            call_type = call_info["call_type"]
            parsed_data["summary"]["call_types"][call_type] = parsed_data["summary"]["call_types"].get(call_type, 0) + 1
            
            # Collect function calls
            if call_info.get("decoded_input"):
                print(f"Function call: {call_info['decoded_input']}")
                parsed_data["function_calls"].append({
                    "trace_index": i,
                    "function": call_info["decoded_input"],
                    "from": call_info["from"],
                    "to": call_info["to"]
                })
        
        # Convert sets to lists for JSON serialization
        parsed_data["addresses_involved"] = list(parsed_data["addresses_involved"])
        parsed_data["contract_addresses"] = list(parsed_data["contract_addresses"])
        parsed_data["summary"]["total_value_transferred_eth"] = parsed_data["summary"]["total_value_transferred"] / 10**18
        
        return parsed_data
    
    def _parse_single_trace(self, trace: Dict[str, Any], index: int) -> Dict[str, Any]:
        """Parse a single trace record"""
        action = trace.get('action', {})
        result = trace.get('result') or {}
        
        # Extract function signature from input data
        input_data = action.get('input', '')
        function_signature = self._extract_function_signature(input_data)
        
        # Parse function parameters
        decoded_input = ""
        if function_signature and function_signature != input_data[:10]:
            # Only decode if function signature differs from raw method ID
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
        
        # Add decoded input to result if successfully parsed
        if decoded_input:
            call_info["decoded_input"] = decoded_input
        
        return call_info
    
    def _extract_function_signature(self, input_data: str) -> str:
        """Extract function signature from input data"""
        if not input_data or input_data == '0x':
            return ""
        
        # Common function signature mapping (fallback)
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
            
            # Try API query first
            api_signature = self.get_function_signature_from_api(method_id)
            if api_signature != method_id:
                return api_signature
            
            # Fall back to local mapping if API query failed
            return function_signatures.get(method_id, method_id)
        
        return ""
    
    def save_to_json(self, data: Dict[str, Any], filename: str = None) -> str:
        """Save data to JSON file"""
        # Ensure log directory exists
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
        """Save call data to CSV file"""
        # Ensure log directory exists
        self._ensure_log_directory()
        
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            tx_hash = data.get('transaction_info', {}).get('hash', 'unknown')[:10]
            filename = f"tx_calls_{tx_hash}_{timestamp}.csv"
        
        filepath = os.path.join(self.log_dir, filename)
        
        # Create DataFrame
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
    
    def save_contract_info_to_json(self, contract_info: Dict[str, Any], filename: str = None) -> str:
        """Save contract info to a separate JSON file"""
        # Ensure log directory exists
        self._ensure_log_directory()
        
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"tx_contracts_{timestamp}.json"
        
        filepath = os.path.join(self.log_dir, filename)
        
        # Export contract source code to separate .sol files (verified sources, multi-file projects, decompiled sources)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        sources_root = Path(self.log_dir) / "sources" / f"tx_contracts_{timestamp}"
        sources_root.mkdir(parents=True, exist_ok=True)

        def _sanitize_filename(name: str) -> str:
            name = (name or "").strip()
            if not name:
                return "Unknown"
            # Keep only common safe characters
            return re.sub(r"[^0-9A-Za-z._-]+", "_", name)

        def _normalize_newlines(s: str) -> str:
            return s.replace("\r\n", "\n").replace("\r", "\n")

        def _extract_sources_from_source_code(source_code: str) -> Dict[str, str]:
            """
            Parse the SourceCode/source_code string from explorer API into a multi-file mapping.

            - Single file: returns {"<Contract>.sol": content} directly
            - Multi-file project (common on Etherscan/BscScan): source_code is a JSON string,
              often wrapped in double braces {{ ... }}; parsed to read obj["sources"][path]["content"].
            """
            if not isinstance(source_code, str):
                return {}
            raw = source_code.strip()
            if not raw:
                return {}

            candidate = raw
            # Common Etherscan pattern: extra layer of braces e.g. "{{ ... }}", strip one layer
            if candidate.startswith("{{") and candidate.endswith("}}"):
                candidate = candidate[1:-1]

            # Try parsing as JSON (multi-file project)
            if candidate.startswith("{") and ("\"sources\"" in candidate or "'sources'" in candidate):
                try:
                    obj = json.loads(candidate)
                    sources = obj.get("sources")
                    if isinstance(sources, dict):
                        out: Dict[str, str] = {}
                        for rel_path, file_obj in sources.items():
                            if not rel_path:
                                continue
                            if isinstance(file_obj, dict) and isinstance(file_obj.get("content"), str):
                                out[str(rel_path)] = _normalize_newlines(file_obj["content"])
                        if out:
                            return out
                except Exception:
                    # JSON parse failed, treat as single file
                    pass

            # Default: single file
            return {"contract.sol": _normalize_newlines(raw)}
        for address, info in contract_info.items():
            # 1) Verified source: export as .sol (single or multi-file project)
            if info.get("has_source_code") and isinstance(info.get("source_code"), str) and info.get("source_code"):
                contract_dir = sources_root / address.lower()
                contract_dir.mkdir(parents=True, exist_ok=True)

                contract_name = _sanitize_filename(info.get("contract_name") or f"contract_{address[2:10]}")
                sources = _extract_sources_from_source_code(info["source_code"])

                exported_files: List[str] = []
                exported_files_rel: List[str] = []
                entry_candidates: List[str] = []

                # Single file fallback: use a friendlier filename
                if list(sources.keys()) == ["contract.sol"]:
                    sources = {f"{contract_name}.sol": sources["contract.sol"]}

                for rel_path, content in sources.items():
                    # Prevent writing outside directory
                    rel_path = rel_path.lstrip("/").replace("..", "__")
                    out_path = contract_dir / rel_path
                    out_path.parent.mkdir(parents=True, exist_ok=True)
                    try:
                        out_path.write_text(content, encoding="utf-8")
                        exported_files.append(str(out_path))
                        exported_files_rel.append(str(out_path.relative_to(contract_dir)))

                        # Rough identification of entry point files (containing contract/interface/library definitions)
                        if re.search(r"\b(contract|interface|library)\s+[A-Za-z_][A-Za-z0-9_]*\b", content):
                            entry_candidates.append(str(out_path.relative_to(contract_dir)))
                    except Exception as e:
                        print(f"Failed to export source for {address} -> {out_path}: {e}")

                if exported_files:
                    info["source_export_dir"] = str(contract_dir)
                    info["source_files"] = exported_files
                    info["source_files_rel"] = exported_files_rel
                    if entry_candidates:
                        info["source_entry_candidates"] = entry_candidates

                    # Generate an index file for quick main contract file lookup
                    try:
                        index_path = contract_dir / "__index__.txt"
                        lines = []
                        lines.append(f"address: {address}\n")
                        lines.append(f"contract_name: {info.get('contract_name')}\n")
                        lines.append("\nentry_candidates:\n")
                        for p in entry_candidates:
                            lines.append(f"- {p}\n")
                        lines.append("\nall_files:\n")
                        for p in exported_files_rel:
                            lines.append(f"- {p}\n")
                        index_path.write_text("".join(lines), encoding="utf-8")
                        exported_files.append(str(index_path))
                        exported_files_rel.append(str(index_path.relative_to(contract_dir)))
                        info["source_index_file"] = str(index_path)
                    except Exception as e:
                        print(f"Failed to generate source index for {address}: {e}")

                # Also persist ABI separately (if available)
                if isinstance(info.get("abi"), str) and info["abi"]:
                    abi_path = contract_dir / f"{contract_name}.abi.json"
                    try:
                        abi_path.write_text(info["abi"], encoding="utf-8")
                        info["abi_file"] = str(abi_path)
                        # Allow transaction_processor to copy ABI file later
                        if exported_files:
                            exported_files.append(str(abi_path))
                            exported_files_rel.append(str(abi_path.relative_to(contract_dir)))
                    except Exception as e:
                        print(f"Failed to export ABI for {address} -> {abi_path}: {e}")

            if info.get('decompiled') and info.get('optimized_sol_code'):
                # Save optimized source code
                sol_filename = f"decompiled_{address[2:12]}_{timestamp}.sol"
                sol_filepath = os.path.join(self.log_dir, sol_filename)
                
                with open(sol_filepath, 'w', encoding='utf-8') as f:
                    f.write(info['optimized_sol_code'])
                
                # Add file path to contract info
                info['optimized_sol_file'] = sol_filepath
                print(f"Decompiled source code saved to: {sol_filepath}")
                
                # Save raw decompiled code if available
                if info.get('raw_sol_code'):
                    raw_sol_filename = f"raw_decompiled_{address[2:12]}_{timestamp}.sol"
                    raw_sol_filepath = os.path.join(self.log_dir, raw_sol_filename)
                    
                    with open(raw_sol_filepath, 'w', encoding='utf-8') as f:
                        f.write(info['raw_sol_code'])
                    
                    info['raw_sol_file'] = raw_sol_filepath
                    print(f"Raw decompiled code saved to: {raw_sol_filepath}")
                
                # Save decompiled ABI if available
                if info.get('decompiled_abi'):
                    abi_filename = f"decompiled_abi_{address[2:12]}_{timestamp}.json"
                    abi_filepath = os.path.join(self.log_dir, abi_filename)
                    
                    with open(abi_filepath, 'w', encoding='utf-8') as f:
                        f.write(info['decompiled_abi'])
                    
                    info['decompiled_abi_file'] = abi_filepath
                    print(f"Decompiled ABI saved to: {abi_filepath}")
        
        # Save contract info JSON
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(contract_info, f, indent=2, ensure_ascii=False)
        
        return filepath
    
    def generate_summary_report(self, data: Dict[str, Any], contract_info: Dict[str, Any] = None) -> str:
        """Generate transaction summary report"""
        tx_info = data.get('transaction_info', {})
        summary = data.get('summary', {})
        
        report = f"""
=== Transaction Trace Analysis Report ===

Network Info:
- Network: {self.network_config['name']}
- Chain ID: {self.chain_id}

Basic Info:
- Tx Hash: {tx_info.get('hash', 'N/A')}
- Block Number: {tx_info.get('block_number', 'N/A')}
- Tx Position: {tx_info.get('position', 'N/A')}

Call Statistics:
- Total Calls: {summary.get('total_calls', 0)}
- Call Type Distribution: {summary.get('call_types', {})}
- Total Value Transferred: {summary.get('total_value_transferred_eth', 0):.6f} ETH

Addresses Involved: {len(data.get('addresses_involved', []))}
Contract Addresses: {len(data.get('contract_addresses', []))}
Value Transfers: {len(data.get('value_transfers', []))}
Function Calls: {len(data.get('function_calls', []))}

=== Contract Address List ===
"""
        
        # Display contract address list
        for address in data.get('contract_addresses', []):
            report += f"\nContract: {address}"
            if contract_info and address in contract_info:
                info = contract_info[address]
                report += f" - {info.get('contract_name', 'Unknown')}"
                report += f" ({'has source' if info.get('has_source_code') else 'no source'})"
        
        # Add detailed info if contract info is available
        if contract_info:
            report += f"\n\n=== Contract Details ==="
            
            for address, info in contract_info.items():
                report += f"\n\nContract: {address}\n"
                report += f"  Name: {info.get('contract_name', 'Unknown')}\n"
                report += f"  Has Source: {'yes' if info.get('has_source_code') else 'no'}\n"
                
                if info.get('has_source_code'):
                    report += f"  Compiler: {info.get('compiler_version', 'N/A')}\n"
                    report += f"  Optimization: {info.get('optimization_used', 'N/A')}\n"
                    report += f"  License: {info.get('license_type', 'N/A')}\n"
                    report += f"  Proxy: {info.get('proxy', 'N/A')}\n"
                else:
                    bytecode_length = len(info.get('bytecode', '')) if info.get('bytecode') else 0
                    report += f"  Bytecode length: {bytecode_length} chars\n"
                    
                    # Add decompilation info
                    if info.get('decompiled') is not None:
                        report += f"  Decompilation: {'succeeded' if info.get('decompiled') else 'failed'}\n"
                        
                        if info.get('decompiled'):
                            report += f"  Decompiled at: {info.get('decompiled_at', 'N/A')}\n"
                            if info.get('optimized_sol_file'):
                                report += f"  Optimized code: {info.get('optimized_sol_file')}\n"
                            if info.get('raw_sol_file'):
                                report += f"  Raw code: {info.get('raw_sol_file')}\n"
                            if info.get('decompiled_abi_file'):
                                report += f"  ABI file: {info.get('decompiled_abi_file')}\n"
                        else:
                            if info.get('decompile_error'):
                                report += f"  Decompile error: {info.get('decompile_error')}\n"
                
                if info.get('error'):
                    report += f"  Error: {info['error']}\n"
        
        report += f"\n=== Detailed Call Chain ===\n"
        
        for i, call in enumerate(data.get('call_tree', [])):
            indent = "  " * len(call.get('trace_address', []))
            report += f"{indent}{i}. {call['call_type']}: {call['from'][:10]}... -> {call['to'][:10]}...\n"
            
            # Show decoded parameters if available
            if call.get('decoded_input'):
                report += f"{indent}   Function: {call['decoded_input']}\n"
            
            report += f"{indent}   Value: {call['value_eth']:.6f} ETH\n"
            
            # Add contract info
            if contract_info and call['to'] in contract_info:
                contract = contract_info[call['to']]
                report += f"{indent}   Contract: {contract.get('contract_name', 'Unknown')}\n"
        
        return report
    
    def save_report(self, report: str, filename: str = None) -> str:
        """Save report to file"""
        # Ensure log directory exists
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
        Call LLM API for code optimization.
        
        Args:
            prompt: Prompt to send to the LLM.
            
        Returns:
            Optimized code returned by the LLM.
        """
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
    
    def heimdall_decompile(self, contract_address: str, bytecode: str) -> Tuple[Optional[str], Optional[str]]:
        """
        Decompile contract using Heimdall.
        
        Args:
            contract_address: Contract address.
            bytecode: Contract bytecode.
            
        Returns:
            Tuple of (decompiled sol code, ABI code), or (None, None) on failure.
        """
        print(f"Decompiling contract {contract_address} with Heimdall...")
        
        try:
            # Ensure tx-level output directory exists (i.e. output/local/<tx>/)
            try:
                Path(self.output_local_dir).mkdir(parents=True, exist_ok=True)
            except Exception:
                # Directory creation failure should not block decompilation; will try reading from default output/local later
                pass

            # Create temp file for bytecode
            with tempfile.NamedTemporaryFile(mode='w', suffix='.bin', delete=False) as temp_file:
                temp_file.write(bytecode)
                temp_file_path = temp_file.name
            
            # Generate contract name
            contract_name = f"Contract_{contract_address[2:12]}"  # Use first 10 chars of address
            
            # Execute decompilation
            result = decompile(
                target=temp_file_path,
                name=contract_name,
                include_sol=True,
                include_yul=False
            )
            
            # Clean up temp file
            os.unlink(temp_file_path)
            
            # Heimdall default output path (fixed output/local/)
            sol_file_default = Path("output") / "local" / f"{contract_name}-decompiled.sol"
            abi_file_default = Path("output") / "local" / f"{contract_name}-abi.json"

            # New tx-level output path (output/local/<tx_hash>/...)
            sol_file_tx = Path(self.output_local_dir) / f"{contract_name}-decompiled.sol"
            abi_file_tx = Path(self.output_local_dir) / f"{contract_name}-abi.json"

            # If tx-level dir is enabled and Heimdall still wrote to default dir, move files (avoid mixing different txs)
            if sol_file_tx.resolve() != sol_file_default.resolve() and sol_file_default.exists():
                try:
                    sol_file_tx.parent.mkdir(parents=True, exist_ok=True)
                    sol_file_default.replace(sol_file_tx)
                except Exception:
                    # If move fails, fall back to reading from default path
                    pass
            if abi_file_tx.resolve() != abi_file_default.resolve() and abi_file_default.exists():
                try:
                    abi_file_tx.parent.mkdir(parents=True, exist_ok=True)
                    abi_file_default.replace(abi_file_tx)
                except Exception:
                    pass
            
            sol_code = None
            abi_code = None
            
            # Prefer tx-level dir, fall back to default dir
            sol_path_to_read = sol_file_tx if sol_file_tx.exists() else sol_file_default
            abi_path_to_read = abi_file_tx if abi_file_tx.exists() else abi_file_default

            if sol_path_to_read.exists():
                with open(sol_path_to_read, 'r', encoding='utf-8') as f:
                    sol_code = f.read()
                print(f"Successfully read decompiled Solidity code: {sol_path_to_read}")
            else:
                print(f"Warning: decompiled Solidity file not found: {sol_file_tx} or {sol_file_default}")
            
            if abi_path_to_read.exists():
                with open(abi_path_to_read, 'r', encoding='utf-8') as f:
                    abi_code = f.read()
                print(f"Successfully read ABI file: {abi_path_to_read}")
            else:
                print(f"Warning: ABI file not found: {abi_file_tx} or {abi_file_default}")
            
            return sol_code, abi_code
            
        except Exception as e:
            print(f"Heimdall decompilation failed for {contract_address}: {e}")
            # Clean up temp file
            try:
                os.unlink(temp_file_path)
            except:
                pass
            return None, None
    
    def optimize_with_ai(self, raw_sol_code: str, abi_code: str, contract_address: str) -> str:
        """
        Optimize decompiled code using LLM.
        
        Args:
            raw_sol_code: Raw decompiled Solidity code.
            abi_code: ABI code.
            contract_address: Contract address.
            
        Returns:
            Optimized Solidity code.
        """
        print(f"Optimizing decompiled code with LLM: {contract_address}")
        
        prompt = f"""
You are a professional Solidity smart contract developer and code auditor. I have a smart contract recovered from bytecode using the Heimdall decompiler. Please help optimize and refactor it for clarity and readability.

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
    
    def _decompile_contract(self, address: str, bytecode: str) -> Dict[str, Any]:
        """
        Execute the contract decompilation pipeline.
        
        Args:
            address: Contract address.
            bytecode: Contract bytecode.
            
        Returns:
            Decompilation result dictionary.
        """
        if not self.decompile_enabled:
            return {
                'success': False,
                'error': 'Decompilation disabled'
            }
        
        try:
            # Decompile with Heimdall
            raw_sol_code, abi_code = self.heimdall_decompile(address, bytecode)
            
            if not raw_sol_code:
                return {
                    'success': False,
                    'error': 'Heimdall decompilation failed'
                }
            
            # Optimize with LLM
            optimized_sol_code = self.optimize_with_ai(raw_sol_code, abi_code or "", address)
            
            return {
                'success': True,
                'raw_sol_code': raw_sol_code,
                'abi_code': abi_code,
                'optimized_sol_code': optimized_sol_code,
                'decompiled_at': datetime.now().isoformat()
            }
            
        except Exception as e:
            print(f"Decompilation error for {address}: {e}")
            return {
                'success': False,
                'error': f'Decompilation error: {str(e)}'
            }
    
    def analyze_contracts(self, addresses: List[str]) -> Dict[str, Any]:
        """Analyze contract information for a list of addresses"""
        contract_info = {}
        
        valid_addresses = [addr for addr in addresses if addr]
        total_contracts = len(valid_addresses)
        print(f"Fetching info for {total_contracts} contracts...")
        
        for i, address in enumerate(valid_addresses):
            progress = (i + 1) / total_contracts * 100
            print(f"Fetching contract info ({i + 1}/{total_contracts}, {progress:.1f}%): {address}")
            contract_info[address] = self.get_contract_info_from_etherscan(address)
        
        return contract_info


# Usage example
if __name__ == "__main__":
    # Initialize analyzer - using Base network (default)
    # analyzer = TransactionTraceAnalyzer()
    
    # Or explicitly specify network
    analyzer = TransactionTraceAnalyzer(network='bsc')    # Use BSC network
    # analyzer = TransactionTraceAnalyzer(network='bsc')  # Recommended: use BSC only
    
    # Can also switch network at runtime
    # analyzer.switch_network('ethereum')  # Switch to Ethereum network
    
    # Decompilation control (enabled by default)
    # analyzer.enable_decompile(True)   # Enable decompilation
    # analyzer.disable_decompile()      # Disable decompilation
    
    print("=== Transaction Trace Analyzer ===")
    print("Features:")
    print("- Automatically fetch transaction trace data")
    print("- Parse call chains and function parameters")
    print("- Separate contract analysis module")
    print("- Decompile contracts without public source code")
    print("- Decompile bytecode using Heimdall")
    print("- Optimize decompiled code using LLM")
    print("- Generate detailed analysis reports")
    print()
    
    # Example tx hash - replace with actual tx hash
    tx_hash = "0x86486dceddcf581d43ab74e2ca381d4a8ee30a405ae17a81f4615986c0c75419"
    
    # Step 1: Fetch and parse transaction trace data
    print("=== Step 1: Analyze Transaction Trace ===")
    print("Fetching transaction trace data...")
    trace_data = analyzer.get_transaction_trace(tx_hash)
    
    print("Parsing transaction trace data...")
    parsed_data = analyzer.parse_trace_data(trace_data)
    
    if "error" in parsed_data:
        print(f"Error: {parsed_data['error']}")
        exit(1)
    
    # Save trace data
    json_file = analyzer.save_to_json(parsed_data)
    csv_file = analyzer.save_to_csv(parsed_data)
    
    print(f"Trace data saved to: {json_file}")
    print(f"Call data saved to: {csv_file}")
    
    print(f"\nDetected {len(parsed_data.get('contract_addresses', []))} contract addresses")
    
    # Step 2: Optional contract analysis
    print("\n=== Step 2: Analyze Contract Info ===")
    
    # User can choose whether to perform detailed contract analysis
    analyze_contracts = True  # Set to False to skip contract analysis
    
    contract_info = {}
    if analyze_contracts:
        print("Analyzing contract info...")
        contract_addresses = parsed_data.get('contract_addresses', [])
        contract_info = analyzer.analyze_contracts(contract_addresses)
        
        # Save contract info
        contract_file = analyzer.save_contract_info_to_json(contract_info)
        print(f"Contract info saved to: {contract_file}")
        
        # Decompilation statistics
        decompiled_count = 0
        total_contracts = 0
        
        for address, info in contract_info.items():
            total_contracts += 1
            if info.get('decompiled'):
                decompiled_count += 1
        
        print(f"\n=== Decompilation Statistics ===")
        print(f"Total contracts: {total_contracts}")
        print(f"Successfully decompiled: {decompiled_count}")
        print(f"Decompilation rate: {decompiled_count/total_contracts*100:.1f}%" if total_contracts > 0 else "N/A")
    else:
        print("Skipping contract analysis")
    
    # Step 3: Generate comprehensive report
    print("\n=== Step 3: Generate Analysis Report ===")
    
    # Generate report (with or without contract info)
    report = analyzer.generate_summary_report(parsed_data, contract_info if analyze_contracts else None)
    print(report)
    
    # Save report
    report_file = analyzer.save_report(report, f"tx_report_{tx_hash[:10]}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt")
    print(f"Report saved to: {report_file}")
    
    # Save function signature cache
    analyzer._save_function_signature_cache()
    print(f"Function signature cache saved, {len(analyzer.function_signature_cache)} entries")
    
    print("\n=== Analysis Complete ===")
    print("Output file structure:")
    print("- tx_trace_*.json: transaction trace data (call chain, function calls, value transfers, etc.)")
    print("- tx_calls_*.csv: simplified call data table")
    print("- tx_contracts_*.json: contract info (source code, ABI, decompiled code, etc.)")
    print("- tx_report_*.txt: comprehensive analysis report")
    print("- decompiled_*.sol: decompiled contract source code files")
    print()
    print("Note: decompilation requires the following environment variables:")
    print("- OPENAI_API_KEY: OpenAI API key")
    print("- OPENAI_API_BASE: OpenAI API base URL")
    print("- VUL_MODEL: model to use (optional, default: gpt-4o-mini)")
