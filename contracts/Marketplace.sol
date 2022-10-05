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

This marketplace currently is set up for only 1 seller store with multiple products, and multiple possible buyers.
Things to add:
- Reputation score storage
- Reputation score calculations and updates

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
        uint256 productID,
        string productName, 
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
        uint256 reviewID, 
        uint256 price,
        uint256 timestamp
    ); 
    event BuyerReview(
        uint256 productID,
        uint256 reviewID,
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
        // address productID; 
        uint256 productID;
        string productName;
        address sellerAddress; 
        uint256 price; 
        bool valid;
        uint256 countReviews;
        // Mappings 
        // Buyer address => bool
        mapping(address => bool) buyers; 
        // Buyer address => reviewID
        mapping(address => Review) buyerReviews; 
        // Product[] products; // NEW TODO
        // mapping(address => Review) reviews;
    } 

    Product[] public allProducts;
    // mapping()

    
    // struct Reviews {
    //     mapping()
    // }


    // Define struct for Reviews 
    struct Review {
        // Defining variables
        uint256 reviewID;
        uint256 productID;
        address sellerAddress;
        address buyerAddress;
        //string reviewText;
        uint256 rating;
        bool valid;
    }


    // Define struct for Sale 
    struct Sale {
        // Defining variables
        address saleAddress;
        address productID;
        address sellerAddress;
        address buyerAddress;
        uint256 price;
        uint256 timestamp;
        bool valid;
    }

    // Mappings
    // Tracks seller's number of sales
    mapping(address => uint256) public numOfSales;

    // // Mapping productID to Product 
    // mapping(address => Product) allProducts; 

    // Mapping sellerAddress to the amount of ETH they are able to withdraw
    mapping(address => uint256) sellerRevenue;

    // Mapping buyerAddress to the amount of ETH they are entitled to due to rewards
    mapping(address => uint256) buyerRewardAmounts;

    // Arrays
    // Product[] public allProducts; 
    // Unused so far... review!
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
    function uploadProduct(uint256 productID, string memory productName, uint256 price) 
    public 
    returns (bool success) 
    {
        // Verify whether the product information has been uploaded or not. (Pass if productID not valid)
        require(!allProducts[productID].valid, "Product with this productID already uploaded before!"); 

        // Initialize product instance 
        // cur numProducts will also be the productID of the next newProduct (zero indexed)
        uint256 numProducts = allProducts.length;
        // adds one ele to array allProducts
        allProducts.push(); 
        // Create a newProduct in storage, note that numProducts is the new productID
        // This way of initialisation is necessary to avoid (nested) mapping error in Solidity
        Product storage newProduct = allProducts[numProducts];
        // Product storage newProduct = allProducts[productID];

        // numProducts++;
        newProduct.productID = numProducts; 
        newProduct.productName = productName;
        newProduct.sellerAddress = msg.sender;
        newProduct.price = price;
        newProduct.valid = true;
        newProduct.countReviews = 0;

        // Mappings (None during initialisation)

        // If success, publish to UI 
        emit Upload(numProducts, productName, msg.sender);
        return true;
    }

    // Purchase of product - called by buyer 
    function purchaseProduct(uint256 productID) 
    public 
    payable 
    returns (bool success) 
    { 
        // Verify whether product is in the system 
        require(allProducts[productID].valid, "Product does not exist!"); 

        // Check if buyer's balance is not 0 (the value provided in this function call msg)
        require(msg.value > 0, "Ethers cannot be zero!"); 

        // Identify product instance 
        Product storage productToBuy = allProducts[productID]; 

        // Checks if buyer's payment is equal to product price
        require(msg.value == productToBuy.price, "Please send exact amount!"); 

        // Perform the sale 
        // Give seller the credits 
        sellerRevenue[productToBuy.sellerAddress] += msg.value;
        // Update allSales
        // allSales

        // Update mapping 
        productToBuy.buyers[msg.sender] = true; // mapping buyer address to true or false depending on whether the buyer has bought this product before

        // Publish Purchase event to UI 
        emit ProductSale(msg.sender, sellerAddress, productToBuy.price, block.timestamp); 
        return true; 
    }
    
    // Review of product - called by buyer
    function buyerReview(uint256 buyerRating, uint256 productID) 
    public 
    returns (bool success) 
    { 
        // Verify whether product is in the system 
        require(allProducts[productID].valid, "Product does not exist!");  

        // Identify product instance 
        Product storage productToReview = allProducts[productID]; 

        // Check if buyer actually bought the product 
        require(productToReview.buyers[msg.sender] == true, "No records of buyer buying this product or leaving review."); 

        // Create the Reviewww named productReview
        productToReview.countReviews++;
        uint256 reviewID = productToReview.countReviews;
        Review memory productReview = Review(reviewID, productID, productToReview.sellerAddress, msg.sender, buyerRating, true);

        // Update mappings 
        productToReview.buyerReviews[msg.sender] = productReview;

        // Publish Review event to UI 
        emit BuyerReview(productID, reviewID, msg.sender, buyerRating, block.timestamp);
        return true;

    }

    // Seller rewards buyers for leaving review - called by seller
    function reward(uint256 productID, address buyerAddress, uint256 reviewID) 
    public 
    payable 
    returns (bool success) 
    { 
        // Verify whether product is in the system 
        require(allProducts[productID].valid, "Product does not exist!"); 

        // Identify product instance 
        Product storage product = allProducts[productID]; 

        // Identify product instance via its product ID, via its IPFS address p = allProducts[productID] 
        // Check if buyer has actually bought the product 
        require(product.buyers[buyerAddress] == true, "No records of buyer buying this product."); 

        // TODO START FROM HERE!
        // Check if buyer left a review 
        require(product.buyerReviews[buyerAddress].valid, "No records of buyer leaving review."); 

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