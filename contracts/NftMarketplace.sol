//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
error NftMarketplace_PriceMustBeAboveZero();
error NftMarketplace_NotApprovedForMarketplace();
error NftMarketplace_AlreadyListed(address NFTAddress, uint256 tokenId);

contract NftMarketplace {
struct Listing {
    uint256 price;
    address seller;
}
event ItemListed(address indexed seller, address indexed NFTAddress, uint256 tokenId, uint256 price);

//NFT contract address => tokenId => Listing
mapping(address => mapping(uint256 => Listing)) private s_Listing;

modifier NotListed ( address NFTAddress, uint256 tokenId) {
    Listing memory listing = s_Listing[NFTAddress][tokenId] ;
    if (listing.price > 0)
        revert NftMarketplace_AlreadyListed(NFTAddress, tokenId);
    _;
}

function listItem(address NFTAddress, uint256 tokenId, uint256 price) external {
    if (price <= 0) 
        revert NftMarketplace_PriceMustBeAboveZero();
    IERC721 nft = IERC721(NFTAddress);
    if (nft.getApproved(tokenId) != address(this))
        revert NftMarketplace_NotApprovedForMarketplace();
    s_Listing[NFTAddress][tokenId] = Listing(price, msg.sender);
    emit ItemListed(msg.sender, NFTAddress, tokenId, price);
}

}