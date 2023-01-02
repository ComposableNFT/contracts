//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "../ERC721C.sol";

abstract contract ERC721CUniqueComponents is IERC165, ERC721C {
    /**
     * @dev See {ERC721C-_beforeAttachComponent}.
     */
    function _beforeAttachComponent(
        uint256 tokenId,
        address erc1155cAddr,
        uint256 erc1155cId,
        uint256 erc1155cAmount
    ) internal virtual override {
        super._beforeAttachComponent(
            tokenId,
            erc1155cAddr,
            erc1155cId,
            erc1155cAmount
        );
        require(
            erc1155cAmount == 1 &&
                getComponentAmount(tokenId, erc1155cAddr, erc1155cId) == 0,
            "ERC721CUniqueComponents: components must be unique"
        );
    }
}
