import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-abi-exporter";

const privateKey1 = "0xf52acb50a1e1ec0b3bc867d6621ce2ece52f0ab401cc6f94fdd8f92bb035b50e"
const privateKey2 = "763a5522e7f42ae48984df3c70adab250be4a5181cac03a311dc698c7f638cf3"

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.19",
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
      "KAP721TransferRouter"
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
    }
  },
  
};

export default config;
