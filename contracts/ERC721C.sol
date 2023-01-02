//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";
import "./IERC721C.sol";
import "./IERC1155C.sol";

abstract contract ERC721C is ERC721, IERC721C {
    // Max attachable components quantity
    uint256 private _maxComponentsQnt;

    // Quantity of attached components
    uint256 private _attachedComponentsQnt;

    // Declaration of struct that maps components of specific contract
    struct ContractComponents {
        uint256[] ids;
        uint256[] amounts;
        mapping(uint256 => uint256) idsIndex;
        uint256 contractsIndex;
        mapping(uint256 => uint256) components;
    }

    // Declaration of struct that maps components
    struct Components {
        address[] contracts;
        mapping(address => ContractComponents) contractComponents;
    }

    // Mapping from tokens to its components
    mapping(uint256 => Components) private _components;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection
     * and the max attachable quantity to each token.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 maxComponentsQnt
    ) ERC721(name, symbol) {
        _maxComponentsQnt = maxComponentsQnt;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC721C).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721C-attachComponent}.
     */
    function attachComponent(
        uint256 tokenId,
        address erc1155cAddr,
        uint256 erc1155cId,
        uint256 erc1155cAmount
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721C: caller is not token owner or approved"
        );
        if (_maxComponentsQnt > 0) {
            require(
                _attachedComponentsQnt + erc1155cAmount <= _maxComponentsQnt,
                "ERC721C: max components quantity exceded"
            );
        }
        IERC1155C _erc1155c = IERC1155C(erc1155cAddr);
        require(
            _erc1155c.supportsInterface(type(IERC1155C).interfaceId),
            "ERC721C: token must implement IERC1155C"
        );
        _beforeAttachComponent(
            tokenId,
            erc1155cAddr,
            erc1155cId,
            erc1155cAmount
        );

        Components storage components = _components[tokenId];
        ContractComponents storage contractComponents = components
            .contractComponents[erc1155cAddr];

        if (contractComponents.components[erc1155cId] == 0) {
            if (contractComponents.ids.length == 0) {
                contractComponents.contractsIndex = components.contracts.length;
                components.contracts.push(erc1155cAddr);
            }
            contractComponents.idsIndex[erc1155cId] = contractComponents
                .ids
                .length;
            contractComponents.ids.push(erc1155cId);
            contractComponents.amounts.push(erc1155cAmount);
        } else {
            contractComponents.components[
                contractComponents.idsIndex[erc1155cId]
            ] =
                contractComponents.components[
                    contractComponents.idsIndex[erc1155cId]
                ] +
                erc1155cAmount;
        }
        contractComponents.components[erc1155cId] =
            contractComponents.components[erc1155cId] +
            erc1155cAmount;
        _attachedComponentsQnt += erc1155cAmount;
        _erc1155c.attach(
            _msgSender(),
            erc1155cId,
            erc1155cAmount,
            address(this),
            tokenId
        );
        _afterAttachComponent(
            tokenId,
            erc1155cAddr,
            erc1155cId,
            erc1155cAmount
        );
    }

    /**
     * @dev See {IERC721C-detachComponent}.
     */
    function detachComponent(
        uint256 tokenId,
        address erc1155cAddr,
        uint256 erc1155cId,
        uint256 erc1155cAmount
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721C: caller is not token owner or approved"
        );
        Components storage components = _components[tokenId];
        require(
            components.contractComponents[erc1155cAddr].components[
                erc1155cId
            ] >= erc1155cAmount,
            "ERC721C: amount greater then attached amount"
        );
        IERC1155C _erc1155c = IERC1155C(erc1155cAddr);
        require(
            _erc1155c.supportsInterface(type(IERC1155C).interfaceId),
            "ERC721C: token must implement IERC1155C"
        );
        if (
            components.contractComponents[erc1155cAddr].components[
                erc1155cId
            ] == erc1155cAmount
        ) {
            if (components.contractComponents[erc1155cAddr].ids.length == 1) {
                components.contracts[
                    components.contractComponents[erc1155cAddr].contractsIndex
                ] = components.contracts[components.contracts.length - 1];
                components
                    .contractComponents[
                        components.contracts[
                            components
                                .contractComponents[erc1155cAddr]
                                .contractsIndex
                        ]
                    ]
                    .contractsIndex = components
                    .contractComponents[erc1155cAddr]
                    .contractsIndex;
                delete components
                    .contractComponents[erc1155cAddr]
                    .contractsIndex;
                components.contracts.pop();
            }
            components.contractComponents[erc1155cAddr].ids[
                components.contractComponents[erc1155cAddr].idsIndex[erc1155cId]
            ] = components.contractComponents[erc1155cAddr].ids[
                components.contractComponents[erc1155cAddr].ids.length - 1
            ];
            components.contractComponents[erc1155cAddr].amounts[
                components.contractComponents[erc1155cAddr].idsIndex[erc1155cId]
            ] = components.contractComponents[erc1155cAddr].amounts[
                components.contractComponents[erc1155cAddr].amounts.length - 1
            ];
            components.contractComponents[erc1155cAddr].idsIndex[
                components.contractComponents[erc1155cAddr].ids[
                    components.contractComponents[erc1155cAddr].idsIndex[
                        erc1155cId
                    ]
                ]
            ] = components.contractComponents[erc1155cAddr].idsIndex[
                erc1155cId
            ];
            delete components.contractComponents[erc1155cAddr].idsIndex[
                erc1155cId
            ];
            components.contractComponents[erc1155cAddr].ids.pop();
            components.contractComponents[erc1155cAddr].amounts.pop();
            components.contractComponents[erc1155cAddr].components[
                    erc1155cId
                ] -= erc1155cAmount;
        } else {
            components.contractComponents[erc1155cAddr].components[
                    erc1155cId
                ] -= erc1155cAmount;
            components.contractComponents[erc1155cAddr].amounts[
                components.contractComponents[erc1155cAddr].idsIndex[erc1155cId]
            ] =
                components.contractComponents[erc1155cAddr].amounts[
                    components.contractComponents[erc1155cAddr].idsIndex[
                        erc1155cId
                    ]
                ] -
                erc1155cAmount;
        }
        _attachedComponentsQnt -= erc1155cAmount;
        _erc1155c.detach(
            _msgSender(),
            erc1155cId,
            erc1155cAmount,
            address(this),
            tokenId
        );
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
        require(batchSize == 1, "ERC721C: batch transfer not supported");
        IERC1155C _erc1155c;
        for (uint256 i = 0; i < _components[firstTokenId].contracts.length; i++) {
            _erc1155c = IERC1155C(_components[firstTokenId].contracts[i]);
            _erc1155c.attachedSafeBatchTransferFrom(
                from,
                to,
                _components[firstTokenId]
                    .contractComponents[_components[firstTokenId].contracts[i]]
                    .ids,
                _components[firstTokenId]
                    .contractComponents[_components[firstTokenId].contracts[i]]
                    .amounts,
                "",
                address(this),
                firstTokenId
            );
        }
    }

    /**
     * @dev See {IERC721-getComponentsContracts}.
     */
    function getComponentsContracts(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address[] memory)
    {
        return _components[tokenId].contracts;
    }

    /**
     * @dev See {IERC721-getComponents}.
     */
    function getComponents(uint256 tokenId, address erc1155cAddr)
        public
        view
        virtual
        override
        returns (uint256[][2] memory)
    {
        return [
            _components[tokenId].contractComponents[erc1155cAddr].ids,
            _components[tokenId].contractComponents[erc1155cAddr].amounts
        ];
    }

    /**
     * @dev See {IERC721-getComponentAmount}.
     */
    function getComponentAmount(
        uint256 tokenId,
        address erc1155cAddr,
        uint256 erc1155cId
    ) public view virtual override returns (uint256) {
        return
            _components[tokenId].contractComponents[erc1155cAddr].components[
                erc1155cId
            ];
    }

    /**
     * @dev Hook that is called before any component attachment.
     */
    function _beforeAttachComponent(
        uint256 tokenId,
        address erc1155cAddr,
        uint256 erc1155cId,
        uint256 erc1155cAmount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any component attachment.
     */
    function _afterAttachComponent(
        uint256 tokenId,
        address erc1155cAddr,
        uint256 erc1155cId,
        uint256 erc1155cAmount
    ) internal virtual {}
}
