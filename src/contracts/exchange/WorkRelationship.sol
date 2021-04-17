// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./interface/IWorkRelationshipERC721.sol";

contract WorkRelationship is ERC721, ERC721Pausable, ERC721Burnable {

    event WorkRelationshipMetadataChange();

    uint256 private _relationshipID;
    
    // Mapping from token ID to requesters
    mapping(uint256 => string) private _requesters;
    
    // Mapping from token ID to redeemers
    mapping(uint256 => string) private _redeemers;

    constructor() ERC721("Work Relationship V1", "WRV1") {}

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}
