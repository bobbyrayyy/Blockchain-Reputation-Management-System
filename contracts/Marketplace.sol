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

contract Marketplace {
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
    event ProductSale( 
        address indexed buyerAddress, 
        address indexed sellerAddress, 
        uint256 price, 
        uint256 timestamp 
    ); 
    event Reward( 
        address indexed buyerAddress, 
        address indexed sellerAddress, 
        address indexed commentAddress, 
        uint256 price,
        uint256 timestamp
    ); 
    event BuyerReview(
        address indexed productAddress,
        address indexed buyerAddress,
        uint256 rating,
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
        mapping(address => bool) Buyers; 
        mapping(address => string[]) BuyerReviews; 
    } 

    // Define struct for Reviews 
    struct Review {
        // Defining variables
        uint256 reviewID;
        address productAddress;
        address sellerAddress;
        address buyerAddress;
        //string reviewText;
        uint256 rating;
    }

    // Define struct for Sale 
    struct Sale {
        // Defining variables
        address saleAddress;
        address productAddress;
        address sellerAddress;
        address buyerAddress;
        uint256 price;
        uint256 timestamp;
        bool valid;
    }

    // Mappings
    // Tracks seller's number of sales
    mapping(address => uint256) public numOfSales;

    // Mapping productAddress to Product 
    mapping(address => Product) productMapping; 

    // Mapping sellerAddress to the amount of ETH they are able to withdraw
    mapping(address => uint256) sellerRevenue;

    // Mapping buyerAddress to the amount of ETH they are entitled to due to rewards
    mapping(address => uint256) buyerRewardAmounts;

    // Arrays
    Product[] public allProducts; 
    Review[] public allReviews;
    Sale[] public allSales;


    // Constructor 
    // initialising the marketplace
    constructor(string memory _sellerName, uint256 _sellerSalesCount, uint256 _rewardAmount) {
        sellerAddress = msg.sender; 
        sellerName = _sellerName;
        sellerSalesCount = _sellerSalesCount; 
        rewardAmount = _rewardAmount;
    }

    // Functions
    // Upload Product - called by seller
    function uploadProduct(address productAddress, uint256 price) 
    public 
    returns (bool success) 
    {
        // Verify whether the product information has been uploaded or not. 
        require(!productMapping[productAddress].valid, "Product already uploaded before!"); 

        // Initialize product instance (productAddress, sellerAddress, price) 
        Product storage p = Product(productAddress, msg.sender, price, true); 
        
        // Update mapping info 
        productMapping[productAddress] = p;

        // Add to marketplace's allProducts 
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

        // Checks if buyer's payment is equal to product price
        require(msg.value == p.price, "Please send exact amount!"); 

        // Perform the sale 
        // Give seller the credits 
        sellerRevenue[p.sellerAddress] += msg.value;
        // Update allSales
        // allSales

        // Update mapping 
        p.Buyers[msg.sender] = true; // buyer address is now registered as a buyer of this product 

        // Publish Purchase event to UI 
        emit ProductSale(msg.sender, sellerAddress, p.price, block.timestamp); 
        return true; 
    }
    
    // Review of product - called by buyer
    function buyerReview(string memory buyerRating, address productAddress) 
    public 
    returns (bool success) 
    { 
        // Verify whether product is in the system 
        require(productMapping[productAddress].valid, "Product does not exist!");  

        // Identify product instance 
        Product memory p = productMapping[productAddress]; 

        // Check if buyer actually bought the product 
        require(p.Buyers[msg.sender] == true, "No records of buyer buying this product or leaving review."); 

        // Update mappings 
        p.BuyerReviews[msg.sender] = buyerRating;

        // Publish Review event to UI 
        emit BuyerReview(productAddress, msg.sender, buyerRating, block.timestamp);
        return true; 
    }

    // Seller rewards buyers for leaving review - called by seller
    function reward(address productAddress, address buyerAddress, uint256 reviewID, uint256 rewardAmount) 
    public 
    payable 
    returns (bool success) 
    { 
        // Verify whether product is in the system 
        require(productMapping[productAddress].valid, "Product does not exist!"); 

        // Identify product instance 
        Product memory p = productMapping[productAddress]; 

        // Identify product instance via its product ID, via its IPFS address p = productMapping[productAddress] 
        // Check if buyer has actually bought the product 
        require(p.Buyers[buyerAddress] == true, "No records of buyer buying this product."); 

        // Check if buyer left a review 
        require(p.BuyerReviews[buyerAddress][reviewID] >= 0, "No records of buyer leaving review."); // no record denoted by -1

        // Future TODO - Seller gives review 
        //Update mapping for this seller review to the buyer 

        // Ensure seller has sent the correct amount
        require(msg.value == rewardAmount, "Please send exact amount of reward!");

        // Reward buyer 
        buyerRewardAmounts[buyerAddress] += rewardAmount;

        // Publish Reward event to UI 
        emit Reward(buyerAddress, msg.sender, reviewID, rewardAmount, block.timestamp);
        return true; 
    }

    // Payable functions - called by seller
    // Sellers withdraw amount they are entitled to
    function sellerWithdraw()
    public
    payable
    returns (bool sucess)
    {
        uint256 amountToWithdraw = sellerRevenue[msg.sender];
        payable(msg.sender).transfer(amountToWithdraw);
        sellerRevenue[msg.sender] = 0;
        return true;
    }

    // Buyers withdraw amount they are entitled to
    function buyerWithdraw()
    public
    payable
    returns (bool sucess)
    {
        uint256 amountToWithdraw = buyerRewardAmounts[msg.sender];
        payable(msg.sender).transfer(amountToWithdraw);
        buyerRewardAmounts[msg.sender] = 0;
        return true;
    }



}


// contract ERC20Basic{
//     uint256 public constant tokenPrice = 5; // 1 token for 5 wei
    
//     function buy(uint256 _amount) external payable {
//         // e.g. the buyer wants 100 tokens, needs to send 500 wei
//         require(msg.value == _amount * tokenPrice, 'Need to send exact amount of wei');
        
//         /*
//          * sends the requested amount of tokens
//          * from this contract address
//          * to the buyer
//          */
//         transfer(msg.sender, _amount);
//     }
    
//     function sell(uint256 _amount) external {
//         // decrement the token balance of the seller
//         balances[msg.sender] -= _amount;
//         increment the token balance of this contract
//         balances[address(this)] += _amount;

//         /*
//          * don't forget to emit the transfer event
//          * so that external apps can reflect the transfer
//          */
//         emit Transfer(msg.sender, address(this), _amount);
        
//         // e.g. the user is selling 100 tokens, send them 500 wei
//         payable(msg.sender).transfer(amount * tokenPrice);
//     }
// }