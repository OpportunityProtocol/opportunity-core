// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IEscrow {
    /**
     * @notice Initializes funds from a relationship based on the relationship id and stores evidence pointer.
     * @param _relationshipID The id of the relationship to access
     * @param _metaevidence IPFS pointer to evidence as specifiec by EIP1479. (Evidence standard)
     */
    function initialize(uint256 _relationshipID, string calldata _metaevidence)
        external;

    /**
     * @notice Releases escrow funds to the worker of a relationship.
     * @param _relationshipID The id of the relationship to access
     * @param _amount The amount of funds to release.
     */
    function releaseFunds(uint256 _amount, uint256 _relationshipID) external;

    /**
     * @notice Releases escrow funds back to the employer of a relationship.
     * @param _relationshipID The id of the relationship to access
     */
    function surrenderFunds(uint256 _relationshipID) external;
}
