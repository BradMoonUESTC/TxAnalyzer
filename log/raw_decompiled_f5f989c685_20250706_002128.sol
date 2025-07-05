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
    mapping(bytes32 => bytes32) storage_map_u;
    uint256 public buyRate;
    mapping(bytes32 => bytes32) storage_map_p;
    bytes32 store_ab;
    uint256 store_aa;
    mapping(bytes32 => bytes32) storage_map_ac;
    uint256 public currentIndex;
    uint256 public getTimes;
    uint256 public unresolved_b8738d3a;
    address store_j;
    mapping(bytes32 => bytes32) storage_map_e;
    address public unresolved_0ede9262;
    address public owner;
    mapping(bytes32 => bytes32) storage_map_t;
    uint256 public minBNBAmount;
    mapping(bytes32 => bytes32) storage_map_x;
    uint256 public unresolved_f68c98e0;
    address public defaultAddress;
    address public parAddress;
    mapping(bytes32 => bytes32) storage_map_a;
    uint256 store_c;
    mapping(bytes32 => bytes32) storage_map_f;
    address public topAddress;
    mapping(bytes32 => bytes32) storage_map_ag;
    uint256 public unresolved_c09d1e58;
    mapping(bytes32 => bytes32) storage_map_n;
    address store_y;
    mapping(bytes32 => bytes32) storage_map_b;
    bytes32 store_l;
    address public ownerB;
    address public projectAddress;
    mapping(bytes32 => bytes32) storage_map_o;
    uint256 public unresolved_aeceb6f0;
    
    event BindIntro(address, address, uint256);
    event OwnershipTransferred(address, address);
    
    /// @custom:selector    0x489082df
    /// @custom:signature   takeToken(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function takeToken(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(address(arg0), "no right");
        address var_a = address(arg0);
        var_b = 0x77;
        require(storage_map_a[var_a], "no right");
        var_a = address(arg0);
        var_b = 0x78;
        storage_map_a[var_a] = 0;
        storage_map_b[var_a] = store_c;
        require(!(msg.sender == (address(parAddress))), "no right");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x08;
        var_f = 0x6e6f207269676874000000000000000000000000000000000000000000000000;
        var_a = address(arg0);
        var_b = 0x77;
        require(storage_map_a[var_a], "in black");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x08;
        var_f = 0x696e20626c61636b000000000000000000000000000000000000000000000000;
        require(address(arg0));
        var_a = address(arg0);
        var_b = 0x78;
        require(!storage_map_a[var_a]);
        storage_map_a[var_a] = 0;
        require(storage_map_e[var_a] > (storage_map_e[var_a] + storage_map_a[var_a]));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        storage_map_e[var_a] = (storage_map_e[var_a]) + storage_map_a[var_a];
        address var_c = storage_map_a[var_a];
        return storage_map_a[var_a];
        var_c = storage_map_a[var_a];
        return storage_map_a[var_a];
        var_c = 0;
        return 0;
        var_a = address(arg0);
        var_b = 0x7a;
        var_b = 0x78;
        require((store_c - (storage_map_b[var_a])) > store_c);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        require(!(storage_map_f[var_a] * (store_c - (storage_map_b[var_a])) / (storage_map_f[var_a]) == (store_c - (storage_map_b[var_a]))) | (!storage_map_f[var_a]));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        var_a = address(arg0);
        var_b = 0x78;
        require((storage_map_f[var_a] * (store_c - (storage_map_b[var_a])) / 0x0de0b6b3a7640000) > ((storage_map_f[var_a] * (store_c - (storage_map_b[var_a])) / 0x0de0b6b3a7640000) + storage_map_a[var_a]));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
    }
    
    /// @custom:selector    0x6dfd480b
    /// @custom:signature   Unresolved_6dfd480b(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_6dfd480b(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        require(!(address(arg0)), "can not be zero address");
        ownerB = (uint96(ownerB)) | (address(arg0));
        return ;
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x17;
        var_d = 0x63616e206e6f74206265207a65726f2061646472657373000000000000000000;
    }
    
    /// @custom:selector    0x8d232b97
    /// @custom:signature   changeUniswapV2Router(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function changeUniswapV2Router(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        store_j = (uint96(store_j)) | (address(arg0));
        return ;
    }
    
    /// @custom:selector    0x8e047f0f
    /// @custom:signature   Unresolved_8e047f0f(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_8e047f0f(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(address(arg0), "Ownable: caller is not the owner");
        address var_a = address(arg0);
        var_b = 0x77;
        require(storage_map_a[var_a], "Ownable: caller is not the owner");
        var_a = address(arg0);
        var_b = 0x78;
        storage_map_a[var_a] = 0;
        storage_map_b[var_a] = store_c;
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x20;
        var_f = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        var_a = address(arg0);
        var_b = 0x77;
        require(storage_map_a[var_a]);
        var_a = address(arg0);
        var_b = 0x7a;
        require((unresolved_c09d1e58 - (storage_map_f[var_a])) > unresolved_c09d1e58);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        unresolved_c09d1e58 = unresolved_c09d1e58 - (storage_map_f[var_a]);
        return ;
        require(!store_l < 0x010000000000000000);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x41;
        store_l = store_l + 0x01;
        require(!store_l < store_l);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x32;
        var_a = address(arg0);
        var_b = 0x7a;
        var_b = 0x78;
        require((store_c - (storage_map_b[var_a])) > store_c);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        require(!(storage_map_f[var_a] * (store_c - (storage_map_b[var_a])) / (storage_map_f[var_a]) == (store_c - (storage_map_b[var_a]))) | (!storage_map_f[var_a]));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        var_a = address(arg0);
        var_b = 0x78;
        require((storage_map_f[var_a] * (store_c - (storage_map_b[var_a])) / 0x0de0b6b3a7640000) > ((storage_map_f[var_a] * (store_c - (storage_map_b[var_a])) / 0x0de0b6b3a7640000) + storage_map_a[var_a]));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
    }
    
    /// @custom:selector    0x306c1f0c
    /// @custom:signature   updateAllAverage(uint256 arg0) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function updateAllAverage(uint256 arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, "no right");
        require(!(msg.sender == (address(parAddress))), "no right");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x08;
        var_d = 0x6e6f207269676874000000000000000000000000000000000000000000000000;
        require(unresolved_c09d1e58);
        require(arg0);
        require(arg0 | (((arg0 * 0x0de0b6b3a7640000) / arg0) == 0x0de0b6b3a7640000));
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_f = 0x11;
        require(!unresolved_c09d1e58);
        require(store_c > (store_c + ((arg0 * 0x0de0b6b3a7640000) / unresolved_c09d1e58)));
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_f = 0x11;
        store_c = store_c + ((arg0 * 0x0de0b6b3a7640000) / unresolved_c09d1e58);
        return ;
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_f = 0x12;
        return ;
    }
    
    /// @custom:selector    0xf4b35538
    /// @custom:signature   isBind(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function isBind(address arg0) public view returns (bool) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        var_b = 0x79;
        require(!address(storage_map_a[var_a]));
        require(address(storage_map_a[var_a]));
        var_c = 0x01;
        return 0x01;
        uint256 var_c = 0;
        return 0;
        require(address(topAddress) == (address(arg0)));
        var_c = 0;
        return 0;
        var_c = 0x01;
        return 0x01;
    }
    
    /// @custom:selector    0xe17b2e29
    /// @custom:signature   Unresolved_e17b2e29(address arg0) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_e17b2e29(address arg0) public view returns (bytes memory) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        var_b = 0x78;
        address var_c = storage_map_a[var_a];
        address var_d = storage_map_b[var_a];
        address var_e = storage_map_e[var_a];
        return abi.encodePacked(storage_map_a[var_a], storage_map_b[var_a], storage_map_e[var_a]);
    }
    
    /// @custom:selector    0x191437a1
    /// @custom:signature   getBuyerAtIndex(uint256 arg0) public view returns (address)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function getBuyerAtIndex(uint256 arg0) public view returns (address) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        uint256 var_a = arg0;
        var_b = 0x7b;
        uint256 var_c = address(storage_map_a[var_a]);
        return address(storage_map_a[var_a]);
    }
    
    /// @custom:selector    0xfcfad9ce
    /// @custom:signature   Unresolved_fcfad9ce(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_fcfad9ce(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        address var_e = address(arg0);
        var_f = 0x77;
        require(!storage_map_n[var_e]);
        require((0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff + storage_map_n[var_e]) > storage_map_n[var_e]);
        require((store_l + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) > store_l);
        require((store_l + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) - (0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff + storage_map_n[var_e]));
        require(!(store_l + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) < store_l);
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x32;
        require(!store_l);
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x31;
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        var_e = address(arg0);
        var_f = 0x78;
        storage_map_o[var_e] = store_c;
        var_f = 0x7a;
        require(unresolved_c09d1e58 > (unresolved_c09d1e58 + (storage_map_p[var_e])));
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        unresolved_c09d1e58 = unresolved_c09d1e58 + (storage_map_p[var_e]);
        return ;
    }
    
    /// @custom:selector    0x34cbe2a4
    /// @custom:signature   Unresolved_34cbe2a4(uint256 arg0) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_34cbe2a4(uint256 arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, "Ownable: caller is not the owner");
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        require(!arg0, "must great than 0");
        unresolved_f68c98e0 = arg0;
        return ;
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x11;
        var_d = 0x6d757374206772656174207468616e2030000000000000000000000000000000;
    }
    
    /// @custom:selector    0x3069a920
    /// @custom:signature   Unresolved_3069a920(uint256 arg0) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_3069a920(uint256 arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, "Ownable: caller is not the owner");
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        unresolved_aeceb6f0 = arg0;
        return ;
    }
    
    /// @custom:selector    0x85f236fc
    /// @custom:signature   Unresolved_85f236fc(uint256 arg0) public view returns (bool)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_85f236fc(uint256 arg0) public view returns (bool) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        uint256 var_a = arg0;
        var_b = 0x7c;
        uint256 var_c = !(!bytes1(storage_map_a[var_a]));
        return !(!bytes1(storage_map_a[var_a]));
    }
    
    /// @custom:selector    0xee9907a4
    /// @custom:signature   getUserIndex(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getUserIndex(address arg0) public view returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        var_b = 0x7a;
        address var_c = storage_map_b[var_a];
        return storage_map_b[var_a];
    }
    
    /// @custom:selector    0x80868398
    /// @custom:signature   getBind(address arg0) public view returns (address)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function getBind(address arg0) public view returns (address) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        var_b = 0x79;
        address var_c = address(storage_map_a[var_a]);
        return address(storage_map_a[var_a]);
    }
    
    /// @custom:selector    0x9dd5c01a
    /// @custom:signature   bindIntro(address arg0, address arg1) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function bindIntro(address arg0, address arg1) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(arg1 - (address(arg1)));
        require(!(msg.sender == (address(parAddress))), "no right");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x08;
        var_d = 0x6e6f207269676874000000000000000000000000000000000000000000000000;
        address var_e = address(arg1);
        var_f = 0x7a;
        require(((var_g + 0xa0) > 0xffffffffffffffff) | ((var_g + 0xa0) < var_g));
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_h = 0x41;
        uint256 var_g = var_g + 0xa0;
        address var_a = storage_map_n[var_e];
        address var_i = storage_map_o[var_e];
        address var_j = storage_map_t[var_e];
        address var_k = storage_map_p[var_e];
        address var_l = storage_map_u[var_e];
        require(!address(arg0).code.length);
        require(!address(arg1).code.length);
        require(storage_map_p[var_e]);
        var_e = address(arg0);
        var_f = 0x79;
        storage_map_n[var_e] = (uint96(storage_map_n[var_e])) | (address(arg1));
        address var_m = address(topAddress);
        address var_n = address(arg0);
        var_o = 0x01;
        emit BindIntro(address(topAddress), address(arg0), 0x01);
        return ;
        return ;
    }
    
    /// @custom:selector    0xe8082858
    /// @custom:signature   changeProjectAddress(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function changeProjectAddress(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        projectAddress = (uint96(projectAddress)) | (address(arg0));
        return ;
    }
    
    /// @custom:selector    0x7c0d24f1
    /// @custom:signature   Unresolved_7c0d24f1(address arg0) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_7c0d24f1(address arg0) public view returns (bytes memory) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20);
        require(arg0 - (address(arg0)));
        require(((var_a + 0xc0) > 0xffffffffffffffff) | ((var_a + 0xc0) < var_a));
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_c = 0x41;
        uint256 var_a = var_a + 0xc0;
        var_d = 0x05;
        var_e = msg.data[4:164];
        require(0 < 0x05);
        var_f = 0x20;
        uint256 var_g = var_a.length;
        return abi.encodePacked(0x20, var_a.length);
        address var_b = address(arg0);
        var_h = 0x79;
        require(address(storage_map_x[var_b]));
        require(address(topAddress) == (address(storage_map_x[var_b])));
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_c = 0x32;
        address var_i = address(storage_map_x[var_b]);
        require(0 == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_c = 0x11;
        var_b = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_c = 0x32;
    }
    
    /// @custom:selector    0x3c399169
    /// @custom:signature   Unresolved_3c399169(uint256 arg0, address arg1) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_3c399169(uint256 arg0, address arg1) public view returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 > 0xffffffffffffffff);
        require(!(arg0 + 0x23) < msg.data.length);
        require(arg0 > 0xffffffffffffffff);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_b = 0x41;
        require(((var_c + (uint248((0x20 + (arg0 << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (arg0 << 0x05)) + 0x1f))) < var_c));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_b = 0x41;
        uint256 var_c = var_c + (uint248((0x20 + (arg0 << 0x05)) + 0x1f));
        uint256 var_d = (arg0);
        require(((arg0 + (arg0 << 0x05)) + 0x24) > msg.data.length);
        require((0x24 + arg0) < ((arg0 + (arg0 << 0x05)) + 0x24));
        require(msg.data[0x24 + arg0] - (address(msg.data[0x24 + arg0])));
        require(arg1 > 0xffffffffffffffff);
        require(!((arg1 + 0x23) < msg.data.length), "Ownable: caller is not the owner");
        require(arg1 > 0xffffffffffffffff, "Ownable: caller is not the owner");
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_b = 0x41;
        require(((var_c + (uint248((0x20 + (arg1 << 0x05)) + 0x1f))) > 0xffffffffffffffff) | ((var_c + (uint248((0x20 + (arg1 << 0x05)) + 0x1f))) < var_c), "Ownable: caller is not the owner");
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_b = 0x41;
        var_c = var_c + (uint248((0x20 + (arg1 << 0x05)) + 0x1f));
        address var_e = (arg1);
        require(((arg1 + (arg1 << 0x05)) + 0x24) > msg.data.length, "Ownable: caller is not the owner");
        require((arg1 + 0x24) < ((arg1 + (arg1 << 0x05)) + 0x24), "Ownable: caller is not the owner");
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_f = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_g = 0x20;
        var_h = 0x20;
        var_i = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_b = 0x32;
        return ;
    }
    
    /// @custom:selector    0xa870ff6a
    /// @custom:signature   Unresolved_a870ff6a(uint256 arg0) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function Unresolved_a870ff6a(uint256 arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, "Ownable: caller is not the owner");
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        unresolved_b8738d3a = arg0;
        return ;
    }
    
    /// @custom:selector    0xe5d6d6ef
    /// @custom:signature   Unresolved_e5d6d6ef() public payable returns (uint256)
    function Unresolved_e5d6d6ef() public payable returns (uint256) {
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        require(msg.sender - (address(store_y)), "worng right");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x0b;
        var_d = 0x776f726e67207269676874000000000000000000000000000000000000000000;
        var_a = 0xad5c464800000000000000000000000000000000000000000000000000000000;
        (bool success, bytes memory ret0) = address(store_j).WETH(var_b); // staticcall
        require(!address(0).code.length);
        var_a = 0xd0e30db000000000000000000000000000000000000000000000000000000000;
        (bool success, bytes memory ret0) = address(0).{ value: msg.value }deposit(var_b); // call
        require(unresolved_aeceb6f0 > (unresolved_aeceb6f0 + msg.value));
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_f = 0x11;
        unresolved_aeceb6f0 = unresolved_aeceb6f0 + msg.value;
        return ;
        require(var_g > 0xffffffffffffffff);
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_f = 0x41;
        var_g = var_g;
        require(0);
        require(0x20 > ret0.length);
        require(((var_g + 0x20) > 0xffffffffffffffff) | ((var_g + 0x20) < var_g));
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_f = 0x41;
        uint256 var_g = var_g + 0x20;
        require(((var_g + 0x20) - var_g) < 0x20);
        require(var_g.length - (address(var_g.length)));
    }
    
    /// @custom:selector    0x1d1d630c
    /// @custom:signature   Unresolved_1d1d630c(uint256 arg0, uint256 arg1) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_1d1d630c(uint256 arg0, uint256 arg1) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40, "Ownable: caller is not the owner");
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        minBNBAmount = arg0;
        store_aa = arg1;
        return ;
    }
    
    /// @custom:selector    0x715018a6
    /// @custom:signature   renounceOwnership() public payable returns (uint256)
    function renounceOwnership() public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        owner = uint96(owner);
        emit OwnershipTransferred(address(owner), 0);
        return ;
    }
    
    /// @custom:selector    0x8129fc1c
    /// @custom:signature   initialize() public payable
    function initialize() public payable {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        require(!(bytes1(store_ab >> 0x08)), "Initializable: contract is not initializing");
        require(!(!bytes1(store_ab >> 0x08)), "Initializable: contract is not initializing");
        require(address(this).code.length, "Initializable: contract is not initializing");
        require(!(bytes1(store_ab) == 0x01), "Initializable: contract is not initializing");
        store_ab = 0x01 | (uint248(store_ab));
        require(!(bytes1(store_ab >> 0x08)), "Initializable: contract is not initializing");
        require(!(bytes1(store_ab >> 0x08)), "Initializable: contract is not initializing");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x2b;
        var_d = 0x496e697469616c697a61626c653a20636f6e7472616374206973206e6f742069;
        var_e = 0x6e697469616c697a696e67000000000000000000000000000000000000000000;
        store_ab = 0x0101 | (uint240(store_ab));
        require(!(bytes1(store_ab >> 0x08)), "Initializable: contract is not initializing");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x2b;
        var_d = 0x496e697469616c697a61626c653a20636f6e7472616374206973206e6f742069;
        var_e = 0x6e697469616c697a696e67000000000000000000000000000000000000000000;
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x2e;
        var_d = 0x496e697469616c697a61626c653a20636f6e747261637420697320616c726561;
        var_e = 0x647920696e697469616c697a6564000000000000000000000000000000000000;
        require(!(!bytes1(store_ab >> 0x08)), "Initializable: contract is already initialized");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x2e;
        var_d = 0x496e697469616c697a61626c653a20636f6e747261637420697320616c726561;
        var_e = 0x647920696e697469616c697a6564000000000000000000000000000000000000;
    }
    
    /// @custom:selector    0x89da7deb
    /// @custom:signature   removeLP(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function removeLP(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(address(arg0), "no right");
        address var_a = address(arg0);
        var_b = 0x77;
        require(storage_map_a[var_a], "no right");
        var_a = address(arg0);
        var_b = 0x78;
        storage_map_a[var_a] = 0;
        storage_map_b[var_a] = store_c;
        require(!(msg.sender == (address(unresolved_0ede9262))), "no right");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x08;
        var_f = 0x6e6f207269676874000000000000000000000000000000000000000000000000;
        require(tx.origin - (address(arg0)), "not belong to you");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x11;
        var_f = 0x6e6f742062656c6f6e6720746f20796f75000000000000000000000000000000;
        var_a = address(arg0);
        var_b = 0x77;
        require(storage_map_a[var_a], "Pulled into the blacklist");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x19;
        var_f = 0x50756c6c656420696e746f2074686520626c61636b6c69737400000000000000;
        var_a = address(arg0);
        var_b = 0x7a;
        require(!storage_map_ac[var_a]);
        var_c = 0xc45a015500000000000000000000000000000000000000000000000000000000;
        (bool success, bytes memory ret0) = address(store_j).factory(var_d); // staticcall
        var_c = 0xad5c464800000000000000000000000000000000000000000000000000000000;
        (bool success, bytes memory ret0) = address(store_j).WETH(var_d); // staticcall
        var_c = 0xe6a4390500000000000000000000000000000000000000000000000000000000;
        uint256 var_d = 0;
        address var_e = address(parAddress);
        (bool success, bytes memory ret0) = address(0).Unresolved_e6a43905(var_d); // staticcall
        var_c = 0x095ea7b300000000000000000000000000000000000000000000000000000000;
        var_d = address(store_j);
        var_e = storage_map_ac[var_a];
        (bool success, bytes memory ret0) = address(0).{ value: storage_map_a[var_a] ether }Unresolved_095ea7b3(var_d); // call
        var_c = 0xad5c464800000000000000000000000000000000000000000000000000000000;
        (bool success, bytes memory ret0) = address(store_j).WETH(var_d); // staticcall
        var_c = 0xbaa2abde00000000000000000000000000000000000000000000000000000000;
        var_d = 0;
        var_e = address(parAddress);
        address var_f = storage_map_ac[var_a];
        uint256 var_g = 0;
        uint256 var_h = 0;
        address var_i = address(this);
        uint256 var_j = block.timestamp;
        (bool success, bytes memory ret0) = address(store_j).{ value: var_g ether }Unresolved_baa2abde(var_d); // call
        require(0);
        var_c = 0xad5c464800000000000000000000000000000000000000000000000000000000;
        (bool success, bytes memory ret0) = address(store_j).WETH(var_d); // staticcall
        require(!address(0).code.length);
        var_c = 0x2e1a7d4d00000000000000000000000000000000000000000000000000000000;
        var_d = 0;
        (bool success, bytes memory ret0) = address(0).{ value: var_g ether }Unresolved_2e1a7d4d(var_d); // call
        require(0 > address(this).balance);
        var_c = 0xad5c464800000000000000000000000000000000000000000000000000000000;
        (bool success, bytes memory ret0) = address(store_j).WETH(var_d); // staticcall
        var_k = 0xa9059cbb00000000000000000000000000000000000000000000000000000000;
        var_e = address(arg0);
        var_f = 0;
        var_c = 0x44;
        require(((var_l + 0x80) > 0xffffffffffffffff) | ((var_l + 0x80) < var_l));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_m = 0x41;
        uint256 var_l = var_l + 0x80;
        require(((var_l + 0x40) > 0xffffffffffffffff) | ((var_l + 0x40) < var_l));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_m = 0x41;
        var_l = var_l + 0x40;
        var_n = 0x20;
        var_o = 0x5361666545524332303a206c6f772d6c6576656c2063616c6c206661696c6564;
        (bool success, bytes memory ret0) = address(0).{ value: var_f ether }Unresolved_a9059cbb(var_e); // call
        require(!ret0.length);
        require(!var_p);
        var_q = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_j = 0x20;
        uint256 var_r = var_l.length;
        uint256 var_s = 0;
        var_t = var_u;
        var_s = 0;
        require(!var_p, "SafeERC20: ERC20 operation did not succeed");
        require(var_p, "SafeERC20: ERC20 operation did not succeed");
        require((((0x60 + var_p) + 0x20) - 0x80) < 0x20, "SafeERC20: ERC20 operation did not succeed");
        require(var_c - var_c, "SafeERC20: ERC20 operation did not succeed");
        require(!var_c, "SafeERC20: ERC20 operation did not succeed");
        var_q = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_j = 0x20;
        var_r = 0x2a;
        var_t = 0x5361666545524332303a204552433230206f7065726174696f6e20646964206e;
        var_s = 0x6f74207375636365656400000000000000000000000000000000000000000000;
        if (storage_map_e[var_a]) {
            if (!storage_map_a[var_a]) {
            }
            require(storage_map_e[var_a]);
            currentIndex = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff + currentIndex;
            require(!currentIndex);
        }
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_m = 0x11;
        require(!address(0).code.length, "Address: call to non-contract");
        var_q = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_j = 0x20;
        var_r = 0x1d;
        var_t = 0x416464726573733a2063616c6c20746f206e6f6e2d636f6e7472616374000000;
        require(ret0.length > 0xffffffffffffffff);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_m = 0x41;
        require(((var_l + (uint248(((ret0.length + 0x1f) + 0x20) + 0x1f))) > 0xffffffffffffffff) | ((var_l + (uint248(((ret0.length + 0x1f) + 0x20) + 0x1f))) < var_l));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_m = 0x41;
        var_l = var_l + (uint248(((ret0.length + 0x1f) + 0x20) + 0x1f));
        uint256 var_q = ret0.length;
        require(!var_l.length);
        require(!var_l.length, "Address: call to non-contract");
        require(!address(0).code.length, "Address: call to non-contract");
        var_v = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_t = 0x20;
        var_s = 0x1d;
        var_w = 0x416464726573733a2063616c6c20746f206e6f6e2d636f6e7472616374000000;
        if (var_l.length) {
        }
        if (0x20 > ret0.length) {
        }
        require(!0);
        (bool success, bytes memory ret0) = address(arg0).transfer(0);
        if (var_l > 0xffffffffffffffff) {
            var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            var_m = 0x41;
            if (0x20 > ret0.length) {
            }
            require(var_l > 0xffffffffffffffff);
        }
        require(ret0.length < 0x20);
        require(((var_l + 0x20) > 0xffffffffffffffff) | ((var_l + 0x20) < var_l));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_m = 0x41;
        var_l = var_l + 0x20;
        require(((var_l + 0x20) - var_l) < 0x20);
        require(var_l.length - (address(var_l.length)));
        var_k = 0xbaa2abde00000000000000000000000000000000000000000000000000000000;
        var_e = address(var_l.length);
        var_f = address(parAddress);
        var_g = storage_map_ac[var_a];
        var_h = 0;
        var_i = 0;
        var_j = address(this);
        var_r = block.timestamp;
        (bool success, bytes memory ret0) = address(store_j).{ value: var_d ether }Unresolved_baa2abde(var_e, var_f, var_g, var_h, var_i); // call
        if (0x40 > ret0.length) {
        }
        if (0x20 > ret0.length) {
        }
        require(0x20 > ret0.length);
        require(((var_l + 0x20) > 0xffffffffffffffff) | ((var_l + 0x20) < var_l));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_m = 0x41;
        var_l = var_l + 0x20;
        require(((var_l + 0x20) - var_l) < 0x20);
        require(var_l.length - (address(var_l.length)));
        if (0x20 > ret0.length) {
        }
        if (0x20 > ret0.length) {
        }
        return ;
        var_a = address(arg0);
        var_b = 0x7a;
        var_b = 0x78;
        require((store_c - (storage_map_b[var_a])) > store_c);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_m = 0x11;
        require(!(storage_map_f[var_a] * (store_c - (storage_map_b[var_a])) / (storage_map_f[var_a]) == (store_c - (storage_map_b[var_a]))) | (!storage_map_f[var_a]));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_m = 0x11;
        var_a = address(arg0);
        var_b = 0x78;
        require((storage_map_f[var_a] * (store_c - (storage_map_b[var_a])) / 0x0de0b6b3a7640000) > ((storage_map_f[var_a] * (store_c - (storage_map_b[var_a])) / 0x0de0b6b3a7640000) + storage_map_a[var_a]));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_m = 0x11;
    }
    
    /// @custom:selector    0x931d93fc
    /// @custom:signature   buyerUserInfo(address arg0) public view returns (bytes memory)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function buyerUserInfo(address arg0) public view returns (bytes memory) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        var_b = 0x7a;
        address var_c = storage_map_a[var_a];
        address var_d = storage_map_b[var_a];
        address var_e = storage_map_e[var_a];
        address var_f = storage_map_f[var_a];
        address var_g = storage_map_ac[var_a];
        return abi.encodePacked(storage_map_a[var_a], storage_map_b[var_a], storage_map_e[var_a], storage_map_f[var_a], storage_map_ac[var_a]);
    }
    
    /// @custom:selector    0xa20793fc
    /// @custom:signature   Unresolved_a20793fc(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_a20793fc(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        store_y = (uint96(store_y)) | (address(arg0));
        return ;
    }
    
    /// @custom:selector    0xcc03d761
    /// @custom:signature   Unresolved_cc03d761() public view returns (uint256)
    function Unresolved_cc03d761() public view returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        require(!(msg.sender == (address(parAddress))), "no right");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x08;
        var_d = 0x6e6f207269676874000000000000000000000000000000000000000000000000;
        if ((block.timestamp - getTimes) > block.timestamp) {
            var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
            var_f = 0x11;
            if (!unresolved_b8738d3a) {
                if (!unresolved_b8738d3a) {
                    uint256 var_e = (block.timestamp - getTimes) / unresolved_b8738d3a;
                    var_g = 0x7c;
                    if (storage_map_n[var_e]) {
                        return ;
                        if (!(((unresolved_aeceb6f0 * buyRate) / unresolved_aeceb6f0) == buyRate) | !unresolved_aeceb6f0) {
                            var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                            var_f = 0x11;
                            if (!(unresolved_aeceb6f0 * buyRate) / 0x2710) {
                                if ((block.timestamp - getTimes) > block.timestamp) {
                                    var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                                    var_f = 0x11;
                                    if (!unresolved_b8738d3a) {
                                        if (!unresolved_b8738d3a) {
                                            var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                                            var_f = 0x12;
                                            if (!0x015180) {
                                                var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                                                var_f = 0x12;
                                                return ;
                                                var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                                                var_f = 0x12;
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
    
    /// @custom:selector    0xe6363cb1
    /// @custom:signature   Unresolved_e6363cb1(address arg0, uint256 arg1) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    /// @param              arg1 ["uint256", "bytes32", "int256"]
    function Unresolved_e6363cb1(address arg0, uint256 arg1) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x40);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        address var_e = address(arg0);
        var_f = 0x78;
        require(storage_map_n[var_e] > (storage_map_n[var_e] + arg1));
        var_e = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        storage_map_n[var_e] = storage_map_n[var_e] + arg1;
        return ;
    }
    
    /// @custom:selector    0x44af2e0e
    /// @custom:signature   changeBuyRate(uint256 arg0) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function changeBuyRate(uint256 arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20, "Ownable: caller is not the owner");
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        buyRate = arg0;
        return ;
    }
    
    /// @custom:selector    0x496b370e
    /// @custom:signature   indexUser(uint256 arg0) public view returns (address)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function indexUser(uint256 arg0) public view returns (address) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        uint256 var_a = arg0;
        var_b = 0x7b;
        uint256 var_c = address(storage_map_a[var_a]);
        return address(storage_map_a[var_a]);
    }
    
    /// @custom:selector    0x35b03203
    /// @custom:signature   intro(address arg0) public view returns (address)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function intro(address arg0) public view returns (address) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        var_b = 0x79;
        address var_c = address(storage_map_a[var_a]);
        return address(storage_map_a[var_a]);
    }
    
    /// @custom:selector    0x22a85ee3
    /// @custom:signature   Unresolved_22a85ee3(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_22a85ee3(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        unresolved_0ede9262 = (uint96(unresolved_0ede9262)) | (address(arg0));
        return ;
    }
    
    /// @custom:selector    0xf2fde38b
    /// @custom:signature   transferOwnership(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function transferOwnership(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        require(!(address(arg0)), "Ownable: new owner is the zero address");
        owner = (address(arg0)) | (uint96(owner));
        emit OwnershipTransferred(address(owner), address(arg0));
        return ;
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x26;
        var_d = 0x4f776e61626c653a206e6577206f776e657220697320746865207a65726f2061;
        var_e = 0x6464726573730000000000000000000000000000000000000000000000000000;
    }
    
    /// @custom:selector    0xaffd5db9
    /// @custom:signature   Unresolved_affd5db9() public payable returns (uint256)
    function Unresolved_affd5db9() public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0);
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        require(!address(this).balance);
        (bool success, bytes memory ret0) = address(msg.sender).transfer(address(this).balance);
        return ;
    }
    
    /// @custom:selector    0x2a55feec
    /// @custom:signature   isBuyer(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function isBuyer(address arg0) public view returns (bool) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        var_b = 0x7a;
        address var_c = !(minBNBAmount > (storage_map_f[var_a]));
        return !(minBNBAmount > (storage_map_f[var_a]));
    }
    
    /// @custom:selector    0x91bbec1a
    /// @custom:signature   getUserList(uint256 arg0) public view
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function getUserList(uint256 arg0) public view {
        require(msg.value);
        if ((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20) {
            uint256 var_a = arg0;
            var_b = 0x7b;
            var_a = address(storage_map_a[var_a]);
            var_b = 0x7a;
            if (((var_c + 0xa0) > 0xffffffffffffffff) | ((var_c + 0xa0) < var_c)) {
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                var_d = 0x41;
                uint256 var_c = var_c + 0xa0;
                uint256 var_e = storage_map_a[var_a];
                uint256 var_f = storage_map_b[var_a];
                uint256 var_g = storage_map_e[var_a];
                uint256 var_h = storage_map_f[var_a];
                uint256 var_i = storage_map_ac[var_a];
                require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
                require(((var_c + 0xa0) > 0xffffffffffffffff) | ((var_c + 0xa0) < var_c));
                require(!storage_map_e[var_a]);
                require(0x01);
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                var_d = 0x41;
                require(0 > 0xffffffffffffffff);
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                var_d = 0x41;
                var_c = var_c + 0x20;
                uint256 var_j = 0;
                require(((var_c + 0x20) > 0xffffffffffffffff) | ((var_c + 0x20) < var_c));
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                var_d = 0x41;
                require(0 > 0xffffffffffffffff);
                require(0 < unresolved_f68c98e0);
                var_a = var_k;
                var_b = 0x7b;
                var_a = address(storage_map_a[var_a]);
                var_b = 0x7a;
                require(!var_k);
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                var_d = 0x41;
                var_c = var_c + 0xa0;
                var_j = storage_map_a[var_a];
                uint256 var_l = storage_map_b[var_a];
                uint256 var_m = storage_map_e[var_a];
                uint256 var_n = storage_map_f[var_a];
                uint256 var_o = storage_map_ac[var_a];
                require(((var_c + 0xa0) > 0xffffffffffffffff) | ((var_c + 0xa0) < var_c));
                var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
                var_d = 0x11;
                require(0 == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            }
        }
    }
    
    /// @custom:selector    0xa224fc4f
    /// @custom:signature   Unresolved_a224fc4f(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_a224fc4f(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(!(msg.sender == (address(ownerB))), "no right");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x08;
        var_d = 0x6e6f207269676874000000000000000000000000000000000000000000000000;
        owner = (address(arg0)) | (uint96(owner));
        emit OwnershipTransferred(address(owner), address(arg0));
        return ;
    }
    
    /// @custom:selector    0x9f5c18c4
    /// @custom:signature   Unresolved_9f5c18c4(address arg0) public view returns (bool)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_9f5c18c4(address arg0) public view returns (bool) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        var_b = 0x77;
        address var_c = storage_map_a[var_a];
        return storage_map_a[var_a];
    }
    
    /// @custom:selector    0x4184b3e0
    /// @custom:signature   Unresolved_4184b3e0(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_4184b3e0(address arg0) public view returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        var_b = 0x7a;
        address var_c = storage_map_f[var_a];
        return storage_map_f[var_a];
    }
    
    /// @custom:selector    0xd59f62a8
    /// @custom:signature   getUserAmount(uint256 arg0) public view returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function getUserAmount(uint256 arg0) public view returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        uint256 var_a = arg0;
        var_b = 0x7b;
        var_a = address(storage_map_a[var_a]);
        var_b = 0x7a;
        require(((var_c + 0xa0) > 0xffffffffffffffff) | ((var_c + 0xa0) < var_c));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_d = 0x41;
        uint256 var_c = var_c + 0xa0;
        uint256 var_e = storage_map_a[var_a];
        uint256 var_f = storage_map_b[var_a];
        uint256 var_g = storage_map_e[var_a];
        uint256 var_h = storage_map_f[var_a];
        uint256 var_i = storage_map_ac[var_a];
        require(arg0 == 0x01);
        require(!storage_map_e[var_a]);
        require(0x01);
        uint256 var_j = 0;
        return 0;
        require(0 < unresolved_f68c98e0);
        require(!var_k);
        var_a = var_k;
        var_b = 0x7b;
        var_a = address(storage_map_a[var_a]);
        var_b = 0x7a;
        require(((var_c + 0xa0) > 0xffffffffffffffff) | ((var_c + 0xa0) < var_c));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_d = 0x41;
        var_c = var_c + 0xa0;
        var_j = storage_map_a[var_a];
        uint256 var_l = storage_map_b[var_a];
        uint256 var_m = storage_map_e[var_a];
        uint256 var_n = storage_map_f[var_a];
        uint256 var_o = storage_map_ac[var_a];
        require(0 == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_d = 0x11;
        var_j = 0;
        return 0;
        var_j = 0;
        return 0;
        require(arg0 == 0x01);
        var_j = 0;
        return 0;
    }
    
    /// @custom:selector    0x1ab6ab04
    /// @custom:signature   getMainToken(uint256 arg0) public payable returns (uint256)
    /// @param              arg0 ["uint256", "bytes32", "int256"]
    function getMainToken(uint256 arg0) public payable returns (uint256) {
        require(msg.value);
        require((msg.data.length + 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) < 0x20, "Ownable: caller is not the owner");
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        var_a = 0xad5c464800000000000000000000000000000000000000000000000000000000;
        (bool success, bytes memory ret0) = address(store_j).WETH(var_b); // staticcall
        var_a = 0xa9059cbb00000000000000000000000000000000000000000000000000000000;
        address var_b = msg.sender;
        uint256 var_c = arg0;
        (bool success, bytes memory ret0) = address(0).{ value: 0 ether }Unresolved_a9059cbb(var_b); // call
        return ;
        require(ret0.length < 0x20);
        require(((var_e + 0x20) > 0xffffffffffffffff) | ((var_e + 0x20) < var_e));
        var_f = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x41;
        uint256 var_e = var_e + 0x20;
        require(((var_e + 0x20) - var_e) < 0x20);
        require(var_e.length - var_e.length);
        return ;
        require(0x20 > ret0.length);
        require(((var_e + 0x20) > 0xffffffffffffffff) | ((var_e + 0x20) < var_e));
        var_f = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x41;
        var_e = var_e + 0x20;
        require(((var_e + 0x20) - var_e) < 0x20);
        require(var_e.length - (address(var_e.length)));
    }
    
    /// @custom:selector    0x7ff3a99e
    /// @custom:signature   Unresolved_7ff3a99e(address arg0) public payable
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_7ff3a99e(address arg0) public payable {
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(address(arg0), "no right");
        address var_a = address(arg0);
        var_b = 0x77;
        require(storage_map_a[var_a], "no right");
        var_a = address(arg0);
        var_b = 0x78;
        storage_map_a[var_a] = 0;
        storage_map_b[var_a] = store_c;
        require(!(msg.sender == (address(parAddress))), "no right");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x08;
        var_f = 0x6e6f207269676874000000000000000000000000000000000000000000000000;
        require(address(arg0).code.length, "must user buy");
        require(tx.origin - (address(arg0)), "must user buy");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x0d;
        var_f = 0x6d75737420757365722062757900000000000000000000000000000000000000;
        var_a = address(arg0);
        var_b = 0x7a;
        require(storage_map_f[var_a] > (storage_map_f[var_a] + msg.value), "to less");
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        storage_map_f[var_a] = (storage_map_f[var_a]) + msg.value;
        require(msg.value < minBNBAmount, "to less");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x07;
        var_f = 0x746f206c65737300000000000000000000000000000000000000000000000000;
        require(store_aa < (storage_map_f[var_a] + msg.value), "too more");
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x08;
        var_f = 0x746f6f206d6f7265000000000000000000000000000000000000000000000000;
        require(!(storage_map_ac[var_a]), "can not buy");
        require(currentIndex > 0x01, "can not buy");
        require((currentIndex + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) > currentIndex, "can not buy");
        var_a = currentIndex + 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        var_b = 0x7b;
        var_a = address(storage_map_a[var_a]);
        var_b = 0x7a;
        storage_map_e[var_a] = currentIndex;
        storage_map_a[var_a] = storage_map_ag[var_a];
        storage_map_ag[var_a] = currentIndex;
        var_a = currentIndex;
        var_b = 0x7b;
        storage_map_a[var_a] = (address(arg0)) | (uint96(storage_map_a[var_a]));
        require(currentIndex == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, "can not buy");
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        var_c = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_d = 0x20;
        var_e = 0x0b;
        var_f = 0x63616e206e6f7420627579000000000000000000000000000000000000000000;
        var_a = address(arg0);
        var_b = 0x7a;
        var_b = 0x78;
        require((store_c - (storage_map_b[var_a])) > store_c);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        require(!(storage_map_f[var_a] * (store_c - (storage_map_b[var_a])) / (storage_map_f[var_a]) == (store_c - (storage_map_b[var_a]))) | (!storage_map_f[var_a]));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
        var_a = address(arg0);
        var_b = 0x78;
        require((storage_map_f[var_a] * (store_c - (storage_map_b[var_a])) / 0x0de0b6b3a7640000) > ((storage_map_f[var_a] * (store_c - (storage_map_b[var_a])) / 0x0de0b6b3a7640000) + storage_map_a[var_a]));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_g = 0x11;
    }
    
    /// @custom:selector    0x2d718b3a
    /// @custom:signature   Unresolved_2d718b3a(address arg0) public payable returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function Unresolved_2d718b3a(address arg0) public payable returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        require(msg.sender - (address(owner)), "Ownable: caller is not the owner");
        var_a = 0x08c379a000000000000000000000000000000000000000000000000000000000;
        var_b = 0x20;
        var_c = 0x20;
        var_d = 0x4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572;
        parAddress = (uint96(parAddress)) | (address(arg0));
        return ;
    }
    
    /// @custom:selector    0x1454aef1
    /// @custom:signature   earnedToken(address arg0) public view returns (uint256)
    /// @param              arg0 ["address", "uint160", "bytes20", "int160"]
    function earnedToken(address arg0) public view returns (uint256) {
        require(msg.value);
        require((0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc + msg.data.length) < 0x20);
        require(arg0 - (address(arg0)));
        address var_a = address(arg0);
        var_b = 0x77;
        require(storage_map_a[var_a]);
        uint256 var_c = 0;
        return 0;
        var_a = address(arg0);
        var_b = 0x7a;
        var_b = 0x78;
        require((store_c - (storage_map_b[var_a])) > store_c);
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_d = 0x11;
        require(!(storage_map_f[var_a] * (store_c - (storage_map_b[var_a])) / (storage_map_f[var_a]) == (store_c - (storage_map_b[var_a]))) | (!storage_map_f[var_a]));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_d = 0x11;
        var_a = address(arg0);
        var_b = 0x78;
        require((storage_map_f[var_a] * (store_c - (storage_map_b[var_a])) / 0x0de0b6b3a7640000) > ((storage_map_f[var_a] * (store_c - (storage_map_b[var_a])) / 0x0de0b6b3a7640000) + storage_map_a[var_a]));
        var_a = 0x4e487b7100000000000000000000000000000000000000000000000000000000;
        var_d = 0x11;
        var_c = (storage_map_f[var_a] * (store_c - (storage_map_b[var_a])) / 0x0de0b6b3a7640000) + storage_map_a[var_a];
        return (storage_map_f[var_a] * (store_c - (storage_map_b[var_a])) / 0x0de0b6b3a7640000) + storage_map_a[var_a];
    }
}