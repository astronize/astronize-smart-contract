import { ethers } from "hardhat";

async function main() {
  
  const adminProjectRouter = '0x0428f16731624CD90b8aeca0f904b506728197FB' //manual deploy
  const adminKAP20Router = '0x8C951bD556816D4d31Ce2246B0A1946e0E8169aF' //manual deploy
  const KKUB = '0x1de8a5c87d421f53ee4ae398cc766e62e88e9518'
  const committee = '0xf4A9AaaBc92501FA818190552aE3c7E4a3F306f5'
  const astTokenAddress = '0x61399b0561a87d90A9b0B7EFF36152722960B3c8'


  const NextTransferRouter = await ethers.getContractFactory("NextTransferRouter"); // Lock ชื่อ contract

  const nextTransferRouter = await NextTransferRouter.deploy(adminProjectRouter, adminKAP20Router, KKUB, committee, [astTokenAddress]);

  await nextTransferRouter.deployed();

  console.log(`deployed to ${nextTransferRouter.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
