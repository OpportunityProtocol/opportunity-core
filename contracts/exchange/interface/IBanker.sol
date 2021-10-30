interface IBanker {
    function supplyErc20ToCompound(
        address _erc20Contract,
        address _cErc20Contract,
        address _donor,
        uint256 _numTokensToSupply
    ) external returns (uint);
}