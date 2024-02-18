import { ethers } from "hardhat";
const {

  isBytesLike,
  isBytes,

  arrayify,

  concat,

  stripZeros,
  zeroPad,

  isHexString,
  hexlify,

  hexDataLength,
  hexDataSlice,
  hexConcat,

  hexValue,

  hexStripZeros,
  hexZeroPad,

  splitSignature,
  joinSignature,

  // Types

  Bytes,
  BytesLike,

  DataOptions,

  Hexable,

  SignatureLike,
  Signature

} = require("@ethersproject/bytes");
async function main() {

  const ownerWalletAddress = '0xf4A9AaaBc92501FA818190552aE3c7E4a3F306f5'

  
  //deploy ownerAccessControl
  const OwnerAccessControl = await ethers.getContractFactory("OwnerAccessControl"); // Lock ชื่อ contract d
  const ownerAccessControl = await OwnerAccessControl.deploy(ownerWalletAddress, ethers.utils.formatBytes32String("test"));

  await ownerAccessControl.deployed();
  console.log(`ownerAccessControl deployed to ${ownerAccessControl.address}`);


  //deploy OwnerAccessControlRouter
  const OwnerAccessControlRouter = await ethers.getContractFactory("OwnerAccessControlRouter"); // Lock ชื่อ contract d
  const ownerAccessControlRouter = await OwnerAccessControlRouter.deploy(ownerAccessControl.address);

  await ownerAccessControlRouter.deployed();



  console.log(`OwnerAccessControlRouter deployed to ${ownerAccessControlRouter.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
