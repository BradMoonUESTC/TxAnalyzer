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
    address public getOwner;
    uint256 public totalSupply;
    mapping(bytes32 => bytes32) storage_map_b;
    bytes32 store_e;
    bytes32 store_h;
    bool public _decimals;
    mapping(bytes32 => bytes32) storage_map_d;
    mapping(bytes32 => bytes32) storage_map_f;
    
    event Transfer(address, address, uint256);
    event Approval(address, address, uint256);
    event OwnershipTransferred(address, address);
    
    /// @custom:selector    0x42966c68
    /// @custom:signature   burn(uint256 arg0) public payable returns (bool)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function burn(uint256 arg0) public payable returns (bool) {
        require(address(msg.sender), "                                  ");
        uint256 var_a = 0x60 + var_a;
        var_b = 0x22;
        var_c = this.code[4293:4327];
        address var_d = address(msg.sender);
        var_e = 0x01;
        require(!(arg0 > storage_map_b[var_d]), "                                  ");
        var_f = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        uint256 var_g = (0x20 + (0x04 + var_a)) - (0x04 + var_a);
        uint256 var_h = var_a.length;
        require(!(bytes1(var_a.length)), "                                  ");
        uint256 var_i = (~((0x0100 ** (0x20 - (bytes1(var_a.length)))) - 0x01)) & (var_j);
        var_d = address(msg.sender);
        var_e = 0x01;
        storage_map_b[var_d] = storage_map_b[var_d] - arg0;
        var_a = 0x40 + var_a;
        var_f = 0x1e;
        var_k = 0x536166654d6174683a207375627472616374696f6e206f766572666c6f770000;
        require(!(arg0 > totalSupply), "                              ");
        var_l = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        uint256 var_m = (0x20 + (0x04 + var_a)) - (0x04 + var_a);
        var_i = var_a.length;
        require(!(bytes1(var_a.length)), "                              ");
        uint256 var_n = (~((0x0100 ** (0x20 - (bytes1(var_a.length)))) - 0x01)) & (var_j);
        var_n = var_o;
        totalSupply = totalSupply - arg0;
        uint256 var_l = arg0;
        emit Transfer(address(msg.sender), 0, arg0);
        var_l = 0x01;
        return 0x01;
        var_b = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        uint256 var_p = (0x20 + (0x04 + var_a)) - (0x04 + var_a);
        var_q = 0x21;
        var_r = this.code[4260:4293];
    }
    
    /// @custom:selector    0xa9059cbb
    /// @custom:signature   transfer(address arg0, uint256 arg1) public payable returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function transfer(address arg0, uint256 arg1) public payable returns (bool) {
        require(address(msg.sender), "                                      ");
        require(address(arg0), "                                      ");
        uint256 var_a = 0x60 + var_a;
        var_b = 0x26;
        var_c = this.code[4150:4188];
        address var_d = address(msg.sender);
        var_e = 0x01;
        require(!(arg1 > storage_map_b[var_d]), "                                      ");
        var_f = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        uint256 var_g = (0x20 + (0x04 + var_a)) - (0x04 + var_a);
        uint256 var_h = var_a.length;
        require(!(bytes1(var_a.length)), "                                      ");
        uint256 var_i = (~((0x0100 ** (0x20 - (bytes1(var_a.length)))) - 0x01)) & (var_j);
        var_d = address(msg.sender);
        var_e = 0x01;
        storage_map_b[var_d] = storage_map_b[var_d] - arg1;
        var_d = address(arg0);
        require(!((arg1 + storage_map_b[var_d]) < storage_map_b[var_d]), "SafeMath: addition overflow");
        var_f = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_g = 0x20;
        var_h = 0x1b;
        var_k = 0x536166654d6174683a206164646974696f6e206f766572666c6f770000000000;
        var_d = address(arg0);
        var_e = 0x01;
        storage_map_b[var_d] = arg1 + storage_map_b[var_d];
        uint256 var_f = arg1;
        emit Transfer(address(msg.sender), address(arg0), arg1);
        var_f = 0x01;
        return 0x01;
        var_b = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        uint256 var_l = (0x20 + (0x04 + var_a)) - (0x04 + var_a);
        var_m = 0x23;
        var_n = this.code[4188:4223];
        var_b = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_l = (0x20 + (0x04 + var_a)) - (0x04 + var_a);
        var_m = 0x25;
        var_n = this.code[3999:4036];
    }
    
    /// @custom:selector    0x39509351
    /// @custom:signature   increaseAllowance(address arg0, uint256 arg1) public payable returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function increaseAllowance(address arg0, uint256 arg1) public payable returns (bool) {
        address var_a = address(msg.sender);
        var_b = 0x02;
        var_a = address(arg0);
        address var_b = keccak256(var_a);
        require(!((arg1 + storage_map_d[var_a]) < storage_map_d[var_a]), "SafeMath: addition overflow");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x1b;
        var_f = 0x536166654d6174683a206164646974696f6e206f766572666c6f770000000000;
        require(address(msg.sender), "BEP20: approve to the zero address");
        require(address(arg0), "BEP20: approve to the zero address");
        var_a = address(msg.sender);
        var_b = 0x02;
        var_a = address(arg0);
        var_b = keccak256(var_a);
        storage_map_d[var_a] = arg1 + storage_map_d[var_a];
        uint256 var_c = arg1 + storage_map_d[var_a];
        emit Approval(address(msg.sender), address(arg0), arg1 + storage_map_d[var_a]);
        var_c = 0x01;
        return 0x01;
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        uint256 var_d = (0x20 + (0x04 + var_g)) - (0x04 + var_g);
        var_e = 0x22;
        var_h = this.code[4327:4361];
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = (0x20 + (0x04 + var_g)) - (0x04 + var_g);
        var_e = 0x24;
        var_h = this.code[4036:4072];
    }
    
    /// @custom:selector    0x06fdde03
    /// @custom:signature   name() public view returns (string memory)
    function name() public view returns (string memory) {
        bytes1 var_a = 0x20 + (var_a + (0x20 * (((store_e & (((!bytes1(store_e)) * 0x0100) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) / 0x02) + 0x1f) / 0x20)));
        bytes1 var_b = (store_e & (((!bytes1(store_e)) * 0x0100) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)) / 0x02;
        if (!(store_e & (((!store_e) * 0x0100) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)) / 0x02) {
            if (0x1f < (store_e & (((!store_e) * 0x0100) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) / 0x02)) {
                var_c = 0x06;
                var_d = storage_map_f[var_c];
                if ((var_a + 0x20) + (store_e & (((!store_e) * 0x0100) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) / 0x02) > (0x20 + (var_a + 0x20))) {
                    var_d = 0x20;
                    bytes1 var_e = var_a.length;
                    if (!var_a.length) {
                        bytes1 var_f = (~((0x0100 ** (0x20 - (bytes1(var_a.length)))) - 0x01)) & (var_g);
                        return abi.encodePacked(0x20, var_a.length, (~((0x0100 ** (0x20 - (bytes1(var_a.length)))) - 0x01)) & (var_g));
                        return abi.encodePacked(0x20, var_a.length);
                    }
                }
            }
        }
    }
    
    /// @custom:selector    0xd28d8852
    /// @custom:signature   _name() public view returns (bytes memory)
    function _name() public view returns (bytes memory) {
        bytes1 var_a = 0x20 + (var_a + (0x20 * (((store_e & (0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff + (0x0100 * (!bytes1(store_e)))) / 0x02) + 0x1f) / 0x20)));
        bytes1 var_b = (store_e & (0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff + (0x0100 * (!bytes1(store_e))))) / 0x02;
        if (!(store_e & (0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff + (0x0100 * (!store_e)))) / 0x02) {
            if (0x1f < (store_e & (0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff + (0x0100 * (!store_e))) / 0x02)) {
                var_c = 0x06;
                var_d = storage_map_f[var_c];
                if ((var_a + 0x20) + (store_e & (0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff + (0x0100 * (!store_e))) / 0x02) > (0x20 + (var_a + 0x20))) {
                    var_d = 0x20;
                    bytes1 var_e = var_a.length;
                    if (!var_a.length) {
                        bytes1 var_f = (~((0x0100 ** (0x20 - (bytes1(var_a.length)))) - 0x01)) & (var_g);
                        return abi.encodePacked(0x20, var_a.length, (~((0x0100 ** (0x20 - (bytes1(var_a.length)))) - 0x01)) & (var_g));
                        return abi.encodePacked(0x20, var_a.length);
                    }
                }
            }
        }
    }
    
    /// @custom:selector    0xa457c2d7
    /// @custom:signature   decreaseAllowance(address arg0, uint256 arg1) public payable returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function decreaseAllowance(address arg0, uint256 arg1) public payable returns (bool) {
        uint256 var_a = 0x60 + var_a;
        var_b = 0x25;
        var_c = this.code[4223:4260];
        address var_d = address(msg.sender);
        var_e = 0x02;
        var_d = address(arg0);
        address var_e = keccak256(var_d);
        require(!(arg1 > storage_map_b[var_d]), "                                     ");
        var_f = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        uint256 var_g = (0x20 + (0x04 + var_a)) - (0x04 + var_a);
        uint256 var_h = var_a.length;
        require(!(bytes1(var_a.length)), "                                     ");
        uint256 var_i = (~((0x0100 ** (0x20 - (bytes1(var_a.length)))) - 0x01)) & (var_j);
        require(address(msg.sender), "BEP20: approve to the zero address");
        require(address(arg0), "BEP20: approve to the zero address");
        var_d = address(msg.sender);
        var_e = 0x02;
        var_d = address(arg0);
        var_e = keccak256(var_d);
        storage_map_b[var_d] = storage_map_b[var_d] - arg1;
        address var_f = storage_map_b[var_d] - arg1;
        emit Approval(address(msg.sender), address(arg0), storage_map_b[var_d] - arg1);
        var_f = 0x01;
        return 0x01;
        var_f = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_g = (0x20 + (0x04 + var_a)) - (0x04 + var_a);
        var_h = 0x22;
        var_k = this.code[4327:4361];
        var_f = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_g = (0x20 + (0x04 + var_a)) - (0x04 + var_a);
        var_h = 0x24;
        var_k = this.code[4036:4072];
    }
    
    /// @custom:selector    0x23b872dd
    /// @custom:signature   transferFrom(address arg0, address arg1, uint256 arg2) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function transferFrom(address arg0, address arg1, uint256 arg2) public payable {
        require(address(arg0), "                                      ");
        require(address(arg1), "                                      ");
        uint256 var_a = 0x60 + var_a;
        var_b = 0x26;
        var_c = this.code[4150:4188];
        address var_d = address(arg0);
        var_e = 0x01;
        require(!(arg2 > storage_map_b[var_d]), "                                      ");
        var_f = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        uint256 var_g = (0x20 + (0x04 + var_a)) - (0x04 + var_a);
        uint256 var_h = var_a.length;
        require(!(bytes1(var_a.length)), "                                      ");
        uint256 var_i = (~((0x0100 ** (0x20 - (bytes1(var_a.length)))) - 0x01)) & (var_j);
        var_d = address(arg0);
        var_e = 0x01;
        storage_map_b[var_d] = storage_map_b[var_d] - arg2;
        var_d = address(arg1);
        require(!((arg2 + storage_map_b[var_d]) < storage_map_b[var_d]), "SafeMath: addition overflow");
        var_f = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_g = 0x20;
        var_h = 0x1b;
        var_k = 0x536166654d6174683a206164646974696f6e206f766572666c6f770000000000;
        var_b = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        uint256 var_l = (0x20 + (0x04 + var_a)) - (0x04 + var_a);
        var_m = 0x23;
        var_n = this.code[4188:4223];
        var_b = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_l = (0x20 + (0x04 + var_a)) - (0x04 + var_a);
        var_m = 0x25;
        var_n = this.code[3999:4036];
    }
    
    /// @custom:selector    0xa0712d68
    /// @custom:signature   mint(uint256 arg0) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function mint(uint256 arg0) public view {
        require(address(msg.sender) == (address(getOwner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        require(address(msg.sender), "SafeMath: addition overflow");
        require(!((arg0 + totalSupply) < totalSupply), "SafeMath: addition overflow");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x1b;
        var_d = 0x536166654d6174683a206164646974696f6e206f766572666c6f770000000000;
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x1f;
        var_d = 0x42455032303a206d696e7420746f20746865207a65726f206164647265737300;
    }
    
    /// @custom:selector    0x70a08231
    /// @custom:signature   balanceOf(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function balanceOf(address arg0) public view returns (uint256) {
        address var_a = address(arg0);
        var_b = 0x01;
        address var_c = storage_map_d[var_a];
        return storage_map_d[var_a];
    }
    
    /// @custom:selector    0x95d89b41
    /// @custom:signature   symbol() public view returns (string memory)
    function symbol() public view returns (string memory) {
        bytes1 var_a = 0x20 + (var_a + (0x20 * (((store_h & (((!bytes1(store_h)) * 0x0100) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) / 0x02) + 0x1f) / 0x20)));
        bytes1 var_b = (store_h & (((!bytes1(store_h)) * 0x0100) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)) / 0x02;
        if (!(store_h & (((!store_h) * 0x0100) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)) / 0x02) {
            if (0x1f < (store_h & (((!store_h) * 0x0100) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) / 0x02)) {
                var_c = 0x05;
                var_d = storage_map_f[var_c];
                if ((var_a + 0x20) + (store_h & (((!store_h) * 0x0100) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) / 0x02) > (0x20 + (var_a + 0x20))) {
                    var_d = 0x20;
                    bytes1 var_e = var_a.length;
                    if (!var_a.length) {
                        bytes1 var_f = (~((0x0100 ** (0x20 - (bytes1(var_a.length)))) - 0x01)) & (var_g);
                        return abi.encodePacked(0x20, var_a.length, (~((0x0100 ** (0x20 - (bytes1(var_a.length)))) - 0x01)) & (var_g));
                        return abi.encodePacked(0x20, var_a.length);
                    }
                }
            }
        }
    }
    
    /// @custom:selector    0xdd62ed3e
    /// @custom:signature   allowance(address arg0, address arg1) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function allowance(address arg0, address arg1) public view returns (uint256) {
        address var_a = address(arg0);
        var_b = 0x02;
        var_a = address(arg1);
        address var_b = keccak256(var_a);
        address var_c = storage_map_d[var_a];
        return storage_map_d[var_a];
    }
    
    /// @custom:selector    0x715018a6
    /// @custom:signature   renounceOwnership() public payable
    function renounceOwnership() public payable {
        require(address(msg.sender) == (address(getOwner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        emit OwnershipTransferred(address(getOwner), 0);
        getOwner = uint96(getOwner);
    }
    
    /// @custom:selector    0x095ea7b3
    /// @custom:signature   approve(address arg0, uint256 arg1) public payable returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function approve(address arg0, uint256 arg1) public payable returns (bool) {
        require(address(msg.sender), "BEP20: approve to the zero address");
        require(address(arg0), "BEP20: approve to the zero address");
        address var_a = address(msg.sender);
        var_b = 0x02;
        var_a = address(arg0);
        address var_b = keccak256(var_a);
        storage_map_d[var_a] = arg1;
        uint256 var_c = arg1;
        emit Approval(address(msg.sender), address(arg0), arg1);
        var_c = 0x01;
        return 0x01;
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        uint256 var_d = (0x20 + (0x04 + var_e)) - (0x04 + var_e);
        var_f = 0x22;
        var_g = this.code[4327:4361];
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = (0x20 + (0x04 + var_e)) - (0x04 + var_e);
        var_f = 0x24;
        var_g = this.code[4036:4072];
    }
    
    /// @custom:selector    0xb09f1266
    /// @custom:signature   _symbol() public view returns (bytes memory)
    function _symbol() public view returns (bytes memory) {
        bytes1 var_a = 0x20 + (var_a + (0x20 * (((store_h & (0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff + (0x0100 * (!bytes1(store_h)))) / 0x02) + 0x1f) / 0x20)));
        bytes1 var_b = (store_h & (0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff + (0x0100 * (!bytes1(store_h))))) / 0x02;
        if (!(store_h & (0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff + (0x0100 * (!store_h)))) / 0x02) {
            if (0x1f < (store_h & (0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff + (0x0100 * (!store_h))) / 0x02)) {
                var_c = 0x05;
                var_d = storage_map_f[var_c];
                if ((var_a + 0x20) + (store_h & (0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff + (0x0100 * (!store_h))) / 0x02) > (0x20 + (var_a + 0x20))) {
                    var_d = 0x20;
                    bytes1 var_e = var_a.length;
                    if (!var_a.length) {
                        bytes1 var_f = (~((0x0100 ** (0x20 - (bytes1(var_a.length)))) - 0x01)) & (var_g);
                        return abi.encodePacked(0x20, var_a.length, (~((0x0100 ** (0x20 - (bytes1(var_a.length)))) - 0x01)) & (var_g));
                        return abi.encodePacked(0x20, var_a.length);
                    }
                }
            }
        }
    }
    
    /// @custom:selector    0xf2fde38b
    /// @custom:signature   transferOwnership(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function transferOwnership(address arg0) public payable {
        require(address(msg.sender) == (address(getOwner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        require(address(arg0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(address(getOwner), address(arg0));
        getOwner = (address(arg0)) | (uint96(getOwner));
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        uint256 var_b = (0x20 + (0x04 + var_e)) - (0x04 + var_e);
        var_c = 0x26;
        var_f = this.code[4072:4110];
    }
}