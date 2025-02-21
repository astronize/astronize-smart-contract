import { ethers } from "hardhat";

async function main() {
 
  // init constructor value
  const callHelperAddress = "0x0cD7048a3831E0475F9a8471C64e5b9a1e4e357E" //bitkub deploy
  const kyc = "0x409CF41ee862Df7024f289E9F2Ea2F5d0D7f3eb4" //manual deploy
  const acceptedKycLevel = 4 //default 
  const nextTransferRouterAddress = "0x2fd4562D69D5f3c396B7a487AF21C4f39774Ab76" //manual deploy
  const nextNFTTransferRouterAddress = "0x8659d7fe3ECd406966980aD255B8A970893DF6DB" //manual deploy
  
  const treasuryAddress = "0x93cfdBd25c1dC420ce52B9288A309E25F86F4a4d"
  const nftResaleHandlerAddress = "0x08082659382167ef7412a444af115F807425e5Ae"
  const fee = 500 //2deci
  const minimumSalePrice = 100000000000000 //0.001, 18deci

  const AstronizeMarketplace = await ethers.getContractFactory("AstronizeMarketplace"); // Lock ชื่อ contract
  const astronizeMarketplace = await AstronizeMarketplace.deploy(
    callHelperAddress,
    kyc,
    acceptedKycLevel,
    nextTransferRouterAddress, 
    nextNFTTransferRouterAddress, 
    treasuryAddress,
    fee,
    minimumSalePrice,
    nftResaleHandlerAddress
    );


  // const tokenAddress = "0xAfB090bAefdEadF31Ce2C075807a15841160e852" //ast token
  // const kkubAddress = "0x67eBD850304c70d983B2d1b93ea79c7CD6c3F6b5" //kkub token
  // const tsxNftAddress = "0x43506bCbC8308c28E04377D558260f1e71303F43" //tsx nft

  /* add token whitelist */
  // await astronizeMarketplace.setWhitelistCurrencyToken(tokenAddress, true)
  // await astronizeMarketplace.setWhitelistCurrencyToken(kkubAddress, true)
  /* add nft whitelist */
  // await astronizeMarketplace.setWhitelistNFTToken(tsxNftAddress, true)

  /* resale grantRole */
  const mkpRole = "0xc72925e6daa2c313e7b8aae82a9e85bf595bfe554e8fe978954087f638a5a249"
  const NFTResaleHandler = await ethers.getContractFactory("NFTResaleHandler");
  const nftResaleHandler = NFTResaleHandler.attach(
    nftResaleHandlerAddress 
  );
  await nftResaleHandler.grantRole(mkpRole, astronizeMarketplace.address)

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
cd /Users/jirapongpangbud/Documents/go-workspace/src/astronize-smart-contract/scripts/prod
nvm use v18.16.0
npx hardhat run astronize_mkp.ts --network bitkubMainnet
npx hardhat flatten ../../contracts/astronize/astronize_mkp.sol > ../../flatten/astronize_mkp.sol

*/