const main = async () => {
  try {
    const Contract = await hre.ethers.getContractFactory("ChainBattles");
    const contract = await Contract.deploy();
    await contract.deployed();
    console.log("contract deployed to :", contract.address);
    process.exit(0); // if everything works out we exit the script
  } catch (e) {
    console.log(e);
    process.exit(1); // which signifies there was an issue
  }
};

main();
