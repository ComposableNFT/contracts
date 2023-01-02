//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../ERC1155C.sol";

contract ERC1155CMock is ERC1155C, Ownable {
    constructor(string memory uri_) ERC1155(uri_) {}

    function setURI(string memory uri_) public onlyOwner {
        _setURI(uri_);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }
}
