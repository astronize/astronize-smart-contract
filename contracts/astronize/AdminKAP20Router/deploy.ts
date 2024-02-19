import { ethers } from "hardhat";

async function main() {

const adminProjectAddress = '0x0428f16731624CD90b8aeca0f904b506728197FB'
const committee = '0xf4A9AaaBc92501FA818190552aE3c7E4a3F306f5'
const KKUB = '0x1de8a5c87d421f53ee4ae398cc766e62e88e9518'
const kyc = "0x611D8D4f3743307c73cfa1A0C80F6F89C0950ef5" //manual deploy
const acceptedKycLevel = 4 //default 

const AdminKAP20Router = await ethers.getContractFactory("AdminKAP20Router"); // Lock ชื่อ contract d
const adminKAP20Router = await AdminKAP20Router.deploy(adminProjectAddress, committee, KKUB, kyc, acceptedKycLevel);

  await adminKAP20Router.deployed();

  console.log(`deployed to ${adminKAP20Router.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
