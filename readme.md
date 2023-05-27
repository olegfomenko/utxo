# UTXO EVM

```shell
npm install -D hardhat-deploy
npx hardhat
npm install --save-dev @nomiclabs/hardhat-ethers ethers @nomiclabs/hardhat-waffle ethereum-waffle chai
npm install @openzeppelin/contracts
npx hardhat compile
npx hardhat run scripts/deploy.js --network goerli
npx hardhat verify --network goerli 0x0618110F479948e84AEC6b117Ef3Be881FDe6581
```