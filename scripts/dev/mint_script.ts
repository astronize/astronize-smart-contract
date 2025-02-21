import { ethers } from "hardhat";

async function main() {
 
  /* TSXFANMEET */
  const nftAddress = "0x605B476b2de53513fC112a363B050055D63f56aa"
  const NFTHandler = await ethers.getContractFactory("TSXZODIAC");
  const nftHandler = NFTHandler.attach(
    nftAddress 
  );
  
  //prepar data
  // var tokenList = new Array(); 
  // var ipfsList = new Array(); 

  // for (let i = 324; i <= 326; i++) {
  //   tokenList.push(i)
  //   ipfsList.push("https://bitkubipfs.io/ipfs/QmS71irTJUhGf5C5Sca2U9poJshfYF7VE7rL2uSq9mJ2R4")
  // }

  // let test = await nftHandler.mintWithMetadataBatch("0xF627287E77439B3169ebCEC399Bd5f6Aee3c94c3", ipfsList, tokenList)

  // ======

  var tokenList = new Array(16,17); 
  var ipfsList = new Array(); 

  tokenList.forEach(()=> {
    ipfsList.push("https://bitkubipfs.io/ipfs/QmPk1uLrnEJhXqs48oik8QDZGYxvAwF4i31hwyRKNWE3S2")

  })

  let test = await nftHandler.mintWithMetadataBatch("0xf4A9AaaBc92501FA818190552aE3c7E4a3F306f5", ipfsList, tokenList)

  // ======
  console.log(`result to ${test}`);
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
npx hardhat run mint_script.ts --network bitkub

*/