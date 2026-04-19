// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

struct Origin {
    uint32 srcEid;
    bytes32 sender;
    uint64 nonce;
}

interface IERC20Like {
    function balanceOf(address a) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IEndpointV2 {
    function lzReceive(
        Origin calldata _origin,
        address _receiver,
        bytes32 _guid,
        bytes calldata _message,
        bytes calldata _extraData
    ) external payable;

    function inboundPayloadHash(
        address _receiver,
        uint32 _srcEid,
        bytes32 _sender,
        uint64 _nonce
    ) external view returns (bytes32);

    function lazyInboundNonce(
        address _receiver,
        uint32 _srcEid,
        bytes32 _sender
    ) external view returns (uint64);
}

interface IRSETHOFTAdapter {
    function peers(uint32 eid) external view returns (bytes32);
    function owner() external view returns (address);
    function token() external view returns (address);
}
