import chai, {expect} from "chai";

import { ethers } from "hardhat";
import { BigNumber, Signer } from "ethers";
import { assert } from "chai";
import { solidity } from "ethereum-waffle";

import UniswapV2FactoryArtifact from "@uniswap/v2-core/build/UniswapV2Factory.json"
import UniswapV2RouterArtifact from "@uniswap/v2-periphery/build/UniswapV2Router02.json"
import WETH9Artifact from "@uniswap/v2-periphery/build/WETH9.json"

const { constants } = ethers;
const { MaxUint256 } = constants;

chai.use(solidity);

function expectRevert(condition: any, message: string): void {
    expect(condition).to.revertedWith(message);
}

function unixTimestamp(): number {
    return Math.round(Date.now()/1000)
}

describe("FeeRedistributor", function () {
    let accounts: Signer[];

    let OWNER_SIGNER: any;
    let STAKER_SIGNER: any;
    let HOLDERS_SIGNER: any;
    let ALICE_SIGNER: any;

    let OWNER: any;
    let STAKER: any;
    let HOLDERS: any;
    let ALICE: any;

    let alm: any;
    let feeRedistributor: any;

    let weth: any;
    let factory: any;
    let router: any;
    let multicall: any;

    before("config", async () => {
        accounts = await ethers.getSigners();

        OWNER_SIGNER = accounts[0];
        STAKER_SIGNER = accounts[1];
        HOLDERS_SIGNER = accounts[2];
        ALICE_SIGNER = accounts[3];
        OWNER = await OWNER_SIGNER.getAddress();
        STAKER = await STAKER_SIGNER.getAddress();
        HOLDERS = await HOLDERS_SIGNER.getAddress();
        ALICE = await ALICE_SIGNER.getAddress();

        const AliumToken = await ethers.getContractFactory("AliumToken");
        const FeeRedistributor = await ethers.getContractFactory("FeeRedistributor");
        const Multicall = await ethers.getContractFactory("Multicall");

        const UniswapFactory = await ethers.getContractFactory(UniswapV2FactoryArtifact.abi, UniswapV2FactoryArtifact.bytecode);
        const UniswapRouter = await ethers.getContractFactory(UniswapV2RouterArtifact.abi, UniswapV2RouterArtifact.bytecode);
        const WETH9 = await ethers.getContractFactory(WETH9Artifact.abi, WETH9Artifact.bytecode);

        multicall = await Multicall.deploy()
        await multicall.deployed()

        alm = await AliumToken.deploy(OWNER);
        await alm.deployed()

        weth = await WETH9.deploy()
        await weth.deployed()

        factory = await UniswapFactory.deploy(OWNER)
        await factory.deployed()

        router = await UniswapRouter.deploy(factory.address, weth.address)
        await router.deployed()

        const swapInfo = {
            router: router.address,
            alium: alm.address,
            deflationary: true
        }
        const recipients = [
            {
                account: STAKER,
                share: 50,
                mode: 0
            },
            {
                account: HOLDERS,
                share: 50,
                mode: 1
            },
        ]

        feeRedistributor = await FeeRedistributor.deploy(
            swapInfo,
            recipients
        );
    });

    describe('General', () => {
        before(async () => {
            await alm.disableAllFees()
            await alm.mint(OWNER, '1000000000000')
            await alm.approve(router.address, MaxUint256)
            await router.addLiquidityETH(
                alm.address,
                "1000000000000",
                "0",
                "1000000000000",
                OWNER,
                unixTimestamp() + 1000,
                { value: "1000000000000"}
            )

            await alm.connect(ALICE_SIGNER).approve(router.address, MaxUint256)
        })

        beforeEach(async () => {

        })

        it('#release', async () => {
            // send token
            await alm.mint(feeRedistributor.address, '100000')

            let balanceBefore = await multicall.getEthBalance(HOLDERS)

            // release
            try {
                await expect(feeRedistributor.release())
                    .to.emit(feeRedistributor, "ErrorHandled")
                    .withArgs("xxx");
            } catch (e: any) {
                console.log(e.message)
            }

            assert.equal(Number(await feeRedistributor.errorsCounter()), 0, "Errors detected")

            assert.equal(String(await alm.balanceOf(STAKER)), '50000', 'Staker balance')

            let balanceAfter = await multicall.getEthBalance(HOLDERS)
            assert.notEqual(String(balanceAfter), String(balanceBefore), 'Holders balance equal?')

            console.log(balanceAfter.toString())
            console.log(balanceBefore.toString())
            assert.isAtLeast(Number(balanceAfter), Number(balanceBefore), 'Holders balance')

            assert.equal(Number(await alm.balanceOf(feeRedistributor.address)), 0, "ALM not zero")
            assert.equal(Number(await multicall.getEthBalance(feeRedistributor.address)), 0, "ETH not zero")
        })

    })
})