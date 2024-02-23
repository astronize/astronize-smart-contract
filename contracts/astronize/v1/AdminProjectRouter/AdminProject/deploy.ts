import { ethers } from "hardhat";

async function main() {
//   const callHelperContractAddress = '0xF8FC0E21F21dbb25a23C930E4761Fc19212362cc'
//   const _kyc = '' //
//   const _acceptedKycLevel = '4'
//   const _nextTransferRouterContractAddress = ''
  
//   const _nftAddress = ''
//   const _tokenAddress = ''
//   const _treasuryAddress = ''
  const rootAdminAddress = '0xf4A9AaaBc92501FA818190552aE3c7E4a3F306f5'


  const AdminProject = await ethers.getContractFactory("AdminProject"); // Lock ชื่อ contract

//   const adminProject = await AdminProject.deploy(
//     callHelperContractAddress, 
//     _kyc,
//     _acceptedKycLevel, 
//     _nextTransferRouterContractAddress, 
//     _nftAddress, 
//     _tokenAddress, 
//     _treasuryAddress);

const adminProject = await AdminProject.deploy(rootAdminAddress);

  await adminProject.deployed();

  console.log(`deployed to ${adminProject.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
