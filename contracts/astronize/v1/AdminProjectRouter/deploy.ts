import { ethers } from "hardhat";

async function main() {

const adminProjectAddress = '0x611EC35AA3C2b9998035d6dbB4095C03cC46651c'
const AdminProjectRouter = await ethers.getContractFactory("AdminProjectRouter"); // Lock ชื่อ contract d
const adminProjectRouter = await AdminProjectRouter.deploy(adminProjectAddress);

  await adminProjectRouter.deployed();

  console.log(`deployed to ${adminProjectRouter.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
