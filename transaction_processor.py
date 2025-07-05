#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import json
import shutil
from pathlib import Path

class TransactionProcessor:
    def __init__(self, log_dir='log'):
        self.log_dir = Path(log_dir)
        self.output_dir = Path('transactions')
        
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
                
        print(f"已处理 {len(contracts_data)} 个合约文件")
    
    def process_trace(self, trace_file, output_dir):
        """处理trace文件，按trace_index和trace_address拆分保存"""
        if not trace_file or not trace_file.exists():
            print(f"Trace文件不存在: {trace_file}")
            return
            
        # 创建trace文件夹
        trace_dir = output_dir / 'trace'
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
            
            for trace_item in call_tree:
                trace_index = trace_item.get('trace_index', 0)
                trace_address = trace_item.get('trace_address', [])
                
                # 构造文件名: trace_index_trace_address
                if trace_address:
                    # 将trace_address数组用下划线连接
                    address_str = '_'.join(str(addr) for addr in trace_address)
                    filename = f"{trace_index}_{address_str}.json"
                else:
                    filename = f"{trace_index}.json"
                    
                trace_file_path = trace_dir / filename
                
                # 保存单个trace
                with open(trace_file_path, 'w', encoding='utf-8') as f:
                    json.dump(trace_item, f, indent=2, ensure_ascii=False)
                    
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
    import argparse
    
    parser = argparse.ArgumentParser(description='处理区块链交易数据')
    parser.add_argument('--tx-hash', type=str, help='要处理的交易哈希')
    parser.add_argument('--all', action='store_true', help='处理所有交易')
    parser.add_argument('--list', action='store_true', help='列出可用的交易')
    parser.add_argument('--log-dir', type=str, default='log', help='日志文件目录')
    
    args = parser.parse_args()
    
    processor = TransactionProcessor(args.log_dir)
    
    if args.list:
        transactions = processor.list_available_transactions()
        print("可用的交易哈希:")
        for tx in transactions:
            print(f"  {tx}")
    elif args.all:
        processor.process_all_transactions()
    elif args.tx_hash:
        processor.process_transaction(args.tx_hash)
    else:
        print("请指定 --tx-hash, --all 或 --list 参数")
        print("使用 --help 查看帮助")

if __name__ == "__main__":
    main() 