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
        Generate a safe trace filename for writing to disk.

        Goals:
        - Preserve trace_index + trace_address info (order/depth) as much as possible
        - Avoid overly long filenames on macOS / APFS (typically <=255 chars)
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

            # If too long, degrade: keep prefix + hash + depth info
            if len(name) > 200:
                prefix_parts = parts[:12]
                prefix = "_".join(prefix_parts)
                h = hashlib.sha1(full.encode("utf-8")).hexdigest()[:12]
                name = f"{idx}_d{depth}_{prefix}__h{h}__n{depth}"

        filename = f"{name}.json"

        # Final fallback: if still too long, use only hash (trace_index preserved for sorting/dedup)
        if len(filename) > 240:
            h = hashlib.sha1(filename.encode("utf-8")).hexdigest()[:16]
            filename = f"{idx}_d{depth}__h{h}.json"

        return filename
        
    def find_transaction_files(self, tx_hash):
        """Find all related files for a specific transaction hash"""
        # Use first 10 chars of tx hash for filename matching
        tx_short = tx_hash[:10]
        
        files = {
            'contracts': None,
            'trace': None,
            'report': None
        }
        
        # Find matching files
        for file_path in self.log_dir.glob(f'*{tx_short}*'):
            if 'contracts' in file_path.name:
                files['contracts'] = file_path
            elif 'trace' in file_path.name and file_path.suffix == '.json':
                files['trace'] = file_path
            elif 'report' in file_path.name:
                files['report'] = file_path
                
        return files
    
    def process_contracts(self, contracts_file, output_dir):
        """Process contracts file, saving each contract address separately"""
        if not contracts_file or not contracts_file.exists():
            print(f"Contracts file not found: {contracts_file}")
            return
            
        # Create contracts directory
        contracts_dir = output_dir / 'contracts'
        contracts_dir.mkdir(parents=True, exist_ok=True)
        
        # Read contracts file
        try:
            with open(contracts_file, 'r', encoding='utf-8') as f:
                contracts_data = json.load(f)
        except json.JSONDecodeError as e:
            print(f"Failed to parse contracts file: {e}")
            return
        
        # Create a separate file for each contract
        for contract_address, contract_info in contracts_data.items():
            # Clean address, strip 0x prefix
            clean_address = contract_address.replace('0x', '')
            contract_file = contracts_dir / f"{clean_address}.json"
            
            # Save contract info
            with open(contract_file, 'w', encoding='utf-8') as f:
                json.dump(contract_info, f, indent=2, ensure_ascii=False)

            # If source was exported to .sol files in previous step, copy to transactions/<tx>/
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
                print(f"Failed to copy source files for {contract_address}: {e}")

            # Copy decompilation artifacts (if present), ensuring unverified contracts have full materials in tx dir
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
                print(f"Failed to copy decompilation artifacts for {contract_address}: {e}")
                
        print(f"Processed {len(contracts_data)} contract files")
    
    def process_trace(self, trace_file, output_dir):
        """Process trace file, split and save by trace_index and trace_address"""
        if not trace_file or not trace_file.exists():
            print(f"Trace file not found: {trace_file}")
            return
            
        # Create trace directory
        trace_dir = output_dir / 'trace'
        # Rebuild trace/ dir each time to avoid leftover partial files from previous failures
        if trace_dir.exists():
            shutil.rmtree(trace_dir)
        trace_dir.mkdir(parents=True, exist_ok=True)
        
        # Read trace file
        try:
            with open(trace_file, 'r', encoding='utf-8') as f:
                trace_data = json.load(f)
        except json.JSONDecodeError as e:
            print(f"Failed to parse trace file: {e}")
            return
        
        # Save transaction info
        if 'transaction_info' in trace_data:
            transaction_info_file = trace_dir / 'transaction_info.json'
            with open(transaction_info_file, 'w', encoding='utf-8') as f:
                json.dump(trace_data['transaction_info'], f, indent=2, ensure_ascii=False)
        
        # Process each trace in call_tree
        if 'call_tree' in trace_data:
            call_tree = trace_data['call_tree']

            # Write an index for finding files by trace_address (also avoids overly long filenames)
            files_index = []
            
            for trace_item in call_tree:
                trace_index = trace_item.get('trace_index', 0)
                trace_address = trace_item.get('trace_address', [])
                
                filename = self._safe_trace_filename(trace_index, trace_address)
                    
                trace_file_path = trace_dir / filename
                
                # Save individual trace
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
                print(f"Failed to write trace index: {e}")
                    
        print(f"Processed {len(call_tree)} trace files")
    
    def process_report(self, report_file, output_dir):
        """Process report file by copying it to the output directory"""
        if not report_file or not report_file.exists():
            print(f"Report file not found: {report_file}")
            return
            
        # Copy report file
        output_report = output_dir / 'tx_report.txt'
        shutil.copy2(report_file, output_report)
        
        print(f"Copied report file: {output_report}")
    
    def process_transaction(self, tx_hash):
        """Process all related files for a single transaction"""
        print(f"Processing transaction: {tx_hash}")
        
        # Find related files
        files = self.find_transaction_files(tx_hash)
        
        if not any(files.values()):
            print(f"No related files found for transaction {tx_hash}")
            return
        
        # Create output directory
        tx_output_dir = self.output_dir / tx_hash
        tx_output_dir.mkdir(parents=True, exist_ok=True)
        
        # Process each type of file
        self.process_contracts(files['contracts'], tx_output_dir)
        self.process_trace(files['trace'], tx_output_dir)
        self.process_report(files['report'], tx_output_dir)
        
        print(f"Transaction {tx_hash} processed, output directory: {tx_output_dir}")
        
    def process_all_transactions(self):
        """Process all transactions in the log directory"""
        # Find all trace files to identify transactions
        trace_files = list(self.log_dir.glob('*trace*.json'))
        
        processed_hashes = set()
        
        for trace_file in trace_files:
            # Extract tx hash from filename
            filename = trace_file.name
            # Assumes filename format: tx_trace_0xhash_timestamp.json
            parts = filename.split('_')
            for part in parts:
                if part.startswith('0x') and len(part) >= 10:
                    tx_hash = part
                    if tx_hash not in processed_hashes:
                        processed_hashes.add(tx_hash)
                        self.process_transaction(tx_hash)
                    break
    
    def list_available_transactions(self):
        """List available transaction hashes"""
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
    """Main function, provides CLI interface"""

    
    processor = TransactionProcessor()
    processor.process_transaction('0xeff836fa1ce60f04b94544fa424764101323f1f7c8ab8265b4bd34e9fa84f8db')
    
if __name__ == "__main__":
    main() 