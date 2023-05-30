# UTXO EVM

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Deploy
```shell
npm install -D hardhat-deploy
npx hardhat
npm install --save-dev @nomiclabs/hardhat-ethers ethers @nomiclabs/hardhat-waffle ethereum-waffle chai
npm install @openzeppelin/contracts
npx hardhat compile
npx hardhat run scripts/deploy.js --network sepolia
npx hardhat verify --network sepolia 0xE8d7C93934d1cC5bE96b5B3046a4DB1971339123
npx hardhat test
```

## UTXO Pedersen Commitment (ETH)
Solidity implementation of the [Bitcoin Confidential Assets](https://blockstream.com/bitcoin17-final41.pdf) 
for anonymous ETH transfers. The `./contracts/pedersen` package provides the implementation of UTXO with Pedersen 
commitment along with Back-Maxwell range proofs and Schnorr signatures under bn128 elliptic curve.

Explore [back-maxwell-rangeproof](https://github.com/olegfomenko/back-maxwell-rangeproof) on Go with descriptions, 
Proof and Signature generation examples. 

## UTXO ECDSA (ERC20)
The `./contracts/pedersen` contains Solidity implementation of UTXO for ERC20 transfers managed with ECDSA secp256k1 signature.