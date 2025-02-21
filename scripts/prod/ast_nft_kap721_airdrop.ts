import { ethers } from "hardhat";

async function main() {
 
  const name  = "TSX Badouyao NFT"
  const symbol  = "YAOTSX"
  const baseURI = ""
  const projectName = "bitkub-next-nft"
  const kyc = "0x409CF41ee862Df7024f289E9F2Ea2F5d0D7f3eb4" 
  const adminProjectRouter = "0x15122c945763da4435b45E082234108361B64eBA"  
  const committee = "0x5106ffca7cC44E6cFfEE9bD016A0934130b0322f"
  const KAP721TransferRouter = "0x5730c80A769122859D23fc68b052F307Bc8555fE" //KAP721TransferRouter
  const acceptedKycLevel = 4 //default 

  const AstronizeAirdropNFTKAP721 = await ethers.getContractFactory("TSXBadouyaoNFT"); 
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
cd /Users/jirapongpangbud/Documents/go-workspace/src/astronize-smart-contract/scripts
nvm use v18.16.0
npx hardhat run ast_nft_kap721_airdrop.ts --network bitkubMainnet
npx hardhat flatten ../contracts/astronize/TSXBadouyaoNFT.sol > ../flatten/TSXBadouyaoNFT.sol
*/
