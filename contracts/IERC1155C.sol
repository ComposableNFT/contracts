//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IERC1155C is IERC1155 {
    /**
     * @dev Emitted when `tokenId` get attached to `erc721cId` of contract `erc721cAddr`.
     */
    event Attach(
        address owner,
        uint256 tokenId,
        uint256 amount,
        address erc721cAddr,
        uint256 erc721cId
    );

    /**
     * @dev Emitted when `tokenId` get detached from `erc721cId` of contract `erc721cAddr`.
     */
    event Detach(
        address owner,
        uint256 tokenId,
        uint256 amount,
        address erc721cAddr,
        uint256 erc721cId
    );

    /**
     * @dev Returns how many `tokenId` of `owner` are attached.
     */
    function getAttachedTokensQuantity(address owner, uint256 tokenId)
        external
        view
        returns (uint256);

    /**
     * @dev Same as {IERC1155-safeBatchTransferFrom} adding detaching/attaching functionalities.
     *
     * Requirements:
     * - Caller must be `erc721cAddr`.
     * - `erc721cAddr` must be a contract implementing IERC721C.
     */
    function attachedSafeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data,
        address erc721cAddr,
        uint256 erc721cId
    ) external;

    /**
     * @dev Attaches `tokenId` to `erc721cId` of contract `erc721cAddr`.
     *
     * Requirements:
     *
     * - `erc721cAddr` must be a contract implementing IERC721C.
     * - `owner` must have unattached `tokenId`.
     *
     * Emits a {Attach} event.
     */
    function attach(
        address owner,
        uint256 tokenId,
        uint256 amount,
        address erc721cAddr,
        uint256 erc721cId
    ) external;

    /**
     * @dev Detaches `tokenId` from `erc721cId` of contract `erc721cAddr`.
     *
     * Requirements:
     *
     * - Caller must be `erc721cAddr`.
     * - `erc721cAddr` must be a contract implementing IERC721C.
     * - `tokenId` must be previously attached.
     *
     * Emits a {Detach} event.
     */
    function detach(
        address owner,
        uint256 tokenId,
        uint256 amount,
        address erc721cAddr,
        uint256 erc721cId
    ) external;
}
