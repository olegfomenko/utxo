require("@nomiclabs/hardhat-waffle");
require('@openzeppelin/hardhat-upgrades');
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-truffle5");
require("hardhat-gas-reporter");

module.exports = {
  solidity: "0.8.0",
  gasReporter: {
    enabled: true,
    outputFile: "contract-gas-report.txt",
    noColors: true,
  },
  networks: {
    sepolia: {
      url: "https://sepolia.infura.io/v3/a2da87c20a9c44f68626c276ab62c4a6",
      accounts: {
        mnemonic: "joy cave salute upon change order degree excite clog drive electric lottery",
      },
    },
    local: {
      url: "http://localhost:8545",
      accounts: ["90...caa"]
    },
  },
  etherscan: {
    url: "",
    apiKey: "JD7PMAJC3RWSS7HIEDMRHF16D2G54Z4UUY",
  },
};