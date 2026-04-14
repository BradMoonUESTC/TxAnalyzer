#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import json
import shutil
import hashlib
from pathlib import Path
from typing import Optional

class TransactionProcessor:
    def __init__(self, log_dir='log'):
        self.log_dir = Path(log_dir)
        self.output_dir = Path('transactions')

    def _safe_trace_filename(self, trace_index, trace_address) -> str:
        """
        生成可落盘的 trace 文件名。

        目标：
        - 尽可能保留 trace_index + trace_address 信息（顺序/深度）
        - 避免 macOS / APFS 单个文件名过长（通常 <=255 字符）
        """
        idx = str(trace_index if trace_index is not None else 0)
        addr_list = trace_address if isinstance(trace_address, list) else []
        depth = len(addr_list)

        if not addr_list:
            name = f"{idx}_d0"
        else:
            parts = [str(a) for a in addr_list]
            full = "_".join(parts)
            name = f"{idx}_d{depth}_{full}"

            # 如果太长，降级：保留前缀 + hash + 深度信息
            if len(name) > 200:
                prefix_parts = parts[:12]
                prefix = "_".join(prefix_parts)
                h = hashlib.sha1(full.encode("utf-8")).hexdigest()[:12]
                name = f"{idx}_d{depth}_{prefix}__h{h}__n{depth}"

        filename = f"{name}.json"

        # 兜底：仍过长则只用 hash（trace_index 仍然保留用于排序/去重）
        if len(filename) > 240:
            h = hashlib.sha1(filename.encode("utf-8")).hexdigest()[:16]
            filename = f"{idx}_d{depth}__h{h}.json"

        return filename
        
    def find_transaction_files(self, tx_hash):
        """查找特定交易哈希的所有相关文件"""
        # 提取交易哈希的前10个字符作为文件名匹配
        tx_short = tx_hash[:10]
        
        files = {
            'contracts': None,
            'trace': None,
            'report': None
        }
        
        # 查找匹配的文件
        for file_path in self.log_dir.glob(f'*{tx_short}*'):
            if 'contracts' in file_path.name:
                files['contracts'] = file_path
            elif 'trace' in file_path.name and file_path.suffix == '.json':
                files['trace'] = file_path
            elif 'report' in file_path.name:
                files['report'] = file_path
                
        return files
    
    def process_contracts(self, contracts_file, output_dir):
        """处理contracts文件，按合约地址分别保存"""
        if not contracts_file or not contracts_file.exists():
            print(f"Contracts文件不存在: {contracts_file}")
            return
            
        # 创建contracts文件夹
        contracts_dir = output_dir / 'contracts'
        contracts_dir.mkdir(parents=True, exist_ok=True)
        
        # 读取contracts文件
        try:
            with open(contracts_file, 'r', encoding='utf-8') as f:
                contracts_data = json.load(f)
        except json.JSONDecodeError as e:
            print(f"解析contracts文件失败: {e}")
            return
        
        # 为每个合约创建单独的文件
        for contract_address, contract_info in contracts_data.items():
            # 清理地址，去掉0x前缀
            clean_address = contract_address.replace('0x', '')
            contract_file = contracts_dir / f"{clean_address}.json"
            
            # 保存合约信息
            with open(contract_file, 'w', encoding='utf-8') as f:
                json.dump(contract_info, f, indent=2, ensure_ascii=False)

            # 如果上一步已经把源码导出成 .sol 文件，这里把源码也拷贝到 transactions/<tx>/ 下
            try:
                source_export_dir = contract_info.get("source_export_dir")
                source_files = contract_info.get("source_files") or []
                if source_export_dir and source_files:
                    sources_out_dir = output_dir / "contract_sources" / clean_address
                    sources_out_dir.mkdir(parents=True, exist_ok=True)

                    for src in source_files:
                        src_path = Path(src)
                        if not src_path.exists():
                            continue
                        try:
                            rel = src_path.relative_to(Path(source_export_dir))
                            dst_path = sources_out_dir / rel
                        except Exception:
                            dst_path = sources_out_dir / src_path.name
                        dst_path.parent.mkdir(parents=True, exist_ok=True)
                        shutil.copy2(src_path, dst_path)
            except Exception as e:
                print(f"拷贝源码文件失败 {contract_address}: {e}")

            # 拷贝反编译产物（若存在），确保“无源码合约”也在交易目录下有完整材料
            try:
                def _copy_if_exists(src: Optional[str], dst: Path):
                    if not src:
                        return
                    src_path = Path(src)
                    if not src_path.exists():
                        return
                    dst.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(src_path, dst)

                decompiled_out_dir = output_dir / "contract_sources" / clean_address / "decompiled"
                _copy_if_exists(contract_info.get("optimized_sol_file"), decompiled_out_dir / "optimized.sol")
                _copy_if_exists(contract_info.get("raw_sol_file"), decompiled_out_dir / "raw.sol")
                _copy_if_exists(contract_info.get("decompiled_abi_file"), decompiled_out_dir / "abi.json")
            except Exception as e:
                print(f"拷贝反编译产物失败 {contract_address}: {e}")
                
        print(f"已处理 {len(contracts_data)} 个合约文件")
    
    def process_trace(self, trace_file, output_dir):
        """处理trace文件，按trace_index和trace_address拆分保存"""
        if not trace_file or not trace_file.exists():
            print(f"Trace文件不存在: {trace_file}")
            return
            
        # 创建trace文件夹
        trace_dir = output_dir / 'trace'
        # 为避免上次失败产生的“半成品长文件名”残留，这里每次重建 trace/ 目录
        if trace_dir.exists():
            shutil.rmtree(trace_dir)
        trace_dir.mkdir(parents=True, exist_ok=True)
        
        # 读取trace文件
        try:
            with open(trace_file, 'r', encoding='utf-8') as f:
                trace_data = json.load(f)
        except json.JSONDecodeError as e:
            print(f"解析trace文件失败: {e}")
            return
        
        # 保存交易信息
        if 'transaction_info' in trace_data:
            transaction_info_file = trace_dir / 'transaction_info.json'
            with open(transaction_info_file, 'w', encoding='utf-8') as f:
                json.dump(trace_data['transaction_info'], f, indent=2, ensure_ascii=False)
        
        # 处理call_tree中的每个trace
        if 'call_tree' in trace_data:
            call_tree = trace_data['call_tree']

            # 写一个索引，便于通过 trace_address 找到文件（同时避免文件名过长）
            files_index = []
            
            for trace_item in call_tree:
                trace_index = trace_item.get('trace_index', 0)
                trace_address = trace_item.get('trace_address', [])
                
                filename = self._safe_trace_filename(trace_index, trace_address)
                    
                trace_file_path = trace_dir / filename
                
                # 保存单个trace
                with open(trace_file_path, 'w', encoding='utf-8') as f:
                    json.dump(trace_item, f, indent=2, ensure_ascii=False)

                files_index.append(
                    {
                        "trace_index": trace_index,
                        "depth": len(trace_address) if isinstance(trace_address, list) else 0,
                        "trace_address": trace_address,
                        "file": filename,
                    }
                )

            try:
                index_path = trace_dir / "__files_index__.json"
                with open(index_path, "w", encoding="utf-8") as f:
                    json.dump(files_index, f, indent=2, ensure_ascii=False)
            except Exception as e:
                print(f"写入 trace 索引失败: {e}")
                    
        print(f"已处理 {len(call_tree)} 个trace文件")
    
    def process_report(self, report_file, output_dir):
        """处理report文件，直接复制到输出目录"""
        if not report_file or not report_file.exists():
            print(f"Report文件不存在: {report_file}")
            return
            
        # 复制report文件
        output_report = output_dir / 'tx_report.txt'
        shutil.copy2(report_file, output_report)
        
        print(f"已复制report文件: {output_report}")
    
    def process_transaction(self, tx_hash):
        """处理单个交易的所有相关文件"""
        print(f"开始处理交易: {tx_hash}")
        
        # 查找相关文件
        files = self.find_transaction_files(tx_hash)
        
        if not any(files.values()):
            print(f"未找到交易 {tx_hash} 的相关文件")
            return
        
        # 创建输出目录
        tx_output_dir = self.output_dir / tx_hash
        tx_output_dir.mkdir(parents=True, exist_ok=True)
        
        # 处理各类文件
        self.process_contracts(files['contracts'], tx_output_dir)
        self.process_trace(files['trace'], tx_output_dir)
        self.process_report(files['report'], tx_output_dir)
        
        print(f"交易 {tx_hash} 处理完成，输出目录: {tx_output_dir}")
        
    def process_all_transactions(self):
        """处理log目录中的所有交易"""
        # 查找所有trace文件来识别交易
        trace_files = list(self.log_dir.glob('*trace*.json'))
        
        processed_hashes = set()
        
        for trace_file in trace_files:
            # 从文件名中提取交易哈希
            filename = trace_file.name
            # 假设文件名格式为 tx_trace_0xhash_timestamp.json
            parts = filename.split('_')
            for part in parts:
                if part.startswith('0x') and len(part) >= 10:
                    tx_hash = part
                    if tx_hash not in processed_hashes:
                        processed_hashes.add(tx_hash)
                        self.process_transaction(tx_hash)
                    break
    
    def list_available_transactions(self):
        """列出可用的交易哈希"""
        trace_files = list(self.log_dir.glob('*trace*.json'))
        
        transactions = []
        for trace_file in trace_files:
            filename = trace_file.name
            parts = filename.split('_')
            for part in parts:
                if part.startswith('0x') and len(part) >= 10:
                    transactions.append(part)
                    break
        
        return transactions

def main():
    """主函数，提供命令行接口"""

    
    processor = TransactionProcessor()
    processor.process_transaction('0xeff836fa1ce60f04b94544fa424764101323f1f7c8ab8265b4bd34e9fa84f8db')
    
if __name__ == "__main__":
    main() 