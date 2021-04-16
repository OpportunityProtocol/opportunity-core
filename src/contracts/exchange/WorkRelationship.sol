// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/ERC721/IERC721.sol";
import "@openzeppelin/contracts/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/ERC721/extensions/IERC721Metadata";
import "@openzeppelin/contracts/utils/Context.sol";

contract WorkRelationship is Context, IERC721, IERC721Receiver, IERC721Metadata {
    constructor() {}
}