import chai, {expect} from "chai";

import { ethers } from "hardhat";
import { BigNumber, Signer } from "ethers";
import { assert } from "chai";
import { solidity } from "ethereum-waffle";

const { constants } = ethers;
const { MaxUint256 } = constants;

chai.use(solidity);

describe("SuperALM", function () {
    const BASIC_PRICE = 5e18;
    const REWARD = 1e18;

    let accounts: Signer[];

    let OWNER_SIGNER: any;
    let DEV_SIGNER: any;
    let ALICE_SIGNER: any;

    let OWNER: any;
    let DEV: any;
    let ALICE: any;

    let alm: any;
    let superALM: any;

    before("config", async () => {
        accounts = await ethers.getSigners();

        OWNER_SIGNER = accounts[0];
        DEV_SIGNER = accounts[1];
        ALICE_SIGNER = accounts[2];
        OWNER = await OWNER_SIGNER.getAddress();
        DEV = await DEV_SIGNER.getAddress();
        ALICE = await ALICE_SIGNER.getAddress();

        const AliumToken = await ethers.getContractFactory("AliumToken");
        const SuperALM = await ethers.getContractFactory("SuperALM");

        alm = await AliumToken.deploy(DEV);
        superALM = await SuperALM.deploy(alm.address);
    });

    describe('SuperALM mutable methods', () => {
        it('#mint', async () => {
            let mintAmount = await superALM.countMintPrice(1)
            await alm.mint(ALICE, mintAmount)
            await alm.connect(ALICE_SIGNER).approve(superALM.address, MaxUint256)
            await superALM.connect(ALICE_SIGNER).mint(1)
            assert.equal(String(await alm.balanceOf(ALICE)), String(0), "After balance ALM")
            assert.equal(String(await superALM.balanceOf(ALICE)), String(BigNumber.from(1).mul(BigNumber.from(10).pow(18))), "After balance sALM")
        })

        it('#burn', async () => {
            let aliceBalance = await superALM.balanceOf(ALICE);
            await superALM.connect(ALICE_SIGNER).burn(aliceBalance)
            assert.equal(String(await superALM.balanceOf(ALICE)), String(0), "After balance ALM")
        })
    })

});