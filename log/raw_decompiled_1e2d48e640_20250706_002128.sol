// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title            Decompiled Contract
/// @author           Jonathan Becker <jonathan@jbecker.dev>
/// @custom:version   heimdall-rs v0.9.0
///
/// @notice           This contract was decompiled using the heimdall-rs decompiler.
///                     It was generated directly by tracing the EVM opcodes from this contract.
///                     As a result, it may not compile or even be valid solidity code.
///                     Despite this, it should be obvious what each function does. Overall
///                     logic should have been preserved throughout decompiling.
///
/// @custom:github    You can find the open-source decompiler here:
///                       https://heimdall.rs

contract DecompiledContract {
    bytes public constant transfer = ;
    
    
    /// @custom:selector    0xc6398bbc
    /// @custom:signature   Unresolved_c6398bbc(address arg0, uint256 arg1) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_c6398bbc(address arg0, uint256 arg1) public {
        require(arg0 == (address(arg0)));
        require(!arg1 > 0xffffffffffffffff);
        require(!(arg1) > 0xffffffffffffffff);
        require(address(msg.sender) == 0);
        var_a = msg.data[36:36];
        uint256 var_b = 0;
        (bool success, bytes memory ret0) = address(arg0).Unresolved_(var_c); // delegatecall
        require(ret0.length == 0);
    }
    
    /// @custom:selector    0xddc4dab8
    /// @custom:signature   Unresolved_ddc4dab8(address arg0, uint256 arg1, uint256 arg2) public
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function Unresolved_ddc4dab8(address arg0, uint256 arg1, uint256 arg2) public {
        require(arg0 == (address(arg0)));
        require(arg1 == arg1);
        require(!arg2 > 0xffffffffffffffff);
        require(!(arg2) > 0xffffffffffffffff);
        require(address(msg.sender) == 0);
        var_a = msg.data[36:36];
        uint256 var_b = 0;
        (bool success, bytes memory ret0) = address(arg0).transfer(arg1);
        require(ret0.length == 0);
    }
}