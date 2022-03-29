import hre from "hardhat";
const ethers = hre.ethers;

async function main() {
    const [owner] = await ethers.getSigners();
    console.log(owner.address)

    const AliumToken = await hre.ethers.getContractFactory("AliumToken");
    const SuperALM = await hre.ethers.getContractFactory("SuperALM");

    const alm = await AliumToken.deploy(owner.address)
    await alm.deployed()

    const superAlm = await SuperALM.deploy(alm.address)
    await superAlm.deployed()

    console.log("New Alium token deployed to:", alm.address);
    console.log("Super ALM deployed to:", superAlm.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });