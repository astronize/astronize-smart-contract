import { ethers } from "hardhat";

async function main() {
 
  // init constructor value
  const callHelperAddress = "0xF8FC0E21F21dbb25a23C930E4761Fc19212362cc" //bitkub deploy
  
  const kyc = "0x611D8D4f3743307c73cfa1A0C80F6F89C0950ef5" //manual deploy
  // const kyc = "0x988bc9c05f0e0fbc198a5db0bd62ca90dc3e1b05" //bitkub eploy

  const acceptedKycLevel = 0 //default 
  const nextTransferRouter = "0x3Ddf950176AD0ab4A3De258dCe6B7f0F0c763567" //manual deploy
  // const nextTransferRouter = "0xf3EAB4809D2c749EA09590dfa2DE24aeF8576f13" //bitkub deploy
  
  const nftAddress = "0x48a57978B08313BDD771E46dEAc7aEb7b7E75317"
  const tokenAddress = "0x301d9d566CDe621d76c800C27793e8F329B6DD66"
  const treasuryAddress = "0xf4A9AaaBc92501FA818190552aE3c7E4a3F306f5"



  const AstronizeCouponNFTBridge = await ethers.getContractFactory("AstronizeCouponNFTBridge"); // Lock ชื่อ contract
  const astronizeCouponNFTBridge = await AstronizeCouponNFTBridge.deploy(
    callHelperAddress,
    kyc,
    acceptedKycLevel,
    nextTransferRouter, 
    nftAddress, 
    tokenAddress,
    treasuryAddress
    );


  /* ==== manual step ====
    * 1. ให้สิทธิ์การ mint nft ที่ contract OwnerAccessControl (0xB59ABD01761B011B4Af24c2D6Efb5930F834968A)
        - role address 0xf0887ba65ee2024ea881d91b74c2450ef19e1557f03bed3ea9f16b037cbe2dc9, 0x9667e80708b6eeeb0053fa0cca44e028ff548e2a9f029edfeac87c118b08b7c8
    * 2. grant validater address ที่ contract astronize_conpon_nft_bridge_fee_incloud (this)
    * 3. allow contract address(addAddress func) ที่ NextTransferRouter (0x3ddf950176ad0ab4a3de258dce6b7f0f0c763567)
  */



  console.log(`deployed to ${astronizeCouponNFTBridge.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
