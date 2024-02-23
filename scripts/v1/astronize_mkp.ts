import { ethers } from "hardhat";

async function main() {
 
  // init constructor value
  const callHelperAddress = "0xF8FC0E21F21dbb25a23C930E4761Fc19212362cc" //bitkub deploy
  const kyc = "0x611D8D4f3743307c73cfa1A0C80F6F89C0950ef5" //manual deploy
  const acceptedKycLevel = 0 //default 
  const nextTransferRouter = "0x3Ddf950176AD0ab4A3De258dCe6B7f0F0c763567" //manual deploy
  const nextNFTTransferRouter = "0xbe152D81077bD3dA5C0243545aD530ac9e617A7a" //manual deploy
  
  const treasuryAddress = "0xf4A9AaaBc92501FA818190552aE3c7E4a3F306f5"
  const fee = 500 //2deci
  const minimumSalePrice = 100000000000000 //0.001, 18deci

  const AstronizeMarketplace = await ethers.getContractFactory("AstronizeMarketplace"); // Lock ชื่อ contract
  const astronizeMarketplace = await AstronizeMarketplace.deploy(
    callHelperAddress,
    kyc,
    acceptedKycLevel,
    nextTransferRouter, 
    nextNFTTransferRouter, 
    treasuryAddress,
    fee,
    minimumSalePrice
    );


  /* ==== manual step ====
    * 1. allow contract address(addAddress func) ที่ NextTransferRouter (0x3ddf950176ad0ab4a3de258dce6b7f0f0c763567)
    * 2. allow contract address(addAddress func) ที่ NextNFTTransferRouter (0xbe152d81077bd3da5c0243545ad530ac9e617a7a)
    * 3. KAP721TransferRouter allow (0x8c951bd556816d4d31ce2246b0a1946e0e8169af)
  */



  console.log(`deployed to ${astronizeMarketplace.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});


/*
run script
cd /Users/jirapongpangbud/Documents/go-workspace/src/astronize-smart-contract/scripts
nvm use v18.16.0
npx hardhat run v1/astronize_mkp.ts --network bitkub
npx hardhat flatten ../contracts/astronize/v1/astronize_mkp.sol > ../flatten/astronize_mkp.sol

*/