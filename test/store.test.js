const { expect } = require("chai");

describe("store", () => {
  it("should return its name", async () => {
    const MyStore = await ethers.getContractFactory("Store");
    const myStore = await MyStore.deploy("My Store");

    await myStore.deployed();
    expect(await myStore.getName()).to.equal("My Store");
  });
  it("should change its name when requested", async () => {
    const MyStore = await ethers.getContractFactory("Store");
    const myStore = await MyStore.deploy("My Store");

    await myStore.changeName("Another Store");
    expect(await myStore.getName()).to.equal("Another Store");
  });
});
