import { ethers } from "hardhat";

async function main() {
 
  const name  = "TSXFANMEET"
  const symbol  = "TSXFANMEET"
  const baseURI = ""
  const projectName = "astronize"
  const kyc = "0x611D8D4f3743307c73cfa1A0C80F6F89C0950ef5" 
  const adminProjectRouter = "0x0428f16731624CD90b8aeca0f904b506728197FB"  
  const committee = "0xf4A9AaaBc92501FA818190552aE3c7E4a3F306f5"
  const KAP721TransferRouter = "0xdAcEA798081A88F1F6848aDcee1e929cA715852b" //KAP721TransferRouter
  const acceptedKycLevel = 0 //default 

  const AstronizeAirdropNFTKAP721 = await ethers.getContractFactory("TSXFANMEET"); 
  const astronizeAirdropNFTKAP721 = await AstronizeAirdropNFTKAP721.deploy(
    name,
    symbol,
    baseURI,
    projectName,
    kyc,
    adminProjectRouter,
    committee,
    KAP721TransferRouter,
    acceptedKycLevel
    );


  console.log(`deployed to ${astronizeAirdropNFTKAP721.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});




/*
run script
cd /Users/jirapongpangbud/Documents/go-workspace/src/astronize-smart-contract/scripts/dev
nvm use v18.16.0
npx hardhat run ast_nft_kap721_TSXFANMEET.ts --network bitkub
npx hardhat flatten ../../contracts/astronize/TSXFANMEET.sol > ../../flatten/TSXFANMEET.sol
*/
