const { expect } = require("chai");

describe("Marketplace", () => {
  it("should return its name", async () => {
    const MyMarketplace = await ethers.getContractFactory("Seller A's Store", 0, 10);
    const myMarketplace = await MyMarketplace.deploy("eller A's Store", 0, 0);

    await myMarketplace.deployed();
    expect(await myMarketplace.getName()).to.equal("My Store");
  });
  it("should change its name when requested", async () => {
    const MyMarketplace = await ethers.getContractFactory("Seller A's Store", 0, 10);
    const myMarketplace = await MyMarketplace.deploy("eller A's Store", 0, 0);

    await myMarketplace.changeName("Another Store");
    expect(await myMarketplace.getName()).to.equal("Another Store");
  });
});
