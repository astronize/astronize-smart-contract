import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-abi-exporter";

import dotenv from 'dotenv';
dotenv.config({ path: __dirname+'/.env' });

const privateKey1 = process.env.privateKey1; //0xf4A9AaaBc92501FA818190552aE3c7E4a3F306f5
const privateKey2 = process.env.privateKey2; //0xB88D7e756428c886Ce4aD29E7ecAED17A994EDc2
const privateKey3 = process.env.privateKey3; //0x4B7c4cc1818E110582940983e261E91d9a463b8D
const mainNet = process.env.mainNet; 

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.19",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.17",
      },
      {
        version: "0.8.13",
      },
      {
        version: "0.6.6",
      },
      {
        version: "0.6.12", 
      },
      {
        version: "0.8.9",
      },
      {
        version: "0.8.10",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      }
    ],
  },
  abiExporter: {
    path: './data/abi',
    runOnCompile: true,
    clear: true,
    flat: true,
    spacing: 2,
    pretty: false,
    except: [
      "IERC721",
      "AdminProject",
      "IAdmin",
      "IKAP20",
      "Pauseable",
      "Pausable",
      "Ownable",
      "KYCHandler",
      "INextTransferRouter",
      "INextSwapRouter",
      "KAP20",
      "INextNFTTransferRouter",
      "IKYCBitkubChain",
      "IKYC",
      "IKToken",
      "IKAP721",
      "IERC165",
      "ERC165",
      "IERC20Permit",
      "AccessControl",
      "IERC20",
      "IAccessControlEnumerable",
      "IAccessControl",
      "ERC721Holder",
      "ERC721Enumerable",
      "ERC721Burnable",
      "ERC721",
      "Blacklist",
      "Authorization",
      "Committee",
      "IKAP165",
      "KYCBitkubChainV2",
      "KAP165",
      "KAP721",
      "ASTToken",
      "KAP721TransferRouter",
      "INFTResaleHandler"
    ]
  },
  networks: {
    hardhat: {
    },
    bsc: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      accounts: [privateKey1]
      // accounts: [privateKey1, privateKey2]
    },
    bitkub: {
      url: "https://rpc-testnet.bitkubchain.io",
      accounts: [privateKey1]
    },
    bitkubMainnet: {
      url: "https://rpc.bitkubchain.io",
      accounts: [mainNet]
    }
  },
  
};

export default config;
