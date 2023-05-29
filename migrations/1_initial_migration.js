const UTXO = artifacts.require("UTXO");

module.exports = function(deployer) {
  deployer.deploy(UTXO);
}