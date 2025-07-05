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
    uint256 public constant decimals = 18;
    uint256 public constant WETH = 1097077688018008265106216665536940668749033598146;
    uint256 public constant POSITION_MANAGER = 1115489085710619414828654646022418608911583149704;
    
    mapping(bytes32 => bytes32) storage_map_e;
    bytes32 store_a;
    bool public unresolved_2f4237c0;
    mapping(bytes32 => bytes32) storage_map_b;
    bytes32 store_h;
    address public creator;
    uint256 public totalSupply;
    address public platform;
    
    event Approval(address, address, uint256);
    error ERC20InvalidReceiver(address);
    event Transfer(address, address, uint256);
    
    /// @custom:selector    0x06fdde03
    /// @custom:signature   name() public view returns (string memory)
    function name() public view returns (string memory) {
        if (store_a) {
            if (store_a - ((store_a >> 0x01) < 0x20)) {
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                var_b = 0x22;
                uint256 var_c = var_c + (0x20 + (((0x1f + (store_a >> 0x01)) / 0x20) * 0x20));
                bytes32 var_d = store_a >> 0x01;
                if (store_a) {
                    if (store_a - ((store_a >> 0x01) < 0x20)) {
                        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                        var_b = 0x22;
                        if (!store_a >> 0x01) {
                            if (0x1f < (store_a >> 0x01)) {
                                var_a = 0x03;
                                var_e = storage_map_b[var_a];
                                if ((0x20 + var_c) + (store_a >> 0x01) > (0x20 + (0x20 + var_c))) {
                                    var_e = 0x20;
                                    uint256 var_f = var_c.length;
                                    uint256 var_g = 0;
                                    return abi.encodePacked(0x20, var_c.length);
                                    uint256 var_e = (store_a / 0x0100) * 0x0100;
                                    var_e = 0x20;
                                    var_f = var_c.length;
                                    var_g = 0;
                                    return abi.encodePacked(0x20, var_c.length);
                                    var_e = 0x20;
                                    var_f = var_c.length;
                                    var_g = 0;
                                    return abi.encodePacked(0x20, var_c.length);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// @custom:selector    0x42966c68
    /// @custom:signature   burn(uint256 arg0) public payable
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function burn(uint256 arg0) public payable {
        require(address(msg.sender), "No buys allowed during launch block!");
        require(!(block.number > unresolved_2f4237c0), "No buys allowed during launch block!");
        require(!(block.number > unresolved_2f4237c0), "No buys allowed during launch block!");
        require(!(block.number == unresolved_2f4237c0), "No buys allowed during launch block!");
        require(!(address(msg.sender)), "No buys allowed during launch block!");
        require(!(!(address(platform)) == 0), "No buys allowed during launch block!");
        require(!(!(address(platform)) == (address(msg.sender))), "No buys allowed during launch block!");
        require(!(address(platform) == (address(msg.sender))), "No buys allowed during launch block!");
        require(!(!(address(platform)) == (address(msg.sender))), "No buys allowed during launch block!");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x24;
        var_d = 0x4e6f206275797320616c6c6f77656420647572696e67206c61756e636820626c;
        var_e = 0x6f636b2100000000000000000000000000000000000000000000000000000000;
        require(address(msg.sender), CustomError_e450d38c());
        address var_f = address(msg.sender);
        uint256 var_g = 0;
        require(!(storage_map_e[var_f] < arg0), CustomError_e450d38c());
        var_a = 0xe450d38c00000000000000000000000000000000000000000000000000000000;
        address var_b = address(msg.sender);
        address var_c = storage_map_e[var_f];
        uint256 var_d = arg0;
        var_f = address(msg.sender);
        var_g = 0;
        storage_map_e[var_f] = storage_map_e[var_f] - arg0;
        require(0);
        var_f = 0;
        var_g = 0;
        storage_map_e[var_f] = var_d + storage_map_e[var_f];
        uint256 var_a = arg0;
        emit Transfer(address(msg.sender), 0, arg0);
        totalSupply = totalSupply - arg0;
        var_a = arg0;
        emit Transfer(address(msg.sender), 0, arg0);
        require(!totalSupply > (arg0 + totalSupply));
        var_f = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_h = 0x11;
        var_a = 0xc45a015500000000000000000000000000000000000000000000000000000000;
        (bool success, bytes memory ret0) = address(0xc36442b4a4522e871399cd717abdd847ab11fe88).factory(var_b); // staticcall
        uint256 var_i = var_i + (uint248(ret0.length + 0x1f));
        require(!((var_i + ret0.length) - var_i) < 0x20);
        require(var_i.length == (address(var_i.length)));
        var_j = 0x1698ee8200000000000000000000000000000000000000000000000000000000;
        var_c = address(this);
        var_d = 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2;
        var_e = 0x2710;
        (bool success, bytes memory ret0) = address(var_i.length).Unresolved_1698ee82(var_c); // staticcall
        var_i = var_i + (uint248(ret0.length + 0x1f));
        if (!((var_i + ret0.length) - var_i) < 0x20) {
            if (var_i.length == (address(var_i.length))) {
                if (!(address(msg.sender)) == (address(var_i.length))) {
                    if (!(address(msg.sender)) == (address(var_i.length))) {
                        require(!((var_i + ret0.length) - var_i) < 0x20);
                        require(var_i.length == (address(var_i.length)));
                        require(!(address(msg.sender)) == (address(var_i.length)));
                        require(!(address(msg.sender)) == (address(var_i.length)));
                        require(!(address(msg.sender)) == (address(var_i.length)));
                    }
                    require(address(creator) == 0);
                }
                require(0 == (address(var_i.length)));
            }
        }
        var_a = 0x96c6fd1e00000000000000000000000000000000000000000000000000000000;
        var_b = 0;
    }
    
    /// @custom:selector    0xa9059cbb
    /// @custom:signature   transfer(address arg0, uint256 arg1) public payable returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function transfer(address arg0, uint256 arg1) public payable returns (bool) {
        require(arg0 == (address(arg0)));
        require(address(msg.sender), "No buys allowed during launch block!");
        require(address(arg0), "No buys allowed during launch block!");
        require(!(block.number > unresolved_2f4237c0), "No buys allowed during launch block!");
        require(!(block.number > unresolved_2f4237c0), "No buys allowed during launch block!");
        require(!(block.number == unresolved_2f4237c0), "No buys allowed during launch block!");
        require(!(address(msg.sender)), "No buys allowed during launch block!");
        require(!(!(address(platform)) == (address(arg0))), "No buys allowed during launch block!");
        require(!(!(address(platform)) == (address(msg.sender))), "No buys allowed during launch block!");
        require(!(address(platform) == (address(msg.sender))), "No buys allowed during launch block!");
        require(!(!(address(platform)) == (address(msg.sender))), "No buys allowed during launch block!");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x24;
        var_d = 0x4e6f206275797320616c6c6f77656420647572696e67206c61756e636820626c;
        var_e = 0x6f636b2100000000000000000000000000000000000000000000000000000000;
        require(address(msg.sender), CustomError_e450d38c());
        address var_f = address(msg.sender);
        uint256 var_g = 0;
        require(!(storage_map_e[var_f] < arg1), CustomError_e450d38c());
        var_a = 0xe450d38c00000000000000000000000000000000000000000000000000000000;
        address var_b = address(msg.sender);
        address var_c = storage_map_e[var_f];
        uint256 var_d = arg1;
        var_f = address(msg.sender);
        var_g = 0;
        storage_map_e[var_f] = storage_map_e[var_f] - arg1;
        require(address(arg0));
        var_f = address(arg0);
        var_g = 0;
        storage_map_e[var_f] = var_d + storage_map_e[var_f];
        uint256 var_a = arg1;
        emit Transfer(address(msg.sender), address(arg0), arg1);
        var_a = 0x01;
        return 0x01;
        totalSupply = totalSupply - arg1;
        var_a = arg1;
        emit Transfer(address(msg.sender), address(arg0), arg1);
        var_a = 0x01;
        return 0x01;
        require(!totalSupply > (arg1 + totalSupply));
        var_f = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_h = 0x11;
        var_a = 0xc45a015500000000000000000000000000000000000000000000000000000000;
        (bool success, bytes memory ret0) = address(0xc36442b4a4522e871399cd717abdd847ab11fe88).factory(var_b); // staticcall
        uint256 var_i = var_i + (uint248(ret0.length + 0x1f));
        require(!((var_i + ret0.length) - var_i) < 0x20);
        require(var_i.length == (address(var_i.length)));
        var_j = 0x1698ee8200000000000000000000000000000000000000000000000000000000;
        var_c = address(this);
        var_d = 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2;
        var_e = 0x2710;
        (bool success, bytes memory ret0) = address(var_i.length).Unresolved_1698ee82(var_c); // staticcall
        var_i = var_i + (uint248(ret0.length + 0x1f));
        if (!((var_i + ret0.length) - var_i) < 0x20) {
            if (var_i.length == (address(var_i.length))) {
                if (!(address(msg.sender)) == (address(var_i.length))) {
                    if (!(address(msg.sender)) == (address(var_i.length))) {
                        require(!((var_i + ret0.length) - var_i) < 0x20);
                        require(var_i.length == (address(var_i.length)));
                        require(!(address(msg.sender)) == (address(var_i.length)));
                        require(!(address(msg.sender)) == (address(var_i.length)));
                        require(!(address(msg.sender)) == (address(var_i.length)));
                    }
                    require(address(creator) == (address(arg0)));
                }
                require(address(arg0) == (address(var_i.length)));
            }
        }
        var_a = 0xec442f0500000000000000000000000000000000000000000000000000000000;
        var_b = 0;
        var_a = 0x96c6fd1e00000000000000000000000000000000000000000000000000000000;
        var_b = 0;
    }
    
    /// @custom:selector    0x23b872dd
    /// @custom:signature   Unresolved_23b872dd(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_23b872dd(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0x79cc6790
    /// @custom:signature   burnFrom(address arg0, uint256 arg1) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function burnFrom(address arg0, uint256 arg1) public payable {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        var_b = 0x01;
        var_a = address(msg.sender);
        address var_b = keccak256(var_a);
        require(!(storage_map_b[var_a] < 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff), "No buys allowed during launch block!");
        require(address(arg0), "No buys allowed during launch block!");
        require(!(block.number > unresolved_2f4237c0), "No buys allowed during launch block!");
        require(!(block.number > unresolved_2f4237c0), "No buys allowed during launch block!");
        require(!(block.number == unresolved_2f4237c0), "No buys allowed during launch block!");
        require(!(address(arg0)), "No buys allowed during launch block!");
        require(!(!(address(platform)) == 0), "No buys allowed during launch block!");
        require(!(!(address(platform)) == (address(arg0))), "No buys allowed during launch block!");
        require(!(address(platform) == (address(arg0))), "No buys allowed during launch block!");
        require(!(!(address(platform)) == (address(arg0))), "No buys allowed during launch block!");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x24;
        var_f = 0x4e6f206275797320616c6c6f77656420647572696e67206c61756e636820626c;
        var_g = 0x6f636b2100000000000000000000000000000000000000000000000000000000;
        require(address(arg0), CustomError_e450d38c());
        var_a = address(arg0);
        var_b = 0;
        require(!(storage_map_b[var_a] < arg1), CustomError_e450d38c());
        var_c = 0xe450d38c00000000000000000000000000000000000000000000000000000000;
        address var_d = address(arg0);
        address var_e = storage_map_b[var_a];
        uint256 var_f = arg1;
        var_a = address(arg0);
        var_b = 0;
        storage_map_b[var_a] = storage_map_b[var_a] - arg1;
        require(0);
        var_a = 0;
        var_b = 0;
        storage_map_b[var_a] = var_f + storage_map_b[var_a];
        uint256 var_c = arg1;
        emit Transfer(address(arg0), 0, arg1);
        totalSupply = totalSupply - arg1;
        var_c = arg1;
        emit Transfer(address(arg0), 0, arg1);
        require(!totalSupply > (arg1 + totalSupply));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_h = 0x11;
        var_c = 0xc45a015500000000000000000000000000000000000000000000000000000000;
        (bool success, bytes memory ret0) = address(0xc36442b4a4522e871399cd717abdd847ab11fe88).factory(var_d); // staticcall
        uint256 var_i = var_i + (uint248(ret0.length + 0x1f));
        require(!((var_i + ret0.length) - var_i) < 0x20);
        require(var_i.length == (address(var_i.length)));
        var_j = 0x1698ee8200000000000000000000000000000000000000000000000000000000;
        var_e = address(this);
        var_f = 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2;
        var_g = 0x2710;
        (bool success, bytes memory ret0) = address(var_i.length).Unresolved_1698ee82(var_e); // staticcall
        var_i = var_i + (uint248(ret0.length + 0x1f));
        if (!((var_i + ret0.length) - var_i) < 0x20) {
            if (var_i.length == (address(var_i.length))) {
                if (!(address(arg0)) == (address(var_i.length))) {
                    if (!(address(arg0)) == (address(var_i.length))) {
                        require(!((var_i + ret0.length) - var_i) < 0x20);
                        require(var_i.length == (address(var_i.length)));
                        require(!(address(arg0)) == (address(var_i.length)));
                        require(!(address(arg0)) == (address(var_i.length)));
                        require(!(address(arg0)) == (address(var_i.length)));
                    }
                    require(address(creator) == 0);
                }
                require(0 == (address(var_i.length)));
            }
        }
        var_c = 0x96c6fd1e00000000000000000000000000000000000000000000000000000000;
        var_d = 0;
        require(!(storage_map_b[var_a] < arg1), CustomError_fb8f41b2());
        var_c = 0xfb8f41b200000000000000000000000000000000000000000000000000000000;
        var_d = address(msg.sender);
        var_e = storage_map_b[var_a];
        var_f = arg1;
        if (address(arg0)) {
            require(address(arg0), CustomError_94280d62());
            var_a = address(arg0);
            var_b = 0x01;
            var_a = address(msg.sender);
            var_b = keccak256(var_a);
            storage_map_b[var_a] = storage_map_b[var_a] - arg1;
            require(address(msg.sender), CustomError_94280d62());
        }
        var_c = 0x94280d6200000000000000000000000000000000000000000000000000000000;
        var_d = 0;
        var_c = 0xe602df0500000000000000000000000000000000000000000000000000000000;
        var_d = 0;
    }
    
    /// @custom:selector    0xcbbc94cf
    /// @custom:signature   getTokenPair() public payable returns (bytes memory)
    function getTokenPair() public payable returns (bytes memory) {
        var_a = 0xc45a015500000000000000000000000000000000000000000000000000000000;
        (bool success, bytes memory ret0) = address(0xc36442b4a4522e871399cd717abdd847ab11fe88).factory(var_b); // staticcall
        uint256 var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!((var_c + ret0.length) - var_c) < 0x20);
        require(var_c.length == (address(var_c.length)));
        var_d = 0x1698ee8200000000000000000000000000000000000000000000000000000000;
        address var_e = address(this);
        var_f = 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2;
        var_g = 0x2710;
        (bool success, bytes memory ret0) = address(var_c.length).Unresolved_1698ee82(var_e); // staticcall
        var_c = var_c + (uint248(ret0.length + 0x1f));
        require(!((var_c + ret0.length) - var_c) < 0x20);
        require(var_c.length == (address(var_c.length)));
        uint256 var_h = address(var_c.length);
        address var_i = address(this);
        uint256 var_j = address(var_c.length);
        return abi.encodePacked(address(var_c.length), address(this), address(var_c.length));
    }
    
    /// @custom:selector    0x70a08231
    /// @custom:signature   balanceOf(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function balanceOf(address arg0) public view returns (uint256) {
        require(arg0 == (address(arg0)));
        address var_a = address(arg0);
        uint256 var_b = 0;
        address var_c = storage_map_b[var_a];
        return storage_map_b[var_a];
    }
    
    /// @custom:selector    0x95d89b41
    /// @custom:signature   symbol() public view returns (string memory)
    function symbol() public view returns (string memory) {
        if (store_h) {
            if (store_h - ((store_h >> 0x01) < 0x20)) {
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                var_b = 0x22;
                uint256 var_c = var_c + (0x20 + (((0x1f + (store_h >> 0x01)) / 0x20) * 0x20));
                bytes32 var_d = store_h >> 0x01;
                if (store_h) {
                    if (store_h - ((store_h >> 0x01) < 0x20)) {
                        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                        var_b = 0x22;
                        if (!store_h >> 0x01) {
                            if (0x1f < (store_h >> 0x01)) {
                                var_a = 0x04;
                                var_e = storage_map_b[var_a];
                                if ((0x20 + var_c) + (store_h >> 0x01) > (0x20 + (0x20 + var_c))) {
                                    var_e = 0x20;
                                    uint256 var_f = var_c.length;
                                    uint256 var_g = 0;
                                    return abi.encodePacked(0x20, var_c.length);
                                    uint256 var_e = (store_h / 0x0100) * 0x0100;
                                    var_e = 0x20;
                                    var_f = var_c.length;
                                    var_g = 0;
                                    return abi.encodePacked(0x20, var_c.length);
                                    var_e = 0x20;
                                    var_f = var_c.length;
                                    var_g = 0;
                                    return abi.encodePacked(0x20, var_c.length);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// @custom:selector    0xdd62ed3e
    /// @custom:signature   Unresolved_dd62ed3e(address arg0) public pure
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_dd62ed3e(address arg0) public pure {
        require(arg0 == (address(arg0)));
    }
    
    /// @custom:selector    0x095ea7b3
    /// @custom:signature   approve(address arg0, uint256 arg1) public payable returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function approve(address arg0, uint256 arg1) public payable returns (bool) {
        require(arg0 == (address(arg0)));
        require(address(msg.sender), CustomError_94280d62());
        require(address(arg0), CustomError_94280d62());
        address var_a = address(msg.sender);
        var_b = 0x01;
        var_a = address(arg0);
        address var_b = keccak256(var_a);
        storage_map_b[var_a] = arg1;
        require(!0x01, CustomError_94280d62());
        var_c = 0x01;
        return 0x01;
        uint256 var_c = arg1;
        emit Approval(address(msg.sender), address(arg0), arg1);
        var_c = 0x01;
        return 0x01;
        var_c = 0x94280d6200000000000000000000000000000000000000000000000000000000;
        uint256 var_d = 0;
        var_c = 0xe602df0500000000000000000000000000000000000000000000000000000000;
        var_d = 0;
    }
}