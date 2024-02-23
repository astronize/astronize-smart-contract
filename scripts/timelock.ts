import { ethers } from "hardhat";

async function main() {
  
  const admin = "0xf4A9AaaBc92501FA818190552aE3c7E4a3F306f5";
  const delay = 6*60*60;

  const Timelock = await ethers.getContractFactory("Timelock"); 
  const timelock = await Timelock.deploy(
    admin,
    delay
  );


   /* AstronizeMarketplace */ 
   const AstronizeMarketplaceAddress = "0xF58857357d42160cD0a83f6719Db6db045747EaE" 
  
   const MKP_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000"
   const AstronizeMarketplace = await ethers.getContractFactory("AstronizeMarketplace");
   const astronizeMarketplace = AstronizeMarketplace.attach(
    AstronizeMarketplaceAddress 
   );
 
   await astronizeMarketplace.grantRole(MKP_ADMIN_ROLE, timelock.address)

  /* AstronizeNFTBridge */ 
  const AstronizeNFTBridgeAddress = "0x6FB076Eb7c8908fc2798d4d92BD66121EA52C7Bd" 

  const NFTBridge_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000"
  const MINTER_ROLE = "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6"
  const AstronizeNFTBridge = await ethers.getContractFactory("AstronizeNFTBridge");
  const astronizeNFTBridge = AstronizeNFTBridge.attach(
    AstronizeNFTBridgeAddress 
  );

  await astronizeNFTBridge.grantRole(NFTBridge_ADMIN_ROLE, timelock.address)
  await astronizeNFTBridge.grantRole(MINTER_ROLE, timelock.address)

  /* ownerAccessControl */
  const ownerAccessControlAddress = "0xB59ABD01761B011B4Af24c2D6Efb5930F834968A" //tsx nft
  const roleOwner = "0x6270edb7c868f86fda4adedba75108201087268ea345934db8bad688e1feb91b"
  const roleBurner = "0x9667e80708b6eeeb0053fa0cca44e028ff548e2a9f029edfeac87c118b08b7c8"
  const roleMinter = "0xf0887ba65ee2024ea881d91b74c2450ef19e1557f03bed3ea9f16b037cbe2dc9"

   /* ให้สิทธิ์การ mint, burn, owner nft */
   const OwnerAccessControl = await ethers.getContractFactory("OwnerAccessControl");
   const ownerAccessControl = OwnerAccessControl.attach(
     ownerAccessControlAddress 
   );
 
   await ownerAccessControl.grantRole(roleOwner, timelock.address)
   await ownerAccessControl.grantRole(roleBurner, timelock.address)
   await ownerAccessControl.grantRole(roleMinter, timelock.address)

   
  console.log(`deployed to ${timelock.address}`);
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
npx hardhat run timelock.ts --network bitkub
npx hardhat flatten ../contracts/astronize/time_lock.sol > ../flatten/time_lock.sol

*/