import { ethers } from "hardhat";

async function main() {

const adminProjectAddress = '0x0428f16731624CD90b8aeca0f904b506728197FB'
const KAP721TransferRouter = await ethers.getContractFactory("KAP721TransferRouter"); // Lock ชื่อ contract d
const transferRouter = await KAP721TransferRouter.deploy(adminProjectAddress);

  await transferRouter.deployed();

  console.log(`deployed to ${transferRouter.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
