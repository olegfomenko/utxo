# UTXO EVM

```shell
npm install -D hardhat-deploy
npx hardhat
npm install --save-dev @nomiclabs/hardhat-ethers ethers @nomiclabs/hardhat-waffle ethereum-waffle chai
npm install @openzeppelin/contracts
npx hardhat compile
npx hardhat run scripts/deploy.js --network sepolia
npx hardhat verify --network sepolia 0xE8d7C93934d1cC5bE96b5B3046a4DB1971339123
```