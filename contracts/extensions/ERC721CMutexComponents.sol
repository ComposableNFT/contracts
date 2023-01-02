//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../ERC721C.sol";

abstract contract ERC721CMutexComponents is ERC721C {
    // Struct that represents a component
    struct Component {
        address addr;
        uint256 id;
    }

    // Array that define which component are mutually exclusive
    Component[][] private _mutexComponents;

    // Mapping from tokens to indexes of the array of `_mutexComponents`
    mapping(address => mapping(uint256 => uint256[2])) private _indexes;

    /**
     * @dev Return the array `_mutexComponents`.
     */
    function _getMutexComponents()
        internal
        view
        returns (Component[][] memory)
    {
        return _mutexComponents;
    }

    /**
     * @dev Set `_mutexComponents`.
     */
    function _setMutexComponents(Component[][] memory components)
        internal
        virtual
    {
        for (uint256 i = 0; i < _mutexComponents.length; i++) {
            for (uint256 j = 0; j < _mutexComponents[i].length; j++) {
                delete _indexes[_mutexComponents[i][j].addr][
                    _mutexComponents[i][j].id
                ];
            }
        }
        delete _mutexComponents;
        for (uint256 i = 0; i < components.length; i++) {
            _mutexComponents.push();
            for (uint256 j = 0; j < components[i].length; j++) {
                require(
                    _indexes[components[i][j].addr][components[i][j].id][1] ==
                        0,
                    "ERC721CMutexComponents: components must be unique"
                );
                _mutexComponents[i].push();
                _mutexComponents[i][j] = Component(
                    components[i][j].addr,
                    components[i][j].id
                );
                _indexes[components[i][j].addr][components[i][j].id][0] = i;
                _indexes[components[i][j].addr][components[i][j].id][1] = 1;
            }
        }
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
            _indexes[erc1155cAddr][erc1155cId][1] > 0,
            "ERC721CMutexComponents: component not compatible"
        );
        require(
            erc1155cAmount == 1,
            "ERC721CMutexComponents: component must be unique"
        );
        uint256 indexContainingToken = _indexes[erc1155cAddr][erc1155cId][0];
        address[] memory componentsContracts = getComponentsContracts(tokenId);
        for (uint256 k = 0; k < componentsContracts.length; k++) {
            uint256[][2] memory components = getComponents(
                tokenId,
                componentsContracts[k]
            );
            for (uint256 i = 0; i < components[0].length; i++) {
                for (
                    uint256 j = 0;
                    j < _mutexComponents[indexContainingToken].length;
                    j++
                ) {
                    require(
                        componentsContracts[k] !=
                            _mutexComponents[indexContainingToken][j].addr ||
                            components[0][i] !=
                            _mutexComponents[indexContainingToken][j].id,
                        "ERC721CMutexComponents: token or mutex token already attached"
                    );
                }
            }
        }
    }
}
