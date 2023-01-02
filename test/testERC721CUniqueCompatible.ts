import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ERC721CUniqueCompatibleMock, ERC1155CMock } from "../typechain";
import { BigNumber } from "ethers";

let erc721c: ERC721CUniqueCompatibleMock;
let erc1155c: ERC1155CMock;
let signers: SignerWithAddress[];
let owner: SignerWithAddress;
let acc1: SignerWithAddress;
let acc2: SignerWithAddress;

export const testERC721CUniqueCompatible = () => {
    before(async function () {
        // init contracts
        const ERC721C = await ethers.getContractFactory(
            "ERC721CUniqueCompatibleMock"
        );
        const ERC1155C = await ethers.getContractFactory("ERC1155CMock");
        erc721c = await ERC721C.deploy("IPFS_URI");
        erc1155c = await ERC1155C.deploy("IPFS_URI");
        await erc721c.deployed();
        await erc1155c.deployed();

        // init accounts
        signers = await ethers.getSigners();
        owner = signers[0];
        acc1 = signers[1];
        acc2 = signers[2];
    });

    describe("ERC721CUniqueCompatible", function () {
        it("Should mint", async function () {
            await erc721c.safeMint(owner.address, 1);
            await erc721c.safeMint(acc1.address, 2);
            const tokens = [
                [1, 2, 3],
                [3, 2, 2],
            ];
            await erc1155c.mintBatch(owner.address, tokens[0], tokens[1], []);
            expect(await erc721c.ownerOf(1)).to.be.equal(owner.address);
            const cerc1155BalanceOfBatch = await erc1155c.balanceOfBatch(
                [owner.address, owner.address, owner.address],
                [1, 2, 3]
            );
            expect(cerc1155BalanceOfBatch[0]).to.equal(3);
            expect(cerc1155BalanceOfBatch[1]).to.equal(2);
            expect(cerc1155BalanceOfBatch[2]).to.equal(2);
        });

        it("Should fail to attach a component to a composable because component contract is not compatible", async function () {
            await expect(
                erc721c.attachComponent(1, erc1155c.address, 1, 1)
            ).to.be.revertedWith(
                "ERC721CCompatibleContracts: contract not compatible"
            );
        });

        it("Should add a compatible contract", async function () {
            await erc721c.addCompatibleContracts([erc1155c.address]);
            expect(await erc721c.getCompatibleContracts()).deep.equal([
                erc1155c.address,
            ]);
        });

        it("Should fail to attach components to a composable because token must be unique", async function () {
            await expect(
                erc721c.attachComponent(1, erc1155c.address, 1, 2)
            ).to.be.revertedWith(
                "ERC721CUniqueComponents: components must be unique"
            );
        });

        it("Should attach a component to a composable", async function () {
            let tx = await erc721c.attachComponent(1, erc1155c.address, 1, 1);
            expect(await erc721c.getComponentsContracts(1)).to.deep.equal([
                erc1155c.address,
            ]);
            expect(
                await erc721c.getComponents(1, erc1155c.address)
            ).to.deep.equal([[BigNumber.from(1)], [BigNumber.from(1)]]);
            expect(
                await erc1155c.getAttachedTokensQuantity(owner.address, 1)
            ).to.be.equal(1);

            await erc721c.attachComponent(1, erc1155c.address, 2, 1);
            expect(
                await erc1155c.getAttachedTokensQuantity(owner.address, 2)
            ).to.be.equal(1);
        });

        it("Should fail to attach a component to a composable because token already attached", async function () {
            await expect(
                erc721c.attachComponent(1, erc1155c.address, 1, 2)
            ).to.be.revertedWith(
                "ERC721CUniqueComponents: components must be unique"
            );
        });

        it("Should fail to transfer because not approved", async function () {
            await expect(
                erc721c.transferFrom(owner.address, acc1.address, 1)
            ).to.be.revertedWith(
                "ERC1155: caller is not token owner or approved"
            );
        });

        it("Should approve ERC721C contract", async function () {
            await erc1155c.setApprovalForAll(erc721c.address, true);
            expect(
                await erc1155c.isApprovedForAll(owner.address, erc721c.address)
            ).to.be.true;
        });

        it("Should transfer a composable token", async function () {
            await erc721c.transferFrom(owner.address, acc1.address, 1);
            expect(await erc721c.ownerOf(1)).to.be.equal(acc1.address);
            const cerc1155BalanceOfBatch = await erc1155c.balanceOfBatch(
                [
                    owner.address,
                    owner.address,
                    owner.address,
                    acc1.address,
                    acc1.address,
                    acc1.address,
                ],
                [1, 2, 3, 1, 2, 3]
            );
            expect(cerc1155BalanceOfBatch[0]).to.equal(2);
            expect(cerc1155BalanceOfBatch[1]).to.equal(1);
            expect(cerc1155BalanceOfBatch[2]).to.equal(2);
            expect(cerc1155BalanceOfBatch[3]).to.equal(1);
            expect(cerc1155BalanceOfBatch[4]).to.equal(1);
            expect(cerc1155BalanceOfBatch[5]).to.equal(0);

            expect(await erc721c.getComponentsContracts(1)).to.deep.equal([
                erc1155c.address,
            ]);
            expect(
                await erc721c.getComponents(1, erc1155c.address)
            ).to.deep.equal([
                [BigNumber.from(1), BigNumber.from(2)],
                [BigNumber.from(1), BigNumber.from(1)],
            ]);
            expect(
                await erc1155c.getAttachedTokensQuantity(acc1.address, 1)
            ).to.be.equal(1);
        });

        it("Should detach a component from a composable", async function () {
            await erc721c
                .connect(acc1)
                .detachComponent(1, erc1155c.address, 1, 1);
            expect(
                (await erc721c.getComponentsContracts(1)).length
            ).to.be.equal(1);
        });

        it("Should trasfer a component", async function () {
            await erc1155c
                .connect(acc1)
                .safeBatchTransferFrom(
                    acc1.address,
                    acc2.address,
                    [1],
                    [1],
                    []
                );
            expect(await erc1155c.balanceOf(acc1.address, 1)).to.be.equal(0);
            expect(await erc1155c.balanceOf(acc2.address, 1)).to.be.equal(1);
        });
    });
};
