import chai, {expect} from "chai";

import { ethers } from "hardhat";
import {BigNumber, Signer} from "ethers";
import { assert } from "chai";
import { solidity } from "ethereum-waffle";

const { constants } = ethers;
const { MaxUint256 } = constants;

chai.use(solidity);

function expectRevert(condition: any, message: string) {
    expect(condition).to.revertedWith(message);
}

describe("AliumToken", function () {
    const SYSTEM_DECIMAL = 10000;
    const DEV_FEE = 500;
    const BURN_FEE = 500;

    let accounts: Signer[];

    let OWNER_SIGNER: any;
    let DEV_SIGNER: any;
    let ALICE_SIGNER: any;
    let BOB_SIGNER: any;

    let OWNER: any;
    let DEV: any;
    let ALICE: any;
    let BOB: any;

    let alm: any;

    before("config", async () => {
        accounts = await ethers.getSigners();

        OWNER_SIGNER = accounts[0];
        DEV_SIGNER = accounts[1];
        ALICE_SIGNER = accounts[2];
        BOB_SIGNER = accounts[3];

        OWNER = await OWNER_SIGNER.getAddress();
        DEV = await DEV_SIGNER.getAddress();
        ALICE = await ALICE_SIGNER.getAddress();
        BOB = await BOB_SIGNER.getAddress();

        const AliumToken = await ethers.getContractFactory("AliumToken");

        alm = await AliumToken.deploy(DEV);
    });

    afterEach(async () => {
        await alm.connect(OWNER_SIGNER).burn(await alm.balanceOf(OWNER))
        await alm.connect(DEV_SIGNER).burn(await alm.balanceOf(DEV))
        await alm.connect(ALICE_SIGNER).burn(await alm.balanceOf(ALICE))
        await alm.connect(BOB_SIGNER).burn(await alm.balanceOf(BOB))
    })

    describe('AliumToken mutable methods', () => {

        beforeEach(async () => {
            await alm.connect(OWNER_SIGNER).mint(OWNER, '100000000000000000000000')
        })

        it('#transfer', async () => {
            let mintedBalance = await alm.balanceOf(OWNER)
            assert.equal(String(await alm.balanceOf(OWNER)), String(mintedBalance), "Before balance")
            let transferred = BigNumber.from(1)
            await alm.transfer(ALICE, transferred);
            assert.equal(String(await alm.balanceOf(OWNER)), String(mintedBalance.sub(transferred)), "After balance SENDER")
            assert.equal(String(await alm.balanceOf(ALICE)), String(transferred), "After balance RECEIVER")
        })


        it('#transfer with deflation', async () => {
            let mintedBalance = await alm.balanceOf(OWNER)
            assert.equal(String(await alm.balanceOf(OWNER)), String(mintedBalance), "Before balance")
            let transferred = BigNumber.from(1000000000000)
            await alm.transfer(ALICE, transferred);
            assert.equal(String(await alm.balanceOf(OWNER)), String(mintedBalance.sub(transferred)), "After balance SENDER")
            assert.equal(String(await alm.balanceOf(ALICE)), String(transferred.div(100).mul(90)), "After balance RECEIVER")
            assert.equal(String(await alm.balanceOf(DEV)), String(transferred.div(100).mul(5)), "After balance DEV")
            let output = await alm.estimateOutput(OWNER, ALICE, 1000000000000);
            assert.equal(String(output.amountOut), String(transferred.div(100).mul(90)), "#amountOut")
            assert.equal(String(output.excluded), String(transferred.div(100).mul(10)), "#excluded")
        })

        it('#transferFrom with deflation', async () => {
            let mintedBalance = await alm.balanceOf(OWNER)
            assert.equal(String(await alm.balanceOf(OWNER)), String(mintedBalance), "Before balance")
            let transferred = BigNumber.from(1000000000000)
            await alm.connect(OWNER_SIGNER).approve(ALICE, transferred);
            await alm.connect(ALICE_SIGNER).transferFrom(OWNER, ALICE, transferred);
            assert.equal(String(await alm.balanceOf(OWNER)), String(mintedBalance.sub(transferred)), "After balance SENDER")
            assert.equal(String(await alm.balanceOf(ALICE)), String(transferred.div(100).mul(90)), "After balance RECEIVER")
            assert.equal(String(await alm.balanceOf(DEV)), String(transferred.div(100).mul(5)), "After balance DEV")
            let output = await alm.estimateOutput(OWNER, ALICE, 1000000000000);
            assert.equal(String(output.amountOut), String(transferred.div(100).mul(90)), "#amountOut")
            assert.equal(String(output.excluded), String(transferred.div(100).mul(10)), "#excluded")
        })
    })

});