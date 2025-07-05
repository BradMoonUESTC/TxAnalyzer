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
    mapping(bytes32 => bytes32) storage_map_l;
    mapping(bytes32 => bytes32) storage_map_h;
    mapping(bytes32 => bytes32) storage_map_r;
    mapping(bytes32 => bytes32) storage_map_c;
    mapping(bytes32 => bytes32) storage_map_f;
    mapping(bytes32 => bytes32) storage_map_j;
    address public rewardToken;
    bytes32 store_p;
    mapping(bytes32 => bytes32) storage_map_m;
    address store_k;
    mapping(bytes32 => bytes32) storage_map_n;
    bytes32 store_a;
    uint256 public timeLength;
    bytes32 store_b;
    address public usdt;
    uint256 public getToday;
    address public unresolved_8a810056;
    address public owner;
    
    event NodeAdded(address, uint256);
    event NodeRemoved(address);
    
    /// @custom:selector    0xbd7a303f
    /// @custom:signature   Unresolved_bd7a303f(uint256 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_bd7a303f(uint256 arg0) public view returns (uint256) {
        require(msg.value);
        if ((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20) {
            if (0 < store_a) {
                require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
                var_a = 0x08;
                address var_a = address(store_b >> 0);
                var_b = 0x06;
                require(0 < store_a);
                require(!0 < store_a);
                var_a = 0x08;
                var_a = address(store_b >> 0);
                var_b = 0x06;
                require(!0 < store_a);
                require(!storage_map_c[var_a] > arg0);
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                var_c = 0x11;
                require(0 == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                var_c = 0x11;
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                var_c = 0x32;
                require(0 == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            }
        }
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_c = 0x32;
        uint256 var_d = 0;
        return 0;
    }
    
    /// @custom:selector    0xc7c5a25e
    /// @custom:signature   Unresolved_c7c5a25e(uint256 arg0) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_c7c5a25e(uint256 arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, "Not owner");
        require(!(msg.sender == (address(owner))), "Not owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x09;
        var_d = 0x4e6f74206f776e65720000000000000000000000000000000000000000000000;
        require(!arg0, "wrong time");
        timeLength = arg0;
        return ;
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x0a;
        var_d = 0x77726f6e672074696d6500000000000000000000000000000000000000000000;
    }
    
    /// @custom:selector    0xb2931096
    /// @custom:signature   hasClaimed(address arg0, uint256 arg1) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function hasClaimed(address arg0, uint256 arg1) public view returns (bool) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x40);
        require(arg0 - (address(arg0)));
        uint256 var_a = arg1;
        var_b = 0x07;
        var_a = address(arg0);
        uint256 var_b = 0x05 + keccak256(var_a);
        uint256 var_c = !(!bytes1(storage_map_c[var_a]));
        return !(!bytes1(storage_map_c[var_a]));
    }
    
    /// @custom:selector    0x189a5a17
    /// @custom:signature   nodes(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function nodes(address arg0) public view returns (bool) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        var_b = 0x06;
        address var_c = storage_map_c[var_a];
        address var_d = !(!bytes1(storage_map_f[var_a]));
        return abi.encodePacked(storage_map_c[var_a], (bytes1(storage_map_f[var_a])));
    }
    
    /// @custom:selector    0x5f465f8f
    /// @custom:signature   Unresolved_5f465f8f(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_5f465f8f(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(!(msg.sender == (address(owner))), "Not owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x09;
        var_d = 0x4e6f74206f776e65720000000000000000000000000000000000000000000000;
        unresolved_8a810056 = (uint96(unresolved_8a810056)) | (address(arg0));
        return ;
    }
    
    /// @custom:selector    0x8c256359
    /// @custom:signature   isNodes(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function isNodes(address arg0) public view returns (bool) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        var_b = 0x06;
        address var_c = !(!bytes1(storage_map_f[var_a]));
        return !(!bytes1(storage_map_f[var_a]));
    }
    
    /// @custom:selector    0x9d95f1cc
    /// @custom:signature   addNode(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function addNode(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(!(msg.sender == (address(owner))), "Not owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x09;
        var_d = 0x4e6f74206f776e65720000000000000000000000000000000000000000000000;
        address var_e = address(arg0);
        var_f = 0x06;
        require(bytes1(storage_map_h[var_e]), "Already a node");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x0e;
        var_d = 0x416c72656164792061206e6f6465000000000000000000000000000000000000;
        require((block.timestamp - getToday) > block.timestamp);
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        require(!timeLength);
        require(((var_h + 0x40) > 0xffffffffffffffff) | ((var_h + 0x40) < var_h));
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x41;
        uint256 var_h = var_h + 0x40;
        uint256 var_a = (block.timestamp - getToday) / timeLength;
        var_i = 0x01;
        var_e = address(arg0);
        var_f = 0x06;
        storage_map_j[var_e] = var_h.length;
        storage_map_h[var_e] = (bytes1(var_j)) | (uint248(storage_map_h[var_e]));
        require(!store_a < 0x010000000000000000);
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x41;
        store_a = store_a + 0x01;
        require(!store_a < store_a);
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x32;
        var_e = 0x08;
        store_k = (uint96(store_k)) | (address(arg0) << 0);
        uint256 var_k = (block.timestamp - getToday) / timeLength;
        emit NodeAdded(address(arg0), (block.timestamp - getToday) / timeLength);
        return ;
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x12;
    }
    
    /// @custom:selector    0xb79b70eb
    /// @custom:signature   getBonusPool(uint256 arg0) public view returns (bool)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function getBonusPool(uint256 arg0) public view returns (bool) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        uint256 var_a = arg0;
        var_b = 0x07;
        uint256 var_c = storage_map_c[var_a];
        uint256 var_d = storage_map_l[var_a];
        uint256 var_e = storage_map_f[var_a];
        uint256 var_f = storage_map_m[var_a];
        uint256 var_g = !(!bytes1(storage_map_n[var_a]));
        return abi.encodePacked(storage_map_c[var_a], storage_map_l[var_a], storage_map_f[var_a], storage_map_m[var_a], (bytes1(storage_map_n[var_a])));
    }
    
    /// @custom:selector    0x4e71d92d
    /// @custom:signature   claim() public view
    function claim() public view {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        address var_a = msg.sender;
        var_b = 0x06;
        require(!(bytes1(storage_map_f[var_a])), "Node too new");
        require((block.timestamp - getToday) > block.timestamp, "Node too new");
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_c = 0x11;
        require(!timeLength, "Node too new");
        require((((block.timestamp - getToday) / timeLength) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) > ((block.timestamp - getToday) / timeLength), "Node too new");
        require((((block.timestamp - getToday) / timeLength) + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe) > ((block.timestamp - getToday) / timeLength), "Node too new");
        var_a = ((block.timestamp - getToday) / timeLength) + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe;
        var_b = 0x07;
        require(!(bytes1(storage_map_n[var_a])), "Node too new");
        var_a = msg.sender;
        var_b = 0x06;
        require(storage_map_c[var_a] > (((block.timestamp - getToday) / timeLength) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff), "Node too new");
        var_d = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_e = 0x20;
        var_f = 0x0c;
        var_g = 0x4e6f646520746f6f206e65770000000000000000000000000000000000000000;
        var_a = ((block.timestamp - getToday) / timeLength) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        var_b = 0x07;
        var_a = msg.sender;
        address var_b = keccak256(var_a) + 0x05;
        require(bytes1(storage_map_c[var_a]), "Already claimed");
        var_d = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_e = 0x20;
        var_f = 0x0f;
        var_g = 0x416c726561647920636c61696d65640000000000000000000000000000000000;
        if (0 < store_a) {
            if (!0 < store_a) {
                var_a = 0x08;
                var_a = address(store_b >> 0);
                var_b = 0x06;
                require(0 < store_a, "No valid nodes");
                require(!(0 < store_a), "No valid nodes");
                var_a = 0x08;
                var_a = address(store_b >> 0);
                var_b = 0x06;
                require(!(0 < store_a), "No valid nodes");
                require(!(storage_map_c[var_a] > (((block.timestamp - getToday) / timeLength) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)), "No valid nodes");
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                var_c = 0x11;
                require(0 == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, "No valid nodes");
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                var_c = 0x11;
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                var_c = 0x32;
                require(0 == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, "No valid nodes");
            }
        }
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_c = 0x32;
        require(!0, "No valid nodes");
        require(!0, "No valid nodes");
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_c = 0x12;
        var_d = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_e = 0x20;
        var_f = 0x0e;
        var_g = 0x4e6f2076616c6964206e6f646573000000000000000000000000000000000000;
        require((block.timestamp - getToday) > block.timestamp, "Not a node");
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_c = 0x11;
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_c = 0x11;
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_c = 0x11;
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_c = 0x12;
        var_d = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_e = 0x20;
        var_f = 0x0a;
        var_g = 0x4e6f742061206e6f646500000000000000000000000000000000000000000000;
    }
    
    /// @custom:selector    0x208f2a31
    /// @custom:signature   nodeList(uint256 arg0) public view returns (address)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function nodeList(uint256 arg0) public view returns (address) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(!arg0 < store_a);
        require(!arg0 < store_a);
        var_a = 0x08;
        uint256 var_b = address(store_p >> 0);
        return address(store_p >> 0);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_c = 0x32;
    }
    
    /// @custom:selector    0xb2b99ec9
    /// @custom:signature   removeNode(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function removeNode(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(!(msg.sender == (address(owner))), "Not owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x09;
        var_d = 0x4e6f74206f776e65720000000000000000000000000000000000000000000000;
        address var_e = address(arg0);
        var_f = 0x06;
        require(!(bytes1(storage_map_h[var_e])), "Not a node");
        var_e = address(arg0);
        var_f = 0x06;
        storage_map_j[var_e] = 0;
        storage_map_h[var_e] = 0;
        require(0x01, "Not a node");
        emit NodeRemoved(address(arg0));
        return ;
        require(!(0 < store_a), "Not a node");
        require(!(0 < store_a), "Not a node");
        var_e = 0x08;
        require(address(store_b >> 0) == (address(arg0)), "Not a node");
        require(0 == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, "Not a node");
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        require((store_a + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) > store_a, "Not a node");
        require(!((store_a + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < store_a), "Not a node");
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x32;
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x32;
        emit NodeRemoved(address(arg0));
        return ;
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x0a;
        var_d = 0x4e6f742061206e6f646500000000000000000000000000000000000000000000;
    }
    
    /// @custom:selector    0xcbae0b8d
    /// @custom:signature   Unresolved_cbae0b8d(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_cbae0b8d(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(!(msg.sender == (address(owner))), "Not owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x09;
        var_d = 0x4e6f74206f776e65720000000000000000000000000000000000000000000000;
        usdt = (uint96(usdt)) | (address(arg0));
        return ;
    }
    
    /// @custom:selector    0x9c4380e7
    /// @custom:signature   getToken(address arg0, address arg1, uint256 arg2) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg2 ["uint256", "bytes32", "int256"]
    function getToken(address arg0, address arg1, uint256 arg2) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x60);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(!(msg.sender == (address(owner))), "Not owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x09;
        var_d = 0x4e6f74206f776e65720000000000000000000000000000000000000000000000;
        var_a = 0xa9059cbb00000000000000000000000000000000000000000000000000000000;
        address var_b = address(arg1);
        uint256 var_c = arg2;
        (bool success, bytes memory ret0) = address(arg0).{ value: 0 ether }Unresolved_a9059cbb(var_b); // call
        return ;
        require(0x20 > ret0.length);
        require(((var_e + 0x20) > 0xffffffffffffffff) | ((var_e + 0x20) < var_e));
        var_f = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x41;
        uint256 var_e = var_e + 0x20;
        require(((var_e + 0x20) - var_e) < 0x20);
        require(var_e.length - var_e.length);
        return ;
    }
    
    /// @custom:selector    0x7f315061
    /// @custom:signature   Unresolved_7f315061(uint256 arg0) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_7f315061(uint256 arg0) public view {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, "not rant");
        require(!(msg.sender == (address(rewardToken))), "not rant");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x08;
        var_d = 0x6e6f742072616e74000000000000000000000000000000000000000000000000;
        require((block.timestamp - getToday) > block.timestamp);
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_f = 0x11;
        require(!timeLength);
        uint256 var_e = (block.timestamp - getToday) / timeLength;
        var_g = 0x07;
        require(storage_map_r[var_e] > (storage_map_r[var_e] + arg0));
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_f = 0x11;
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_f = 0x12;
    }
    
    /// @custom:selector    0xc15de638
    /// @custom:signature   Unresolved_c15de638(uint256 arg0) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_c15de638(uint256 arg0) public view {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, "not rant");
        require(!(msg.sender == (address(unresolved_8a810056))), "not rant");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x08;
        var_d = 0x6e6f742072616e74000000000000000000000000000000000000000000000000;
        require((block.timestamp - getToday) > block.timestamp);
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_f = 0x11;
        require(!timeLength);
        uint256 var_e = (block.timestamp - getToday) / timeLength;
        var_g = 0x07;
        require(storage_map_j[var_e] > (storage_map_j[var_e] + arg0));
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_f = 0x11;
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_f = 0x12;
    }
    
    /// @custom:selector    0x66829b16
    /// @custom:signature   changeToken(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function changeToken(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(!(msg.sender == (address(owner))), "Not owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x09;
        var_d = 0x4e6f74206f776e65720000000000000000000000000000000000000000000000;
        rewardToken = (uint96(rewardToken)) | (address(arg0));
        return ;
    }
    
    /// @custom:selector    0xdf9620eb
    /// @custom:signature   Unresolved_df9620eb(uint256 arg0, address arg1) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_df9620eb(uint256 arg0, address arg1) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 > 0xffffffffffffffff);
        require(!(arg0 + 0x23) < msg.data.length);
        require(arg0 > 0xffffffffffffffff);
        require(((arg0 + (arg0 << 0x05)) + 0x24) > msg.data.length, "Not owner");
        require(!(msg.sender == (address(owner))), "Not owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x09;
        var_d = 0x4e6f74206f776e65720000000000000000000000000000000000000000000000;
        require((block.timestamp - getToday) > block.timestamp);
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_f = 0x11;
        require(!timeLength);
        require(0 < (arg0));
        require(msg.data[(arg0 + 0) + 0x24] - (address(msg.data[(arg0 + 0) + 0x24])));
        uint256 var_e = address(msg.data[(arg0 + 0) + 0x24]);
        var_g = 0x06;
        require(!bytes1(storage_map_h[var_e]));
        require(0 == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_f = 0x11;
        require(((var_h + 0x40) > 0xffffffffffffffff) | ((var_h + 0x40) < var_h));
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_f = 0x41;
        uint256 var_h = var_h + 0x40;
        uint256 var_a = (block.timestamp - getToday) / timeLength;
        var_i = 0x01;
        var_e = address(msg.data[(arg0 + 0) + 0x24]);
        var_g = 0x06;
        storage_map_j[var_e] = var_h.length;
        storage_map_h[var_e] = (bytes1(var_j)) | (uint248(storage_map_h[var_e]));
        require(!store_a < 0x010000000000000000);
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_f = 0x41;
        store_a = store_a + 0x01;
        require(!store_a < store_a);
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_f = 0x32;
        return ;
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_f = 0x12;
    }
    
    /// @custom:selector    0xf2fde38b
    /// @custom:signature   transferOwnership(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function transferOwnership(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(!(address(owner) == msg.sender), "Not owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x09;
        var_d = 0x4e6f74206f776e65720000000000000000000000000000000000000000000000;
        owner = (uint96(owner)) | (address(arg0));
        return ;
    }
    
    /// @custom:selector    0x53f3b713
    /// @custom:signature   getNodeList() public view returns (bytes memory)
    function getNodeList() public view returns (bytes memory) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        var_a = store_a;
        var_b = 0x08;
        if (0 < store_a) {
            if (((var_c + (uint248(((var_c + 0x20) - var_c) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248(((var_c + 0x20) - var_c) + 0x1f))) < var_c)) {
                var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                var_d = 0x41;
                uint248 var_c = var_c + (uint248(((var_c + 0x20) - var_c) + 0x1f));
                var_e = 0x20;
                uint256 var_f = var_c.length;
                return abi.encodePacked(0x20, var_c.length);
            }
        }
    }
    
    /// @custom:selector    0xafe5b025
    /// @custom:signature   Unresolved_afe5b025() public payable returns (uint256)
    function Unresolved_afe5b025() public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        if ((block.timestamp - getToday) > block.timestamp) {
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            var_b = 0x11;
            if (!timeLength) {
                if ((((block.timestamp - getToday) / timeLength) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) > ((block.timestamp - getToday) / timeLength)) {
                    if ((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe + ((block.timestamp - getToday) / timeLength)) > (((block.timestamp - getToday) / timeLength) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)) {
                        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                        var_b = 0x11;
                        uint256 var_a = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe + ((block.timestamp - getToday) / timeLength);
                        var_c = 0x07;
                        if (storage_map_n[var_a]) {
                            return ;
                            if (storage_map_f[var_a]) {
                                var_a = ((block.timestamp - getToday) / timeLength) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
                                if (storage_map_c[var_a] > (storage_map_c[var_a] + (storage_map_f[var_a]))) {
                                    var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                                    var_b = 0x11;
                                    if (storage_map_m[var_a]) {
                                        var_a = ((block.timestamp - getToday) / timeLength) + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
                                        var_c = 0x07;
                                        if (storage_map_l[var_a] > (storage_map_l[var_a] + (storage_map_m[var_a]))) {
                                            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                                            var_b = 0x11;
                                            storage_map_n[var_a] = (uint248(storage_map_n[var_a])) | 0x01;
                                            return ;
                                            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                                            var_b = 0x11;
                                            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                                            var_b = 0x12;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}