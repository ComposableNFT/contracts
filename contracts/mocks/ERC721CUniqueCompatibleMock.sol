//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../extensions/ERC721CCompatibleContracts.sol";
import "../extensions/ERC721CUniqueComponents.sol";

contract ERC721CUniqueCompatibleMock is
    ERC721CCompatibleContracts,
    ERC721CUniqueComponents,
    Ownable
{
    string private _tokenURI;

    constructor(string memory tokenURI_) ERC721C("TestERC721C", "TERC721C", 0) {
        _tokenURI = tokenURI_;
    }

    function addCompatibleContracts(address[] memory contracts)
        public
        onlyOwner
    {
        _addCompatibleContracts(contracts);
    }

    function getCompatibleContracts() public view returns (address[] memory) {
        return _getCompatibleContracts();
    }

    function _beforeAttachComponent(
        uint256 tokenId,
        address erc1155cAddr,
        uint256 erc1155cId,
        uint256 erc1155cAmount
    )
        internal
        virtual
        override(ERC721CUniqueComponents, ERC721CCompatibleContracts)
    {
        super._beforeAttachComponent(
            tokenId,
            erc1155cAddr,
            erc1155cId,
            erc1155cAmount
        );
    }

    function setTokenURI(string memory tokenURI_) public onlyOwner {
        _tokenURI = tokenURI_;
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "token does not exist");
        return _tokenURI;
    }
}
