require("@nomiclabs/hardhat-waffle");
require('@openzeppelin/hardhat-upgrades');
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-truffle5");

module.exports = {
  solidity: "0.8.0",
  networks: {
    sepolia: {
      url: "https://sepolia.infura.io/v3/a2da87c20a9c44f68626c276ab62c4a6",
      accounts: {
        mnemonic: "joy cave salute upon change order degree excite clog drive electric lottery",
      },
    },
  },
  etherscan: {
    url: "",
    apiKey: "JD7PMAJC3RWSS7HIEDMRHF16D2G54Z4UUY",
  },
};