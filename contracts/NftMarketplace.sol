//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error NftMarketplace_PriceMustBeAboveZero();
error NftMarketplace_NotApprovedForMarketplace();
error NftMarketplace_AlreadyListed(address NFTAddress, uint256 tokenId);
error NftMarketplace_IsNotOwner();
error NftMarketplace_NotListed(address NFTaddress, uint256 tokenId);
error NftMarketplace_PriceNotMet(address NFTaddress, uint256 tokenId, uint256 price);
error NftMarketplace_NoProceedToWithdraw();
error NftMarketplace_TransferFaied();

contract NftMarketplace is ReentrancyGuard{
struct Listing  {
    uint256 price;
    address seller;
} 
event ItemListed(address indexed seller, address indexed NFTAddress, uint256 tokenId, uint256 price);
event ItemBought(address indexed buyer, address indexed NFTAddress, uint256 tokenId, uint256 price);
event ItemCanceled(address indexed seller, address indexed NFTAddress, uint256 tokenId);

//NFT contract address => tokenId => Listing
mapping(address => mapping(uint256 => Listing)) private s_Listing;

//Seller address to amount earned
mapping (address => uint256) private s_Proceeds;

modifier NotListed ( address NFTAddress, uint256 tokenId) {
    Listing memory listing = s_Listing[NFTAddress][tokenId] ;
    if (listing.price > 0)
        revert NftMarketplace_AlreadyListed(NFTAddress, tokenId);
    _;
}

modifier IsOwner(address NFTAddress, uint256 tokenId, address spender) {
    IERC721 nft = IERC721(NFTAddress);
    address owner = nft.ownerOf(tokenId);
    if (spender != owner) {
            revert NftMarketplace_IsNotOwner();
        }
    _;   
 } 

modifier IsListed(address NFTaddress, uint256 tokenId) {
    Listing memory listing = s_Listing[NFTaddress][tokenId];
    if ( listing.price <= 0 )  {
            revert NftMarketplace_NotListed(NFTaddress, tokenId);
    }
    _;

}
/*
@Notice Method for listing your NFT to the marketplace
@param NFTaddress: Address of the NFT
@param tokenId:  the token ID of the NFT
@param price: the desired price of the NFT
*/
function listItem(address NFTAddress, uint256 tokenId, uint256 price) external NotListed(NFTAddress, tokenId)
    IsOwner(NFTAddress, tokenId, msg.sender) {
    if (price <= 0) 
        revert NftMarketplace_PriceMustBeAboveZero();
    IERC721 nft = IERC721(NFTAddress);
    if (nft.getApproved(tokenId) != address(this))
        revert NftMarketplace_NotApprovedForMarketplace();
    s_Listing[NFTAddress][tokenId] = Listing(price, msg.sender);
    emit ItemListed(msg.sender, NFTAddress, tokenId, price);
}

function buyItem(address NFTaddress, uint256 tokenId) external payable IsListed(NFTaddress, tokenId) nonReentrant(){
    Listing memory nftListed = s_Listing[NFTaddress][tokenId] ;
    if (msg.value < nftListed.price ) {
        revert NftMarketplace_PriceNotMet(NFTaddress, tokenId, nftListed.price);    
    }
    s_Proceeds[nftListed.seller] = s_Proceeds[nftListed.seller] + msg.value;
    delete (s_Listing[NFTaddress][tokenId]);
    IERC721(NFTaddress).safeTransferFrom(nftListed.seller, msg.sender, tokenId);
    emit ItemBought(msg.sender, NFTaddress, tokenId, nftListed.price);
}

function cancelListing(address NFTaddress, uint256 tokenId) external IsListed(NFTaddress, tokenId) IsOwner(NFTaddress, tokenId, msg.sender){
    delete(s_Listing[NFTaddress][tokenId]);
    emit ItemCanceled(msg.sender, NFTaddress, tokenId);
}

function updateListing(address NFTaddress, uint256 tokenId, uint256 newItemPrice) external IsListed(NFTaddress, tokenId) IsOwner(NFTaddress, tokenId, msg.sender) {
    s_Listing[NFTaddress][tokenId].price = newItemPrice;
    emit ItemListed(msg.sender, NFTaddress, tokenId, newItemPrice);
}

function withdrawProceeds() external {
    uint256 proceeds = s_Proceeds[msg.sender];
    if (proceeds <= 0) {
        revert NftMarketplace_NoProceedToWithdraw();
    }
    s_Proceeds[msg.sender] = 0;
    (bool sucess,) = payable (msg.sender).call{value: proceeds}("");
    if (!sucess) {
        revert NftMarketplace_TransferFaied();     
    }

}

function getLitings(address NFTaddress, uint256 tokenId) external view returns (Listing memory) {
    return s_Listing [NFTaddress][tokenId];
}

function getProceeds(address seller) external view returns(uint256) {
    return s_Proceeds[seller];
}

}