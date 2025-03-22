// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract NFTMarket is ReentrancyGuard{

    using Counters for Counters.Counter;
    
    Counters.Counter private _ItemIds;
    Counters.Counter private _ItemsSold;

    address payable owner;

    uint listingPrice = 0.1 ether;

    constructor(){
        owner = payable(msg.sender);
    }


    struct MarketItem{
        uint itemId;
        address nftContract;
        uint tokenId;
        // external account who wants to sell their nft in this market place  
        address payable seller ;
        // owner of the market place who gets listing prices 
        address payable owner ;
        uint price;
        bool sold ;
    }

    mapping(uint => MarketItem) private idToMarketItem;

    event MarketItemCreated(
        uint indexed itemId,
        address indexed  nftContract,
        uint indexed tokenId,
        address seller,
        address owner,
        uint price,
        bool sold 
    );

    function getListingPrice() public view  returns(uint){
        return listingPrice;
    }

    function createMarketItem(
        address nftContract,
        uint tokenId,
        uint price
    ) public payable nonReentrant{
        require(price > 0 ,"price should be atleat one wei");
        require(msg.value ==listingPrice,"price should be equal to the listing price");

        _ItemIds.increment();
        uint itemId = _ItemIds.current();

        idToMarketItem[itemId]=MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );

        IERC721(nftContract).transferFrom(msg.sender , address(this), tokenId);

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            false
        );
    }

    function createMarketSale(
        address nftContract,
        uint itemId
    ) public payable nonReentrant{

        uint price = idToMarketItem[itemId].price;
        uint tokenId = idToMarketItem[itemId].tokenId;

        require(msg.value == price,"please submit the required funds to buy the nft");

        idToMarketItem[itemId].seller.transfer(msg.value);

        IERC721(nftContract).transferFrom(address(this), address(msg.sender), tokenId );

        idToMarketItem[itemId].owner =payable(msg.sender);
        idToMarketItem[itemId].sold = true;

        _ItemsSold.increment();
        payable(owner).transfer(listingPrice);
    }

    function fetchMarketItems() public view returns(MarketItem[] memory){

        uint itemCount= _ItemIds.current();
        uint unSoldItemCount = _ItemIds.current()-_ItemsSold.current();
        uint currentIndex=0;

        MarketItem[] memory items = new MarketItem[](unSoldItemCount);

        for(uint i =0 ; i<itemCount ; i++){
            if(idToMarketItem[i+1].owner==address(0)){
                uint currentId = idToMarketItem[i+1].itemId;
                MarketItem storage currentItem= idToMarketItem[currentId];
                items[currentIndex]=currentItem;
                currentIndex++;
            }
        }
        return items;
    }

    function fetchMyNFTs() public view returns(MarketItem[] memory){
        
        uint totalItemCount = _ItemIds.current();
        uint itemCount=0;
        uint currentIndex=0;


        for(uint i=0 ; i<totalItemCount ; i++){
            if(idToMarketItem[i+1].owner == msg.sender){
                itemCount++;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);

        for(uint i=0 ; i < totalItemCount ; i++){
            if(idToMarketItem[i+1].owner == msg.sender){
                uint currentId =i+1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex]=currentItem;
                currentIndex++;
            }
        }
        return items;
    }

    function fetchItemsCreated()public view returns(MarketItem[] memory){

        uint totalItemCount = _ItemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0 ;

        for (uint i =0 ; i < totalItemCount  ; i++){
            if(idToMarketItem[i+1].seller ==  msg.sender){
                itemCount++;
            }
        }

        MarketItem[]  memory items = new MarketItem[](itemCount);

        for (uint i = 0  ; i < totalItemCount ; i++){
            if(idToMarketItem[i+1].seller==msg.sender){
                uint currentId = i+1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex]=currentItem ;
                currentIndex++;
            }
        }
        return items;
    }
}

