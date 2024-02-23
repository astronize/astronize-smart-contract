import { ethers } from "hardhat";

async function main() {

const adminProjectAddress = '0x0428f16731624CD90b8aeca0f904b506728197FB'

const _kap721TransferRouter = '0xdAcEA798081A88F1F6848aDcee1e929cA715852b'
const _kap1155TransferRouter = '0x0000000000000000000000000000000000000000'
const _committee = '0xf4A9AaaBc92501FA818190552aE3c7E4a3F306f5'

const NextNFTTransferRouter = await ethers.getContractFactory("NextNFTTransferRouter"); // Lock ชื่อ contract d


const nextNFTTransferRouter = await NextNFTTransferRouter.deploy(adminProjectAddress, _kap721TransferRouter, _kap1155TransferRouter, _committee);

  await nextNFTTransferRouter.deployed();

  console.log(`deployed to ${nextNFTTransferRouter.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
