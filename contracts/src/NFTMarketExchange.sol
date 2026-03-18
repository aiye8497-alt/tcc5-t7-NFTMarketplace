//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract NFTMarketExchange is Ownable, ReentrancyGuard {
    struct Listing {
        address seller;
        uint256 price;
    }

    // Mapping from token ID to listing details
    mapping(uint256 => Listing) public listings;

    // Address of the ERC20 token used for payments
    IERC20 public paymentToken;

    // Address of the ERC721 token being traded
    IERC721 public nftToken;

    event ItemListed(address indexed seller, uint256 indexed tokenId, uint256 price);
    event ItemPurchased(address indexed buyer, uint256 indexed tokenId, uint256 price);
    event ItemDelisted(address indexed seller, uint256 indexed tokenId);

    constructor(IERC20 _paymentToken, IERC721 _nftToken) Ownable(msg.sender) {
        paymentToken = _paymentToken;
        nftToken = _nftToken;
    }

    function listItem(uint256 tokenId, uint256 price) external nonReentrant {
        require(nftToken.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(price > 0, "Price must be greater than zero");

        // Transfer the NFT to the contract for escrow
        nftToken.transferFrom(msg.sender, address(this), tokenId);

        // Create a new listing
        listings[tokenId] = Listing({
            seller: msg.sender,
            price: price
        });

        emit ItemListed(msg.sender, tokenId, price);
    }

    function purchaseItem(uint256 tokenId) external nonReentrant {
        Listing memory listing = listings[tokenId];
        require(listing.price > 0, "Item not listed");

        // Transfer payment from buyer to seller
        paymentToken.transferFrom(msg.sender, listing.seller, listing.price);

        // Transfer the NFT from the contract to the buyer
        nftToken.transferFrom(address(this), msg.sender, tokenId);

        // Remove the listing
        delete listings[tokenId];

        emit ItemPurchased(msg.sender, tokenId, listing.price);
    }

    function delistItem(uint256 tokenId) external nonReentrant {
        Listing memory listing = listings[tokenId];
        require(listing.seller == msg.sender, "Not the seller");

        // Transfer the NFT back to the seller
        nftToken.transferFrom(address(this), msg.sender, tokenId);

        // Remove the listing
        delete listings[tokenId];

        emit ItemDelisted(msg.sender, tokenId);
    }
}