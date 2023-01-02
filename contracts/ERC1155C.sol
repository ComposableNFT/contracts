//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./IERC1155C.sol";
import "./IERC721C.sol";

abstract contract ERC1155C is ERC1155, IERC1155C {
    using Address for address;

    // Mapping from token to attached quantity
    mapping(uint256 => mapping(address => uint256))
        private _totalAttachedQuantity;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC1155)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155C).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155C-getAttachedTokensQuantity}.
     */
    function getAttachedTokensQuantity(address owner, uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _totalAttachedQuantity[tokenId][owner];
    }

    /**
     * @dev See {IERC1155C-attach}.
     */
    function attach(
        address owner,
        uint256 tokenId,
        uint256 amount,
        address erc721cAddr,
        uint256 erc721cId
    ) public virtual override {
        IERC721C _erc721c = IERC721C(erc721cAddr);
        require(
            erc721cAddr.isContract() &&
                _erc721c.supportsInterface(type(IERC721C).interfaceId) &&
                erc721cAddr == _msgSender(),
            "ERC1155C: callable only by an ERC721C"
        );
        require(
            balanceOf(owner, tokenId) >=
                _totalAttachedQuantity[tokenId][owner] + amount,
            "ERC1155C: unavailable tokens to attach"
        );
        _totalAttachedQuantity[tokenId][owner] += amount;
        emit Attach(owner, tokenId, amount, erc721cAddr, erc721cId);
    }

    /**
     * @dev See {IERC1155C-detach}.
     */
    function detach(
        address owner,
        uint256 tokenId,
        uint256 amount,
        address erc721cAddr,
        uint256 erc721cId
    ) public virtual override {
        IERC721C _erc721c = IERC721C(erc721cAddr);
        require(
            erc721cAddr.isContract() &&
                _erc721c.supportsInterface(type(IERC721C).interfaceId) &&
                erc721cAddr == _msgSender(),
            "ERC1155C: caller must be an ERC721C"
        );
        _totalAttachedQuantity[tokenId][owner] -= amount;
        emit Detach(owner, tokenId, amount, erc721cAddr, erc721cId);
    }

    /**
     * @dev See {IERC1155C-attachedSafeBatchTransferFrom}.
     */
    function attachedSafeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data,
        address erc721cAddr,
        uint256 erc721cId
    ) public virtual override {
        IERC721C _erc721c = IERC721C(erc721cAddr);
        require(
            erc721cAddr.isContract() &&
                _erc721c.supportsInterface(type(IERC721C).interfaceId) &&
                erc721cAddr == _msgSender(),
            "ERC1155C: callable only by an ERC721C"
        );
        for (uint256 i = 0; i < ids.length; i++) {
            detach(from, ids[i], amounts[i], erc721cAddr, erc721cId);
        }
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; i++) {
            attach(to, ids[i], amounts[i], erc721cAddr, erc721cId);
        }
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        if (from != address(0)) {
            for (uint256 i = 0; i < ids.length; i++) {
                require(
                    (balanceOf(from, ids[i]) -
                        _totalAttachedQuantity[ids[i]][from]) >= amounts[i],
                    "ERC1155C: not enough tokens"
                );
            }
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
