const UTXO = artifacts.require("UTXO");
const EllipticCurve = artifacts.require("EllipticCurve");

module.exports = function(deployer) {
  deployer.deploy(EllipticCurve).then(()=>{
    return deployer.deploy(UTXO);
  });
  deployer.link(EllipticCurve, UTXO);
}