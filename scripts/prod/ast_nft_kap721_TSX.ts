import { ethers } from "hardhat";

async function main() {
 
  const name  = "TSX by Astronize NFT"
  const symbol  = "TSXNFT"
  const baseURI = " "
  const projectName = "astronize"
  const kyc = "0x409CF41ee862Df7024f289E9F2Ea2F5d0D7f3eb4" //manual deploy
  const adminProjectRouter = "0x15122c945763da4435b45E082234108361B64eBA"  //deploy router ใหม่ เพราะเหมือนจะ setup admin address ผิด
  const committee = "0x5106ffca7cC44E6cFfEE9bD016A0934130b0322f"
  const KAP721TransferRouter = "0x5730c80A769122859D23fc68b052F307Bc8555fE" //KAP721TransferRouter
  const acceptedKycLevel = 4 //default 
  const ownerAccessControlRouter = "0xE38b683F08901434c4ee6581927acA5FbCE27427"

  const AstronizeCouponNFTKAP721 = await ethers.getContractFactory("AstronizeNFTKAP721"); 
  const astronizeCouponNFTKAP721 = await AstronizeCouponNFTKAP721.deploy(
    name,
    symbol,
    baseURI,
    projectName,
    kyc,
    adminProjectRouter,
    committee,
    KAP721TransferRouter,
    acceptedKycLevel,
    ownerAccessControlRouter
    );


  
  /* mainnet ไม่มีสิทธิ์ bitkub เป็นคนทำ */
  /* addToken */
  // const nextNFTTransferRouterAddress = "0x8659d7fe3ECd406966980aD255B8A970893DF6DB" //manual deploy
  // const project = "astronize"

  // const NextNFTTransferRouter = await ethers.getContractFactory("NextNFTTransferRouter");
  // const nextNFTTransferRouter = NextNFTTransferRouter.attach(
  //   nextNFTTransferRouterAddress 
  // );
  // await nextNFTTransferRouter.addAddress(project, astronizeCouponNFTKAP721.address)
  // await nextNFTTransferRouter.addToken(project, astronizeCouponNFTKAP721.address)

  console.log(`deployed to ${astronizeCouponNFTKAP721.address}`);
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
npx hardhat run ast_nft_kap721_TSX.ts --network bitkubMainnet
npx hardhat flatten ../../contracts/astronize/ast_nft_kap721.sol > ../../flatten/ast_nft_kap721.sol

*/