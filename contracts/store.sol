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
    // Variables
    address public immutable sellerAddress; 
    string public sellerName; 
    uint256 public sellerSalesCount; 
    uint256 public rewardAmount;     

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
    
    // Structs
    // Define struct for Product (contains product info) 
    struct Product { 
        // Defining variables 
        address productAddress; 
        address sellerAddress; 
        uint256 price; 
        bool valid;
        // Mappings 
        //mapping(address => bool) Buyers; 
        //mapping(address => string[]) BuyerReviews; 
    } 

    // Define struct for Reviews 
    struct Review {
        // Defining variables
        address productAddress;
        address sellerAddress;
        address buyerAddress;
        string reviewText;
        uint256 rating;
        bool valid;
    }

    // // Define struct for Sale 
    // struct Sale {
    //     // Defining variables
    //     address productAddress;
    //     address sellerAddress;
    //     address buyerAddress;
    //     uint256 price;
    //     uint256 timestamp;
    //     bool valid;
    // }

    // Mappings
    // Tracks seller's number of sales
    mapping(address => uint256) public numOfSales;

    // Mapping productAddress to Product 
    mapping(address => Product) productMapping; 

    // Arrays
    // array of Products 
    Product[] public allProducts; 
    // array of Reviews
    Review[] public allReviews;
    // Sale[] public allSales;


    // Constructor 
    // initialising the seller store
    constructor(string memory _sellerName, uint256 _sellerSalesCount, uint256 _rewardAmount) {
        sellerAddress = msg.sender; 
        sellerName = _sellerName;
        sellerSalesCount = _sellerSalesCount; 
        rewardAmount = _rewardAmount;

    }

    // Functions

    // // setter method - costs gas
    // function changeName(string memory _sellerName) public {
    //     sellerName = _sellerName;
    // }

    // // getter method
    // function getName() public view returns (string memory) {
    //     return sellerName;
    // }

    // Upload Product - called by seller
    function uploadProduct(address productAddress, uint256 price) 
    public 
    returns (bool success) 
    {
        // Verify whether the product information has been uploaded or not. 
        require(!productMapping[productAddress].valid, "Product already uploaded before!"); 

        // Initialize product instance (productAddress, sellerAddress, price) 
        Product memory p = Product(productAddress, msg.sender, price, true); 
        
        // Update mapping info 
        productMapping[productAddress] = p;

        // Add to store's allProducts 
        allProducts.push(p); 

        // If success, publish to UI 
        emit Upload(productAddress, msg.sender);
        return true;
    }

    // Purchase of product - called by buyer 
    function purchaseProduct(address productAddress) 
    public 
    payable 
    returns (bool success) 
    { 
        // Verify whether product is in the system 
        require(productMapping[productAddress].valid, "Product does not exist!"); 

        // Check if buyer's balance is not 0 
        require(msg.value > 0, "Ethers cannot be zero!"); 

        // Identify product instance 
        Product memory p = productMapping[productAddress]; 

        // Checks if buyer's balance is sufficient to buy product 
        require(msg.sender.balance < p.price, "Insufficient balance!"); 

        // Perform the sale 
        msg.sender.balance -= p.price; 
        p.sellerAddress.balance += p.price; 
        sellerSalesCount += 1; 

        // Update mapping 
        p.Buyers[msg.sender] = ''; //blank to indicate no review yet 

        // Publish Purchase event to UI 
        emit Sale(msg.sender, sellerAddress, p.price, block.timestamp); 
        return true; 
    }


}
