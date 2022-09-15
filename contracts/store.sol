/**
Created by Bob Lin

Blockchain Reputation Management System in E-commerce 
-- 6 sections of code:
1. Create contract structure
2. Initialize seller store
3. Product upload
4. Product purchase
5. Buyer reviews
6. Rewards
 */


// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Store {
    // Defining some global variables 
    address public immutable sellerAddress; 
    string public sellerName; 
    uint256 public sellerSalesCount; 
    uint256 public rewardAmount;     

    // Define struct for Product (contains product info) 
    struct Product { 
        // Defining variables 
        address productAddress; 
        address sellerAddress; 
        uint256 price; 
        // Mappings 
        mapping(address => bool) Buyers; 
        mapping(address => string[]) BuyerReviews; 
    } 
    // Mapping productAddress to Product 
    mapping(address => Product) productMapping; 

    // Initialize array of Products 
    Product[] public allProducts; 

    // Events 
    event Upload( 
        address indexed productAddress, 
        address indexed sellerAddress
    
    ); 
    event Sale( 
        address indexed buyerAddress, 
        address indexed sellerAddress, 
        uint256 price, 
        uint256 timestamp 
    ); 
    event Reward( 
        address indexed buyerAddress, 
        address indexed sellerAddress, 
        address indexed commentAddress, 
        address sellerId, 
        uint256 price,
        uint256 timestamp
    ); 
    event Transfer( 

    ); 

    // Constructor
    constructor(string memory _sellerName, uint256 _sellerSalesCount, uint256 _rewardAmount) {
        sellerAddress = msg.sender; 
        sellerName = _sellerName;
        sellerSalesCount = _sellerSalesCount; 
        rewardAmount = _rewardAmount;

    }

    // setter method - costs gas
    function changeName(string memory _sellerName) public {
        sellerName = _sellerName;
    }

    // getter method
    function getName() public view returns (string memory) {
        return sellerName;
    }


}
