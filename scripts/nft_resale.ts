import { ethers } from "hardhat";

async function main() {
  
  const NFTResaleHandler = await ethers.getContractFactory("NFTResaleHandler"); 
  const nftResaleHandler = await NFTResaleHandler.deploy();


  console.log(`deployed to ${nftResaleHandler.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});


  /* ==== manual step ====
    * 1. grantRole 0xc72925e6daa2c313e7b8aae82a9e85bf595bfe554e8fe978954087f638a5a249 ให้ MKP contract
  */



/*
run script
cd /Users/jirapongpangbud/Documents/go-workspace/src/astronize-smart-contract/scripts
nvm use v18.16.0
npx hardhat run nft_resale.ts --network bitkub
npx hardhat flatten ../contracts/astronize/v2/nft_resale.sol > ../flatten/nft_resale.sol

*/