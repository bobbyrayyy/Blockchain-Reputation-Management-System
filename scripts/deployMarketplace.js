async function main() {
    const MyMarketplace = await ethers.getContractFactory("Seller A's Store", 0, 10);
    const myMarketplace = await MyMarketplace.deploy("eller A's Store", 0, 0);
  
    console.log("Store deployed to:", myMarketplace.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
  });
  