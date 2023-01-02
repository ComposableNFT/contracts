//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721C is IERC721 {
    /**
     * @dev Emitted when component token `erc1155cId` of
     * contract `erc1155cAddr` get attached to token `tokenId`.
     */
    event AttachComponent(
        uint256 tokenId,
        address erc1155cAddr,
        uint256 erc1155cId,
        uint256 erc1155cAmount
    );

    /**
     * @dev Emitted when component token `erc1155cId` of
     * contract `erc1155cAddr` get detached to token `tokenId`.
     */
    event DetachComponent(
        uint256 tokenId,
        address erc1155cAddr,
        uint256 erc1155cId,
        uint256 erc1155cAmount
    );

    /**
     * @dev Returns contracts of components attached to `tokenId`.
     */
    function getComponentsContracts(uint256 tokenId)
        external
        view
        returns (address[] memory);

    /**
     * @dev Returns ids and amounts of components attached to `tokenId`
     * belonging to `erc1155cAddr`.
     */
    function getComponents(uint256 tokenId, address erc1155cAddr)
        external
        view
        returns (uint256[][2] memory);

    /**
     * @dev Returns the amount of attached components to `tokenId`.
     */
    function getComponentAmount(
        uint256 tokenId,
        address erc1155cAddr,
        uint256 erc1155cId
    ) external view returns (uint256);

    /**
     * @dev Attaches component token `erc1155cId` of contract `erc1155cAddr`
     * to composable token `tokenId`.
     *
     * Requirements:
     *
     * - Caller must be owner or approved operator.
     * - `erc1155cAddr` must be a contract implementing IERC1155C.
     * - `erc1155cId` of contract `erc1155cAddr` must exist.
     *
     * Emits a {AttachComponent} event.
     */
    function attachComponent(
        uint256 tokenId,
        address erc1155cAddr,
        uint256 erc1155cId,
        uint256 erc1155cAmount
    ) external;

    /**
     * @dev Detaches component token `erc1155cId` of contract `erc1155cAddr`
     * from composable token `tokenId`.
     *
     * Requirements:
     * - Caller must be owner or approved operator.
     * - `erc1155cId` of contract `erc1155cAddr` must be previously attached.
     *
     * Emits a {AttachComponent} event.
     */
    function detachComponent(
        uint256 tokenId,
        address erc1155cAddr,
        uint256 erc1155cId,
        uint256 erc1155cAmount
    ) external;
}
