/*
Created by Bob Lin
SPDX-License-Identifier: MIT

Blockchain Reputation Management System in E-commerce 
-- 6 sections of code:
1. Create contract structure
2. Initialize seller store
3. Product upload
4. Product purchase
5. Buyer reviews
6. Rewards

*/

pragma solidity >= 0.7.0 < 0.9.0;

contract Marketplace {
    // ------------------------------------------------- Variables -------------------------------------------------
    uint public countOfSellers = 0;     
    uint public countOfBuyers = 0;
    uint public countOfProducts = 0;     

    // CONSTANTS
    uint PADDING = 100;    // This allows us to do 2dp calculations (convert percentages to basis points)

    // Note that all percentages in this program are represented as basis points (+ve uint)
    uint FORGET = 86; 
    uint TOLERANCE = 98;    
    uint NMAX = 20;
    uint NMIN = 0;

    uint VERIFIEDSCORE = 50;    // Verified accounts will receive this score straightaway (future works)
    
    // ----- Structs ------
    struct Seller {
        address sellerAddress;
        string name;
        uint sellerID;
        uint sellerRepScore;
        uint rewardPercentage; // bp
        uint sellerRevenue;
        bool valid;
        bool verified;
    }

    struct Buyer {
        address buyerAddress;
        uint buyerID;
        uint buyerRepScore;
        uint buyerRewardAmount;
        bool valid;
        bool verified;
        uint numOfReviewsGiven;
        uint countOfRepScores;
    }

    struct Product { 
        uint productID;
        string productName;
        address sellerAddress; 
        uint price; // in wei
        bool valid;
        uint countReviews;
        uint latestReviewTimestamp;
        uint rating;
        bool reviewed;
    } 

    // ----- Mappings -----
    // Maps user address to Seller or Buyer account struct
    mapping(address => Seller) public allSellers;
    mapping(address => Buyer) public allBuyers;

    // Tracks seller's number of sales
    mapping(address => uint) public numOfSales;

    // Mapping sellerAddress to array of Products
    mapping(address => Product[]) public productsOfSeller; 

    // Mapping buyerAddress to array of Products that they bought
    mapping(address => Product[]) public purchasedProductsOfBuyer;
    

    // ------------------------------------------------- Events -------------------------------------------------
    event Upload( 
        uint productID,
        string productName, 
        address sellerAddress
    ); 
    event ProductSale( 
        address buyerAddress, 
        address sellerAddress, 
        string productName,
        uint productID,
        uint price, // in wei
        uint timestamp,
        uint buyerProductIdx
    ); 
    event Reward( 
        address buyerAddress, 
        address sellerAddress, 
        uint price, // in wei
        uint timestamp
    ); 
    event BuyerReview(
        uint productID,
        address sellerAddress,
        address buyerAddress,
        uint rating,
        uint timestamp,
        uint newRating, 
        uint newCountOfReviews
    );
    event CreateSeller( 
        address sellerAddress, 
        string name,
        uint sellerID,
        uint rewardPercentage
    ); 
    event CreateBuyer( 
        address buyerAddress, 
        uint buyerID,
        uint buyerRepScore
    );
    event Verified(
        address userAddress
    );


    // ------------------------------------------------- Functions -------------------------------------------------

    function createSeller(string memory sellerName, uint rewardPercentage) 
    public 
    /*
        Creates a new seller - called by seller 
    */
    {
        // Check for duplicates
        require(!allSellers[msg.sender].valid, "Seller with this sellerAddress already exists!");

        // Update mapping and creation of new Seller struct
        Seller storage newSeller = allSellers[msg.sender];
        newSeller.sellerAddress = msg.sender;
        newSeller.name = sellerName;
        newSeller.sellerID = countOfSellers;
        newSeller.rewardPercentage = rewardPercentage;
        newSeller.sellerRevenue = 0;
        newSeller.valid = true;

        allSellers[msg.sender] = newSeller;
        countOfSellers++;

        emit CreateSeller(msg.sender, sellerName, countOfSellers, rewardPercentage);
    }

    function createBuyer(uint buyerRepScore) 
    public 
    /*
        Creates a buyer - called by buyer
        Technically all new buyers should start with rep score = 1
    */
    {
        // Check for duplicates
        require(!allBuyers[msg.sender].valid, "Buyer with this buyerAddress already exists!");

        // Update mapping
        Buyer storage newBuyer = allBuyers[msg.sender];
        newBuyer.buyerAddress = msg.sender;
        newBuyer.buyerID = countOfBuyers;
        newBuyer.buyerRepScore = buyerRepScore;
        newBuyer.valid = true;
        newBuyer.numOfReviewsGiven = 1; // N - starts at 1 because buyer will give review, if buyer doesn't, variable not used
        newBuyer.countOfRepScores = 1;  // n

        allBuyers[msg.sender] = newBuyer;
        countOfBuyers++;

        emit CreateBuyer(msg.sender, countOfBuyers, buyerRepScore);
    }

    function uploadProduct(string memory productName, uint price) 
    public 
    /*
        Called by existing seller to create and upload a new product
    */
    {
        // Verify whether the product information has been uploaded or not. (Pass if productID not valid)
        require(allSellers[msg.sender].valid, "This function is not called by a valid seller address!"); 

        // Get array of this seller's current products
        Product[] storage curSellerProducts = productsOfSeller[msg.sender];

        // Create a new slot in array for the next product
        uint productID = curSellerProducts.length;
        curSellerProducts.push();

        // Create Product struct (new product)
        Product storage newProduct = curSellerProducts[productID];
        newProduct.productID = productID; 
        newProduct.productName = productName;
        newProduct.sellerAddress = msg.sender;
        newProduct.price = price; // in wei
        newProduct.valid = true;
        newProduct.countReviews = 1; // n
        newProduct.rating = 1;  
        newProduct.reviewed = false;
        
        curSellerProducts[productID] = newProduct;
        countOfProducts++;

        // Update mapping productsOfSeller
        productsOfSeller[msg.sender] = curSellerProducts;

        // If success, publish to UI 
        emit Upload(productID, productName, msg.sender);
    }

    function purchaseProduct(uint productID, address payable sellerAddress) 
    public 
    payable 
    /*
        Called by existing buyer to purchase an existing product sold by a seller
        Involves payment from buyer to seller
    */
    { 
        // Verify whether the caller is a buyer
        require(allBuyers[msg.sender].valid, "This function is not called by a valid buyer address!"); 

        // Verify whether product is in the system 
        require(productsOfSeller[sellerAddress][productID].valid, "Product does not exist!"); 

        // Check if buyer's balance is not 0 (the value provided in this function call msg)
        require(msg.value > 0, "Ethers cannot be zero!"); 

        // Identify product instance 
        Product storage productToBuy = productsOfSeller[sellerAddress][productID]; // TODO memoery or storage?

        // Checks if buyer's payment is equal to product price
        require(msg.value  == productToBuy.price, "Please send exact amount!");  // in wei

        // Perform the sale 
        // Transfer eth to seller
        (bool sent, ) = sellerAddress.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        // Update curBuyerProducts array
        Product[] storage curBuyerProducts = purchasedProductsOfBuyer[msg.sender];
        uint buyerProductIdx = curBuyerProducts.length;
        curBuyerProducts.push();
        curBuyerProducts[buyerProductIdx] = productToBuy;

        // Update numOfSales
        numOfSales[sellerAddress]++;

        // Publish Purchase event to UI 
        emit ProductSale(msg.sender, sellerAddress, productToBuy.productName, productToBuy.productID, productToBuy.price, block.timestamp, buyerProductIdx); 
    }
    
    function buyerReview(uint buyerRating, uint productID, uint buyerProductIdx, address sellerAddress) 
    public 
    /*
        Buyer review of the product - called by buyer
        This is the second step of two steps, first being the buyer calling the calculateRepScore function
    */
    { 
        // --- CHECKS ---
        // Verify whether seller product is in the system ››
        require(productsOfSeller[sellerAddress][productID].valid, "Product does not exist!");  

        // Check if buyer has purchased this product before 
        require(
            purchasedProductsOfBuyer[msg.sender][buyerProductIdx].sellerAddress == sellerAddress &&
            purchasedProductsOfBuyer[msg.sender][buyerProductIdx].productID == productID,
            "This buyer's purchased product does not match with the seller's product to be reviewed."
        ); 

        // Check if buyer has left a review on this product before
        require(
            purchasedProductsOfBuyer[msg.sender][buyerProductIdx].reviewed == false, 
            "Buyer has already left a review on this product before."
        );

        // --- CALCULATIONS ---
        uint newRepScore = calculateRepScore(buyerRating, productID, buyerProductIdx, sellerAddress);

        // Calculate new product rating
        uint oldRating = productsOfSeller[sellerAddress][productID].rating;
        uint numOfRatings = productsOfSeller[sellerAddress][productID].countReviews;
        uint newRating = ( (oldRating * numOfRatings) + (buyerRating * newRepScore / 100) ) * 100 / (numOfRatings*100 + newRepScore); //CANNOT DIVIDE BY 100
        
        // --- UPDATE STATES --- 
        /* DEVELOPER'S NOTE:
        Notice how seller's product only gets rating and countReviews updated, 
        whereas buyer's product only gets reviewed and latestReviewTimestamp updated.

        This is because seller's product is 'on display', it has never been/will never be reviewed,
        it only updates the newest rating.

        The buyer's product should reflect whether the buyer has reviewed it, to prevent double reviews.
        Timestamp is needed to calculate rep score for this buyer. 
        The rating of the buyer's product will stay the same and reflect the rating at which the buyer bought it.
        */

        // Update seller's product's information
        productsOfSeller[sellerAddress][productID].rating = newRating;
        productsOfSeller[sellerAddress][productID].countReviews++;

        // Update buyer's product information
        purchasedProductsOfBuyer[msg.sender][buyerProductIdx].reviewed = true;
        purchasedProductsOfBuyer[msg.sender][buyerProductIdx].latestReviewTimestamp = block.timestamp;
        
        // Update buyer rep score and increment counters
        allBuyers[msg.sender].buyerRepScore = newRepScore; 
        allBuyers[msg.sender].countOfRepScores++;
        allBuyers[msg.sender].numOfReviewsGiven++;

        // Note that cannot directly call reward() function here because internal function cannot be payable
    
        // Publish Review event to UI 
        emit BuyerReview(productID, sellerAddress, msg.sender, buyerRating, block.timestamp, productsOfSeller[sellerAddress][productID].rating, productsOfSeller[sellerAddress][productID].countReviews);
    }

    function calculateRepScore(uint buyerRating, uint productID, uint buyerProductIdx, address sellerAddress)
    private
    view
    returns (uint)
    /*
        Called by buyerReview() function internally to return calculate updated rep score
        It is a view function, meaning no states are modified in this function - 
        merely viewing and calculating values without updates
    */
    {
        // Identify buyer and rep scores
        Buyer storage buyer = allBuyers[msg.sender];
        uint oldRepScore = buyer.buyerRepScore;
        uint countOfRepScores = buyer.countOfRepScores;

        // 1. frequency factor 
        // Use buyer's latest timestamp
        uint timePrev = purchasedProductsOfBuyer[msg.sender][buyerProductIdx].latestReviewTimestamp;    
        uint timeNow = block.timestamp;
        uint deltaHours = (timeNow - timePrev)/3600;
        uint frequencyFactor;

        if (deltaHours > 38) {
            frequencyFactor = 100;
        }
        else {
            // Anything more than 38 hours will cause error
            frequencyFactor = ((PADDING ** deltaHours) / (FORGET ** deltaHours));   // to int (bp)
        }

        // 2. deviation factor
        // need this workaround since no support for negative numbers for unsigned int
        uint deltaRating;
        uint oldRating = productsOfSeller[sellerAddress][productID].rating;
        if (oldRating > buyerRating) {
            deltaRating = oldRating - buyerRating;
        }
        else {
            deltaRating = buyerRating - oldRating;
        }

        // Note that deltaRating can max be 38, any bigger than 38 MIGHT be larger than max support of Solidity uint256
        if (deltaRating > 38) {
            deltaRating = 38;
        }
        uint deviationFactor = ( (TOLERANCE ** deltaRating)*100 ) / (PADDING ** deltaRating);// to integer (bp)

        // 3. active factor
        uint N = allBuyers[msg.sender].numOfReviewsGiven;
        uint activeFactor = ((N - NMIN)*100) /(NMAX - NMIN);       // int (bp)
        // activeFactor is minimum of the result above, or 100
        if (activeFactor > 100) {
            activeFactor = 100;
        }

        // Calc incomingRepScore - the next instance of RS score to include in aggregation
        uint incomingRepScore = frequencyFactor * deviationFactor * activeFactor /10000;    //int (bp)
        if (incomingRepScore > 150) {
            incomingRepScore = 150;
        }
        else if (incomingRepScore < 1) {
            incomingRepScore = 0;
        }

        // Calc newRepScore (aggregated w past rep scores)
        uint newRepScore = (incomingRepScore + (oldRepScore * countOfRepScores)) / (countOfRepScores+1);  // rounded by Solidity
        // Conditional clause such that rep scores are not stagnant due to rounding issues - should be refactored in future works
        if (newRepScore == oldRepScore) {
            if (incomingRepScore > oldRepScore) {
                newRepScore++;
            }
            else if (incomingRepScore < oldRepScore) {
                newRepScore--;
            }
        }

        // Sanity checks on limits
        if (newRepScore < 0) {
            newRepScore = 0;
        }
        else if (newRepScore > 100) {
            newRepScore = 100;
        }

        return newRepScore;
    }

    // Seller rewards buyers for leaving review - called by seller
    function reward(address sellerAddress, uint productID, address buyerAddress, uint buyerProductIdx) 
    public 
    payable 
    { 
        // CHECKS
        require(productsOfSeller[sellerAddress][productID].valid, "Product does not exist!"); 
        require(purchasedProductsOfBuyer[buyerAddress][buyerProductIdx].valid, "No records of buyer buying this product."); 
        require(purchasedProductsOfBuyer[buyerAddress][buyerProductIdx].reviewed, "No records of buyer leaving review."); 

        // Calculate how much to reward (in wei)
        uint finalReward = allSellers[sellerAddress].rewardPercentage * productsOfSeller[sellerAddress][productID].price * allBuyers[buyerAddress].buyerRepScore / 10000; // div by 100 twice (one for rewardPercentage, one for buyerRepScore)

        // Check if msg.value is enough to pay Buyer (in wei)
        require(msg.value >= finalReward, "msg.value not enough to pay reward."); 
        
        // Transfer reward amount to buyer 
        (bool sentBuyer, ) = buyerAddress.call{value: finalReward}("");
        require(sentBuyer, "Failed to send Ether to Buyer");

        // Change return to seller
        uint remainingValue = msg.value - finalReward;
        (bool sentSeller, ) = sellerAddress.call{value: remainingValue}("");
        require(sentSeller, "Failed to send remaining Ether to Seller");

        // Publish Reward event to UI 
        emit Reward(buyerAddress, msg.sender, finalReward, block.timestamp);
    }

    function verifyID()
    public
    /*
        (Currently not in any use case, designed for future works)
        Verifies a buyer account, which increases rep score to VERIFIEDSCORE, if current score is lower
    */
    {   
        // Checks
        require(allBuyers[msg.sender].valid == true, "Address is not a buyer");
        require(allBuyers[msg.sender].verified == false, "This account is already verified.");

        allBuyers[msg.sender].verified = true;

        // Update rep score to VERIFIEDSCORE if current score is under VERIFIEDSCORE
        if (allBuyers[msg.sender].buyerRepScore < VERIFIEDSCORE) {
            allBuyers[msg.sender].buyerRepScore = VERIFIEDSCORE;
        }
        
        emit Verified(msg.sender);
    }

}

