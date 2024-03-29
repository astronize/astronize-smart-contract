import { ethers } from "hardhat";

async function main() {
 
  // init constructor value
  const callHelperAddress = "0xF8FC0E21F21dbb25a23C930E4761Fc19212362cc" //bitkub deploy
  
  const kyc = "0x611D8D4f3743307c73cfa1A0C80F6F89C0950ef5" //manual deploy
  // const kyc = "0x988bc9c05f0e0fbc198a5db0bd62ca90dc3e1b05" //bitkub eploy

  const acceptedKycLevel = 0 //default 
  const nextTransferRouterAddress = "0x3Ddf950176AD0ab4A3De258dCe6B7f0F0c763567" //manual deploy
  // const nextTransferRouter = "0xf3EAB4809D2c749EA09590dfa2DE24aeF8576f13" //bitkub deploy
  
  const tokenAddress = "0xaE66074Ff1fFdaDf96fCf3A031EccdB946b85824" //ast token
  const treasuryAddress = "0xf4A9AaaBc92501FA818190552aE3c7E4a3F306f5"


  const AstronizeNFTBridge = await ethers.getContractFactory("AstronizeNFTBridge"); // Lock ชื่อ contract
  const astronizeNFTBridge = await AstronizeNFTBridge.deploy(
    callHelperAddress,
    kyc,
    acceptedKycLevel,
     nextTransferRouterAddress, 
    
    tokenAddress,
    treasuryAddress
    );


  /* ==== manual step ====
    * 1. ให้สิทธิ์การ mint nft ที่ contract OwnerAccessControl (0xB59ABD01761B011B4Af24c2D6Efb5930F834968A)
        - role address 0xf0887ba65ee2024ea881d91b74c2450ef19e1557f03bed3ea9f16b037cbe2dc9, 0x9667e80708b6eeeb0053fa0cca44e028ff548e2a9f029edfeac87c118b08b7c8, 0x6270edb7c868f86fda4adedba75108201087268ea345934db8bad688e1feb91b
    * 2. grant validater address ที่ contract AstronizeNFTBridge (this) (0xB88D7e756428c886Ce4aD29E7ecAED17A994EDc2, 0xf4A9AaaBc92501FA818190552aE3c7E4a3F306f5, 0x4B7c4cc1818E110582940983e261E91d9a463b8D)
    * 3. allow contract address(addAddress func) ที่ NextTransferRouter (0x3ddf950176ad0ab4a3de258dce6b7f0f0c763567)
    * 4. allow nft address ที่อนุญาติให้ mint
    * 5. set bitkub whitelist (RestAPI)
  */

  const tsxNftAddress = "0x04Bbc463A0fCAa1073408115cfD4af2df0173B94" //tsx nft
  const ownerAccessControlAddress = "0xB59ABD01761B011B4Af24c2D6Efb5930F834968A" //tsx nft
  const project = "astronize"

  const validaterAddress_1 = "0xB88D7e756428c886Ce4aD29E7ecAED17A994EDc2" 
  const validaterAddress_2 = "0xf4A9AaaBc92501FA818190552aE3c7E4a3F306f5" 
  const validaterAddress_3 = "0x4B7c4cc1818E110582940983e261E91d9a463b8D" 

  const roleOwner = "0x6270edb7c868f86fda4adedba75108201087268ea345934db8bad688e1feb91b"
  const roleBurner = "0x9667e80708b6eeeb0053fa0cca44e028ff548e2a9f029edfeac87c118b08b7c8"
  const roleMinter = "0xf0887ba65ee2024ea881d91b74c2450ef19e1557f03bed3ea9f16b037cbe2dc9"

  /* allow nft address ที่อนุญาติให้ mint */
  await astronizeNFTBridge.setWhitelistNFTToken(tsxNftAddress, true)

  /* grant validater address */
  await astronizeNFTBridge.grantTrustedValidator(validaterAddress_1)
  await astronizeNFTBridge.grantTrustedValidator(validaterAddress_2)
  await astronizeNFTBridge.grantTrustedValidator(validaterAddress_3)

  /* allow contract address(addAddress func) ที่ NextTransferRouter */
  const NextTransferRouter = await ethers.getContractFactory("NextTransferRouter");
  const nextTransferRouter = NextTransferRouter.attach(
    nextTransferRouterAddress 
  );
  await nextTransferRouter.addAddress(project, astronizeNFTBridge.address)

  /* ให้สิทธิ์การ mint, burn, owner nft */
  const OwnerAccessControl = await ethers.getContractFactory("OwnerAccessControl");
  const ownerAccessControl = OwnerAccessControl.attach(
    ownerAccessControlAddress 
  );

  await ownerAccessControl.grantRole(roleOwner, astronizeNFTBridge.address)
  await ownerAccessControl.grantRole(roleBurner, astronizeNFTBridge.address)
  await ownerAccessControl.grantRole(roleMinter, astronizeNFTBridge.address)

  console.log(`deployed to ${astronizeNFTBridge.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});


/* how to run 

  //deploy
  nvm use v18.16.0
  cd /Users/jirapongpangbud/Documents/go-workspace/src/astronize-smart-contract/scripts
  npx hardhat run dev/astronize_nft_bridge.ts --network bitkub
  npx hardhat flatten ../contracts/astronize/astronize_nft_bridge.sol > ../flatten/astronize_nft_bridge.sol
*/