import { ethers } from "hardhat";

async function main() {
 
  /* TSXFANMEET */
  const nftAddress = "0x253296b6ED276D66E8c13d06B5bDCD69a16c0618"
  const NFTHandler = await ethers.getContractFactory("TSXZODIAC");
  const nftHandler = NFTHandler.attach(
    nftAddress 
  );
  
  //prepar data
  var tokenList = new Array(); 
  var ipfsList = new Array(); 

  // 2405-2500
  // 2501-2600
  // 2601-2700
  // 2701-2737
  // for (let i = 2405; i <= 2500; i++) {
  // for (let i = 2501; i <= 2600; i++) {
  // for (let i = 2601; i <= 2700; i++) {
  for (let i = 2701; i <= 2737; i++) {
    tokenList.push(i)
    ipfsList.push("https://bitkubipfs.io/ipfs/QmSk1Laipspd9pA64KV6Wx6r7mpmr4ffP2QKtKedU6Sd5t")
  }

  let test = await nftHandler.mintWithMetadataBatch("0xba0905132ccd7dca87b8b5876fd81f160e59869b", ipfsList, tokenList)

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
cd /Users/jirapongpangbud/Documents/go-workspace/src/astronize-smart-contract/scripts/prod
nvm use v18.16.0
npx hardhat run mint_script.ts --network bitkubMainnet

*/