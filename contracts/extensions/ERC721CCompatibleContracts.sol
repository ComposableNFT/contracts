//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "../ERC721C.sol";

abstract contract ERC721CCompatibleContracts is IERC165, ERC721C {
    // Array of compatible contracts
    address[] private _contracts;

    // Mapping from compatible contract addresses to indexes in `_contracts` array
    mapping(address => uint256[2]) private _indexes;

    /**
     * @dev Add compatible contracts.
     */
    function _addCompatibleContracts(address[] memory contracts)
        internal
        virtual
    {
        for (uint256 i = 0; i < contracts.length; i++) {
            if (_indexes[contracts[i]][1] == 0) {
                _indexes[contracts[i]] = [_contracts.length, 1];
                _contracts.push(contracts[i]);
            }
        }
    }

    /**
     * @dev Remove compatible contracts.
     */
    function _removeCompatibleContracts(address[] memory contracts)
        internal
        virtual
    {
        for (uint256 i = 0; i < contracts.length; i++) {
            if (_indexes[contracts[i]][1] == 1) {
                _contracts[_indexes[contracts[i]][0]] = _contracts[
                    _contracts.length - 1
                ];
                _indexes[_contracts[_contracts.length - 1]] = _indexes[
                    contracts[i]
                ];
                _indexes[contracts[i]] = [0, 0];
                _contracts.pop();
            }
        }
    }

    /**
     * @dev Return compatible contracts.
     */
    function _getCompatibleContracts()
        internal
        view
        virtual
        returns (address[] memory)
    {
        return _contracts;
    }

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
            _indexes[erc1155cAddr][1] > 0,
            "ERC721CCompatibleContracts: contract not compatible"
        );
    }
}
