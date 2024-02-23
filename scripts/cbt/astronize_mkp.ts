import { ethers } from "hardhat";

async function main() {
 
  // init constructor value
  const callHelperAddress = "0xF8FC0E21F21dbb25a23C930E4761Fc19212362cc" //bitkub deploy
  const kyc = "0x611D8D4f3743307c73cfa1A0C80F6F89C0950ef5" //manual deploy
  const acceptedKycLevel = 0 //default 
  const nextTransferRouterAddress = "0x3Ddf950176AD0ab4A3De258dCe6B7f0F0c763567" //manual deploy
  const nextNFTTransferRouterAddress = "0xbe152D81077bD3dA5C0243545aD530ac9e617A7a" //manual deploy
  
  const treasuryAddress = "0xf4A9AaaBc92501FA818190552aE3c7E4a3F306f5"
  const nftResaleHandlerAddress = "0x898D122268343e2A29d33E03Ac46e7796ce1537c"
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


  /* ==== manual step ====
    * 1. allow contract address(addAddress func) ที่ NextTransferRouter (0x3ddf950176ad0ab4a3de258dce6b7f0f0c763567)
    * 2. allow contract address(addAddress func) ที่ NextNFTTransferRouter (0xbe152d81077bd3da5c0243545ad530ac9e617a7a)
    * 3. KAP721TransferRouter allow (0x8c951bd556816d4d31ce2246b0a1946e0e8169af)
    * 4. add token whitelist
    * 5. add nft whitelist
    * 6. resale grantRole MKP_ROLE(0xc72925e6daa2c313e7b8aae82a9e85bf595bfe554e8fe978954087f638a5a249) (0x898D122268343e2A29d33E03Ac46e7796ce1537c)
    * 7. set bitkub whitelist (RestAPI)
  */

  const tokenAddress = "0x270e298eE53948Bb8012076C6e679BD5d3449c57" //ast token
  const tsxNftAddress = "0xB674192e553b493325Ca243d789804BC0e48AA07" //tsx nft
  const AdminKAP20RouterAddress = "0x8C951bD556816D4d31Ce2246B0A1946e0E8169aF" //tsx nft
  const project = "astronize"

  await astronizeMarketplace.setWhitelistCurrencyToken(tokenAddress, true)
  await astronizeMarketplace.setWhitelistNFTToken(tsxNftAddress, true)

  /* allow contract address(addAddress func) */
  const NextTransferRouter = await ethers.getContractFactory("NextTransferRouter");
  const nextTransferRouter = NextTransferRouter.attach(
    nextTransferRouterAddress 
  );
  await nextTransferRouter.addAddress(project, astronizeMarketplace.address)

  /* allow contract address(addAddress func) */
  const NextNFTTransferRouter = await ethers.getContractFactory("NextNFTTransferRouter");
  const nextNFTTransferRouter = NextNFTTransferRouter.attach(
    nextNFTTransferRouterAddress 
  );
  await nextNFTTransferRouter.addAddress(project, astronizeMarketplace.address)

  /* KAP721TransferRouter (addAddress) */
  const AdminKAP20Router = await ethers.getContractFactory("AdminKAP20Router");
  const adminKAP20Router = AdminKAP20Router.attach(
    AdminKAP20RouterAddress 
  );
  await adminKAP20Router.addAddress(astronizeMarketplace.address)
  
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
cd /Users/jirapongpangbud/Documents/go-workspace/src/astronize-smart-contract/scripts
nvm use v18.16.0
npx hardhat run dev/astronize_mkp.ts --network bitkub
npx hardhat flatten ../contracts/astronize/astronize_mkp.sol > ../flatten/astronize_mkp.sol

*/