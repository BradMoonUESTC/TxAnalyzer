# main.py

import sys

import subprocess

# def run_heimdall(command):
#     """Helper function to run heimdall commands."""
#     # result = subprocess.run(['heimdall'] + command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, shell=True)
#     result = subprocess.run(['heimdall'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, shell=True)
#     if result.returncode != 0:
#         print("Error:", result.stderr)
#     return result.stdout

def run_heimdall(command):
    """Helper function to run heimdall commands."""
    heimdall_path = "/Users/xueyue/.bifrost/bin/heimdall"  
    result = subprocess.run([heimdall_path] + command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if result.returncode != 0:
        print("Error:", result.stderr)
    return result.stdout

def config_view():
    """View the current configuration of heimdall-rs."""
    return run_heimdall(['config'])

def config_set(key, value):
    """Set a configuration value."""
    return run_heimdall(['config', key, value])

def disassemble(target):
    """Disassemble EVM bytecode at the specified target."""
    return run_heimdall(['disassemble', target])

def decode(target, openai_api_key=None, explain=True):
    """Decode raw calldata."""
    command = ['decode', target]
    if openai_api_key:
        command += ['-o', openai_api_key]
    if explain:
        command.append('--explain')
    return run_heimdall(command)

def decompile(target,name,include_sol=True, include_yul=False,):
    """Decompile raw contract bytecode."""
    command = ['decompile', target, '-n', name]
    if include_sol:
        command.append('--include-sol')
    if include_yul:
        command.append('--include-yul')
    return run_heimdall(command)


def cfg(target, color_edges=True, format=None):
    """Generate a control flow graph for EVM bytecode."""
    command = ['cfg', target]
    if color_edges:
        command += ['-c']
    if format:
        command += ['-f', format]
    return run_heimdall(command)

def dump(target, api_key, from_block=None, to_block=None, chain='ethereum', no_tui=False):
    """Dump all storage slots and values within an EVM smart contract."""
    command = ['dump', target, '-t', api_key, '--chain', chain]
    if from_block:
        command += ['--from-block', from_block]
    if to_block:
        command += ['--to-block', to_block]
    if no_tui:
        command.append('--no-tui')
    return run_heimdall(command)

def inspect(target, api_key=None):
    """Inspect Ethereum transactions."""
    command = ['inspect', target]
    if api_key:
        command += ['-t', api_key]
    return run_heimdall(command)

