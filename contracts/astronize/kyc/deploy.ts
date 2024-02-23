import { ethers } from "hardhat";

async function main() {

const adminAddress = '0x0428f16731624CD90b8aeca0f904b506728197FB' //admin contract address

const KYCBitkubChainV2 = await ethers.getContractFactory("KYCBitkubChainV2"); // Lock ชื่อ contract d
const kycBitkubChainV2 = await KYCBitkubChainV2.deploy(adminAddress);

  await kycBitkubChainV2.deployed();

  console.log(`deployed to ${kycBitkubChainV2.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
