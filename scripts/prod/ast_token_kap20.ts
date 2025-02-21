import { ethers } from "hardhat";

async function main() {
 
  const name = "Astronize"
  const symbol = "AST"
  const projectName = "astronize"
  const decimals = 18
  const kyc = "0x409CF41ee862Df7024f289E9F2Ea2F5d0D7f3eb4"

  const adminProjectRouter = "0x15122c945763da4435b45E082234108361B64eBA"
  const transferRouter = "0xFbf5b70ef07AE6F64D3796f8a0fE83A3579FAb6f" //AdminKAP20Router / TransferRouter
  const ownerAccessControlRouter = "0xE38b683F08901434c4ee6581927acA5FbCE27427" 

  const committee = "0x5106ffca7cC44E6cFfEE9bD016A0934130b0322f"
  const acceptedKycLevel = 4

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
cd /Users/jirapongpangbud/Documents/go-workspace/src/astronize-smart-contract/scripts/prod
nvm use v18.16.0
npx hardhat run ast_token_kap20.ts --network bitkubMainnet
npx hardhat flatten ../contracts/astronize/ast_kap20.sol > ../flatten/ast_kap20.sol

*/