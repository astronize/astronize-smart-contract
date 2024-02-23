import { ethers } from "hardhat";

async function main() {
 
  const kyc = "0x611D8D4f3743307c73cfa1A0C80F6F89C0950ef5" //manual deploy
  // const adminKAP20Router = "0x8c951bd556816d4d31ce2246b0a1946e0e8169af" //adminProject ผิด ใช้ 0x0428f16731624CD90b8aeca0f904b506728197FB แทน
  const adminKAP20Router = "0x0428f16731624CD90b8aeca0f904b506728197FB"
  const committee = "0xf4A9AaaBc92501FA818190552aE3c7E4a3F306f5"
  const acceptedKycLevel = 0//default 

  const AstronizeToken = await ethers.getContractFactory("ASTToken"); 
  const astronizeToken = await AstronizeToken.deploy(
    adminKAP20Router,
    committee,
    kyc,
    acceptedKycLevel
    );


  console.log(`deployed to ${astronizeToken.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
