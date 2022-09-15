async function main() {
    const MyStore = await ethers.getContractFactory("Store");
    const myStore = await MyStore.deploy("Store");
  
    console.log("Store deployed to:", myStore.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
  });
  