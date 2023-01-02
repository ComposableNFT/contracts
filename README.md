# Composable NFT

## Introduction

An architecture for composing ERC721 tokens with ERC1155 tokens by adding extensions to these already widely used standards.

## Architecture

To implement composability two extensions have been developed that add public methods to ERC721 and ERC1155 standards, so that ERC1155 Component (ERC1155C) tokens can be attached to ERC721 Composable (ERC721C) tokens.<br />
The new methods are:

-   ERC721C:
    -   [`getComponentsContracts`](/contracts/IERC721C.sol#L32) -> view
    -   [`getComponents`](/contracts/IERC721C.sol#L41) -> view
    -   [`getComponentAmount`](/contracts/IERC721C.sol#L49) -> view
    -   [`attachComponent`](/contracts/IERC721C.sol#L67) -> write
    -   [`detachComponent`](/contracts/IERC721C.sol#L84) -> write

-   ERC1155C:
    -   [`getAttachedTokensQuantity`](/contracts/IERC1155C.sol#L32) -> view
    -   [`attachedSafeBatchTransferFrom`](/contracts/IERC1155C.sol#L44) -> write
    -   [`attach`](/contracts/IERC1155C.sol#L64) -> write
    -   [`detach`](/contracts/IERC1155C.sol#L83) -> write

To manage composability devs need to use only the write methods on the ERC721C: `attachComponent` and `detachComponent`.
All the three write methods in the ERC1155C extension are callable only by an instance of an ERC721C contract instance:

-   `attach` is called by `attachComponent`
-   `detach` is called by `detachComponent`
-   `attachedSafeBatchTransferFrom` is called when a composable NFT is transferred

When an ERC721C token is transferred, all the attached ERC1155C tokens will be transferred too, so the ERC721C contract needs to be approved otherwise the transfer transaction gets reverted. ERC1155C tokens cannot be transferred alone if attached.

ERC721C constructor requires `uint256 maxComponentsQnt` as additional argument to define the quantity of components that a composable NFT can support, it can be set to `0` for no limit, but it is not recommended.

## Composable NFT Extensions

The base implementation does not define limits on which components can be attached, some extensions have been developed to cover general cases:

-   `ERC721CUniqueComponents`
-   `ERC721CCompatibleContracts`
-   `ERC721CMutexComponents`

### ERC721CUniqueComponents

This extension ensures that all attached components are unique.

### ERC721CCompatibleContracts

This extension limits attachable components to specific ERC1155C contracts.
Compatible contracts can be managed with the two methods:

-   `_addCompatibleContracts(address[] memory contracts)`
-   `_removeCompatibleContracts(address[] memory contracts)`

### ERC721CMutexComponents

This extension ensures mutual exclusivity between components. Configuration can be set using the method `_setMutexComponents(Component[][] memory components)`.

Only components set with `_setMutexComponents` can be attached to this type of composable NFT and they must be unique.

`Component` is defined as:

```js
struct Component {
    address addr;
    uint256 id;
}
```

where `addr` is the ERC1155C contract address and `id` is the token id.

The argument `components` is an array of arrays of `Component` where the internal ones are lists of mutually exclusive components.

Gas consumption of `_setMutexComponents` grows proportionally with the length of the argument `components`.

## Application examples

- Avatars:
    - ERC721C -> Base avatar
    - ERC1155C -> Clothes, accessories, weapons, etc...

- Cars:
    - ERC721C -> Chassis
    - ERC1155C -> Engines, wheels, transmissions, etc...

- Boxes:
    - ERC721C -> Token Box
    - ERC1155C -> Any token  

- Houses:
    - ERC721C -> Building
    - ERC1155C -> Furnitures

## Examples

Examples on how to use these contracts can be found [here](/contracts/mocks) and [here](/test).