async function main() {

  const [deployer] = await ethers.getSigners();

  console.log(
    "Deploying contracts with the account:",
    deployer.address
  );

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const lib = await ethers.getContractFactory("EllipticCurve");
  const libContract = await lib.deploy();

  console.log("Contract deployed at:", libContract.address);

  const utxo = await ethers.getContractFactory("UTXO",
    {
      libraries: {
        EllipticCurve: libContract.address,
      }
    }
  );

  const utxoContract = await utxo.deploy();
  console.log("Contract deployed at:", utxoContract.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });