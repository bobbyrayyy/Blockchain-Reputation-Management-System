// require("@nomicfoundation/hardhat-chai-matchers");
// require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-ethers");
require("@nomicfoundation/hardhat-toolbox");
// require("dotenv").config();

const ALCHEMY_API_KEY = "1wmWntbqyQY7dxyMAK4ZnTTzyO8FfnbC";
const GOERLI_PRIVATE_KEY = "22d151880b7f106cabafdff6238ec2ac90a0dd3d3cb1a868f422f4f15e19173b";

module.exports = {
  solidity: "0.8.9",
  defaultNetwork: "georli",
  networks: {
    // hardhat: {},
    georli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      accounts: [GOERLI_PRIVATE_KEY]
    }
  },
  // paths: {
  //   sources: "./contracts",
  //   tests: "./test",
  //   cache: "./cache",
  //   artifacts: "./artifacts"
  // },
  // etherscan: {
  // // Your API key for Etherscan
  // // Obtain one at https://etherscan.io/
  // apiKey: "ZW14B7S34VJTYJ6PSCPX4DN15U4D65HVMR"
  // },
  
};

/*
TODO - Cant deploy to testnet now, some errors with API URL and PRI KEY
Current status:
- Marketplace.sol done
- Can deploy to hardhat default net (by commenting our defaultNetwork and networks in config)
- Cannot deploy to goerli yet

*/