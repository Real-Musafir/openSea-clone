//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; //prevent re-entrancy attacks

contract NFTMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold; //Total number of item sold

    address payable owner; // owner of the smart contract

    //people have to pay their NFT on this marketplace
    uint256 listingPrice = 0.025 ether;

    constructor(){
        owner = payable(msg.sender);
    }

    struct MarketItem {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint price;
        bool sold; 
    }

    //a way to access values of the MarketItem struct above by passing an integer ID
    mapping(uint256 => MarketItem) private idMarketItem;

    //log message (when item is sold)
    event MarketItemCreated(
       uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address  seller,
        address  owner,
        uint price,
        bool sold
    );

    /// @notice function to get listing price
    function getListingPrice() public view returns(uint256){
        return listingPrice;
    }

    /// @notice function to create market item
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price) public payable nonReentrant{
            require(price>0, "Price must be above zero");
            require(msg.value == listingPrice, "Price Must be equal to the listing price");
            
            _itemIds.increment();
            uint256 itemId = _itemIds.current();

           idMarketItem[itemId] = MarketItem(
               itemId,
               nftContract,
               tokenId,
               payable(msg.sender), //address of the seller putting the nft up for sale
               payable(address(0)), // no owner yet (set owner to empty address)
               price,
               false
           );

           // transfer ownership of the nft to the contract itself
           IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId); //in safeTransferFrom(from, to, tokenId)

           //Log this transaction
           emit MarketItemCreated(
               itemId,
               nftContract,
               tokenId,
               msg.sender,
               address(0),
               price,
               false);

        }


        /// @notice function to create a sale
        function createMarketSale(address nftContract, uint256 itemId) public payable nonReentrant{
            uint price = idMarketItem[itemId].price;
            uint tokenId =  idMarketItem[itemId].tokenId;

            require(msg.value == price, "Please submit the asking price in order to complete purchase");

            //pay the seller the amount
            idMarketItem[itemId].seller.transfer(msg.value);

             // transfer ownership of the nft from the contract itself to the buyer
           IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId); //in safeTransferFrom(from, to, tokenId)

           idMarketItem[itemId].owner = payable(msg.sender); // mark buyer as new owner
           idMarketItem[itemId].sold = true; // mark that is has been sold
           _itemsSold.increment(); //increment the total number of Items sold by 1
           payable(owner).transfer(listingPrice); //pay owner of contract the listing price
        }

        /// @notice total number of items unsold on our platform
        function fetchMarketItems() public view returns(MarketItem[] memory) {
            uint itemCount = _itemIds.current(); // total number of item ever created in our platform

            uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
            
            uint currentIndex = 0;

            MarketItem[] memory items = new MarketItem[](unsoldItemCount);
            //loop throug all items ever created
            for(uint i=0; i<itemCount; i++){
                // check if the item has not been sold
                // by checking if the owner field if emtpy
                if(idMarketItem[i+1].owner == address(0)){
                    // Yes this item has never been sold
                    uint currentId = idMarketItem[i+1].itemId;
                    MarketItem storage currentItem = idMarketItem[currentId];
                    items[currentIndex] = currentItem;
                    currentIndex +=1;
                }
            }

            return items; // return array of all unsold items
        }

        /// @notice fetch list of NFTS owned bought by this user
        function fetchMyNFTs() public view returns(MarketItem[] memory){
            // get total number of items ever created
            uint totalItemCount = _itemIds.current();

            uint itemCount = 0;
            uint currentIndex = 0;

            for(uint i = 0; i<=totalItemCount; i++){
                if(idMarketItem[i+1].owner==msg.sender){
                    itemCount +=1;
                }
            }

        MarketItem[] memory items = new MarketItem[](itemCount);

        for(uint i =0; i<totalItemCount; i++){
            if(idMarketItem[i+1].owner==msg.sender){
                uint currentId = idMarketItem[i+1].itemId;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex +=1;

            }
        }

        return items;

        }

}