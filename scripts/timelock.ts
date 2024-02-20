import { ethers } from "hardhat";

async function main() {
  
  const admin = "0xf4A9AaaBc92501FA818190552aE3c7E4a3F306f5";
  const delay = 6*60*60;

  const Timelock = await ethers.getContractFactory("Timelock"); 
  const timelock = await Timelock.deploy(
    admin,
    delay
  );


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