import { ethers } from "hardhat";

async function main() {
 
  const name = "AstronizeTokenKAP20"
  const symbol = "ast"
  const projectName = "astronize"
  const decimals = 18
  const kyc = "0x2c8abd9c61d4e973ca8db5545c54c90e44a2445c"

  const adminProjectRouter = "0x16bafEAf79E6B21d111ACb2A36DD6DD18c8dCbD0"
  const transferRouter = "0x614d499a673ee3220758787572bf32872a5fe13b" //AdminKAP20Router / TransferRouter
  const ownerAccessControlRouter = "0x85bc9f9a9651e8087f7532a7ac0df00cd39653f0" 

  const committee = "0xf4A9AaaBc92501FA818190552aE3c7E4a3F306f5"
  const acceptedKycLevel = 0//default 

  const AstronizeToken = await ethers.getContractFactory("ASTTokenKAP20"); 
  const astronizeToken = await AstronizeToken.deploy(
    name,
    symbol,
    projectName,
    decimals,
    kyc,
    adminProjectRouter,
    committee,
    transferRouter,
    acceptedKycLevel,
    ownerAccessControlRouter
    );


  console.log(`deployed to ${astronizeToken.address}`);
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
npx hardhat run ast_token_kap20.ts --network bitkub
npx hardhat flatten ../contracts/astronize/ast_kap20.sol > ../flatten/ast_kap20.sol

*/