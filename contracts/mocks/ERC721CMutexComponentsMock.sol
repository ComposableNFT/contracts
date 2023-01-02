//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../extensions/ERC721CMutexComponents.sol";

contract ERC721CMutexComponentsMock is ERC721CMutexComponents, Ownable {
    string private _tokenURI;

    constructor(string memory tokenURI_) ERC721C("TestERC721C", "TERC721C", 0) {
        _tokenURI = tokenURI_;
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

    function setMutexComponents(Component[][] memory components)
        public
        onlyOwner
    {
        super._setMutexComponents(components);
    }

    function getMutexComponents()
        public
        view
        returns (Component[][] memory)
    {
        return _getMutexComponents();
    }
}
