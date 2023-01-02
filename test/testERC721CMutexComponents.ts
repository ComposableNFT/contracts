import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ERC721CMutexComponentsMock, ERC1155CMock } from "../typechain";
import { BigNumber } from "ethers";

let erc721c: ERC721CMutexComponentsMock;
let erc1155c: ERC1155CMock;
let signers: SignerWithAddress[];
let owner: SignerWithAddress;
let acc1: SignerWithAddress;
let acc2: SignerWithAddress;

export const testERC721CMutexComponents = () => {
    before(async function () {
        // init contracts
        const ERC721C = await ethers.getContractFactory(
            "ERC721CMutexComponentsMock"
        );
        const ERC1155C = await ethers.getContractFactory("ERC1155CMock");
        erc721c = await ERC721C.deploy("IPFS_URL");
        erc1155c = await ERC1155C.deploy("IPFS_URL");
        await erc721c.deployed();
        await erc1155c.deployed();

        // init accounts
        signers = await ethers.getSigners();
        owner = signers[0];
        acc1 = signers[1];
        acc2 = signers[2];
    });

    describe("ERC721CMutexComponents", function () {
        it("Should mint", async function () {
            await erc721c.safeMint(owner.address, 1);
            const tokens = [
                [1, 2, 3, 4],
                [1, 2, 2, 1],
            ];
            await erc1155c.mintBatch(owner.address, tokens[0], tokens[1], []);
            expect(await erc721c.ownerOf(1)).to.be.equal(owner.address);
            const cerc1155BalanceOfBatch = await erc1155c.balanceOfBatch(
                [owner.address, owner.address, owner.address],
                [1, 2, 3]
            );
            expect(cerc1155BalanceOfBatch[0]).to.equal(1);
            expect(cerc1155BalanceOfBatch[1]).to.equal(2);
            expect(cerc1155BalanceOfBatch[2]).to.equal(2);
        });

        it("Should fail to set mutex components, components are not unique", async function () {
            await expect(
                erc721c.setMutexComponents([
                    [
                        { addr: erc1155c.address, id: 1 },
                        { addr: erc1155c.address, id: 2 },
                    ],
                    [
                        { addr: erc1155c.address, id: 2 },
                        { addr: erc1155c.address, id: 3 },
                        { addr: erc1155c.address, id: 4 },
                    ],
                ])
            ).to.be.revertedWith(
                "ERC721CMutexComponents: components must be unique"
            );
        });

        it("Should set mutex components", async function () {
            await erc721c.setMutexComponents([
                [
                    { addr: erc1155c.address, id: 1 },
                    { addr: erc1155c.address, id: 2 },
                ],
                [
                    { addr: erc1155c.address, id: 3 },
                    { addr: erc1155c.address, id: 4 },
                ],
            ]);
            const mutexComponents = await erc721c.getMutexComponents();
            expect(mutexComponents[0][0].addr).to.be.equal(erc1155c.address);
            expect(mutexComponents[0][0].id).to.be.equal(1);
        });

        it("Should approve ERC721C contract", async function () {
            await erc1155c.setApprovalForAll(erc721c.address, true);
            expect(
                await erc1155c.isApprovedForAll(owner.address, erc721c.address)
            ).to.be.true;
        });

        it("Should attach a component", async function () {
            await erc721c.attachComponent(1, erc1155c.address, 1, 1);
            expect(await erc721c.getComponentsContracts(1)).to.deep.equal([
                erc1155c.address,
            ]);
            expect(
                await erc721c.getComponents(1, erc1155c.address)
            ).to.deep.equal([[BigNumber.from(1)], [BigNumber.from(1)]]);
            expect(
                await erc1155c.getAttachedTokensQuantity(owner.address, 1)
            ).to.be.equal(1);
        });

        it("Should fail to attach, mutual exclusive token is already attached", async function () {
            await expect(
                erc721c.attachComponent(1, erc1155c.address, 2, 1)
            ).to.be.revertedWith(
                "ERC721CMutexComponents: token or mutex token already attached"
            );
        });

        it("Should attach a second token", async function () {
            await erc721c.attachComponent(1, erc1155c.address, 3, 1);
            expect(await erc721c.getComponentsContracts(1)).to.deep.equal([
                erc1155c.address,
            ]);
            expect(
                await erc721c.getComponents(1, erc1155c.address)
            ).to.deep.equal([
                [BigNumber.from(1), BigNumber.from(3)],
                [BigNumber.from(1), BigNumber.from(1)],
            ]);
            expect(
                await erc1155c.getAttachedTokensQuantity(owner.address, 1)
            ).to.be.equal(1);
            expect(
                await erc1155c.getAttachedTokensQuantity(owner.address, 3)
            ).to.be.equal(1);
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
            expect(cerc1155BalanceOfBatch[0]).to.equal(0);
            expect(cerc1155BalanceOfBatch[1]).to.equal(2);
            expect(cerc1155BalanceOfBatch[2]).to.equal(1);
            expect(cerc1155BalanceOfBatch[3]).to.equal(1);
            expect(cerc1155BalanceOfBatch[4]).to.equal(0);
            expect(cerc1155BalanceOfBatch[5]).to.equal(1);

            expect(await erc721c.getComponentsContracts(1)).to.deep.equal([
                erc1155c.address,
            ]);
            expect(
                await erc721c.getComponents(1, erc1155c.address)
            ).to.deep.equal([
                [BigNumber.from(1), BigNumber.from(3)],
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

        it("Should detach a second component from a composable", async function () {
            await erc721c
                .connect(acc1)
                .detachComponent(1, erc1155c.address, 3, 1);
            expect(
                (await erc721c.getComponentsContracts(1)).length
            ).to.be.equal(0);
            expect(
                (await erc721c.getComponents(1, erc1155c.address))[0].length
            ).to.be.equal(0);
            expect(
                (await erc721c.getComponents(1, erc1155c.address))[1].length
            ).to.be.equal(0);
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

        it("Should attach two components", async function () {
            await erc1155c.mintBatch(acc1.address, [1, 2, 3], [2, 2, 2], []);
            await erc721c
                .connect(acc1)
                .attachComponent(1, erc1155c.address, 1, 1);
            await erc721c
                .connect(acc1)
                .attachComponent(1, erc1155c.address, 3, 1);
        });

        it("Should reset mutex components", async function () {
            await erc721c.setMutexComponents([
                [
                    { addr: erc1155c.address, id: 1 },
                    { addr: erc1155c.address, id: 2 },
                    { addr: erc1155c.address, id: 3 },
                    { addr: erc1155c.address, id: 4 },
                    { addr: erc1155c.address, id: 5 },
                    { addr: erc1155c.address, id: 6 },
                    { addr: erc1155c.address, id: 7 },
                    { addr: erc1155c.address, id: 8 },
                ],
                [
                    { addr: erc1155c.address, id: 9 },
                    { addr: erc1155c.address, id: 10 },
                    { addr: erc1155c.address, id: 11 },
                    { addr: erc1155c.address, id: 12 },
                    { addr: erc1155c.address, id: 13 },
                    { addr: erc1155c.address, id: 14 },
                    { addr: erc1155c.address, id: 15 },
                    { addr: erc1155c.address, id: 16 },
                ],
                [
                    { addr: erc1155c.address, id: 17 },
                    { addr: erc1155c.address, id: 18 },
                    { addr: erc1155c.address, id: 19 },
                    { addr: erc1155c.address, id: 20 },
                    { addr: erc1155c.address, id: 21 },
                    { addr: erc1155c.address, id: 22 },
                    { addr: erc1155c.address, id: 23 },
                    { addr: erc1155c.address, id: 24 },
                ],
                [
                    { addr: erc1155c.address, id: 25 },
                    { addr: erc1155c.address, id: 26 },
                    { addr: erc1155c.address, id: 27 },
                    { addr: erc1155c.address, id: 28 },
                    { addr: erc1155c.address, id: 29 },
                    { addr: erc1155c.address, id: 30 },
                    { addr: erc1155c.address, id: 31 },
                    { addr: erc1155c.address, id: 32 },
                ],
                [
                    { addr: erc1155c.address, id: 33 },
                    { addr: erc1155c.address, id: 34 },
                    { addr: erc1155c.address, id: 35 },
                    { addr: erc1155c.address, id: 36 },
                    { addr: erc1155c.address, id: 37 },
                    { addr: erc1155c.address, id: 38 },
                    { addr: erc1155c.address, id: 39 },
                    { addr: erc1155c.address, id: 40 },
                ],
                [
                    { addr: erc1155c.address, id: 41 },
                    { addr: erc1155c.address, id: 42 },
                    { addr: erc1155c.address, id: 43 },
                    { addr: erc1155c.address, id: 44 },
                    { addr: erc1155c.address, id: 45 },
                    { addr: erc1155c.address, id: 46 },
                    { addr: erc1155c.address, id: 47 },
                    { addr: erc1155c.address, id: 48 },
                ],
            ]);
            const mutexComponents = await erc721c.getMutexComponents();
            expect(mutexComponents[0][1].addr).to.be.equal(erc1155c.address);
            expect(mutexComponents[0][1].id).to.be.equal(2);
        });

        it("Should detach one of the two non-compatible component", async function () {
            await erc721c
                .connect(acc1)
                .detachComponent(1, erc1155c.address, 3, 1);
        });

        it("Should fail to attach, mutual exclusive token is already attached", async function () {
            await expect(
                erc721c.connect(acc1).attachComponent(1, erc1155c.address, 3, 1)
            ).to.be.revertedWith(
                "ERC721CMutexComponents: token or mutex token already attached"
            );
        });
    });
};
