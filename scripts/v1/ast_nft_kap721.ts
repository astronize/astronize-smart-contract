import { ethers } from "hardhat";

async function main() {
 
  const name  = "CrashOfThronesNFT"
  const symbol  = "COTNFT"
  const baseURI = "https://dev-api.astronize.com/cot/token/"
  const projectName = "astronize"
  const kyc = "0x611D8D4f3743307c73cfa1A0C80F6F89C0950ef5" //manual deploy
  const adminProjectRouter = "0x0428f16731624CD90b8aeca0f904b506728197FB"  //deploy router ใหม่ เพราะเหมือนจะ setup admin address ผิด
  const committee = "0xf4A9AaaBc92501FA818190552aE3c7E4a3F306f5"
  const KAP721TransferRouter = "0xdAcEA798081A88F1F6848aDcee1e929cA715852b" //KAP721TransferRouter
  const acceptedKycLevel = 0 //default 
  const ownerAccessControlRouter = "0x85bC9F9A9651e8087F7532A7aC0df00Cd39653F0"

  const AstronizeCouponNFTKAP721 = await ethers.getContractFactory("AstronizeCouponNFTKAP721"); 
  const astronizeCouponNFTKAP721 = await AstronizeCouponNFTKAP721.deploy(
    name,
    symbol,
    baseURI,
    projectName,
    kyc,
    adminProjectRouter,
    committee,
    KAP721TransferRouter,
    acceptedKycLevel,
    ownerAccessControlRouter
    );


  console.log(`deployed to ${astronizeCouponNFTKAP721.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
