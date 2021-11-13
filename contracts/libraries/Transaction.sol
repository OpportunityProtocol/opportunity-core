library Transaction {
    struct EIP712ERC20Permit {
        uint256 nonce;
        uint256 expiry;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
}