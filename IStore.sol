// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Pubuli.sol";

interface IPubuliumStore {
    struct OneToken{
      address nftContractAddress;
      uint256 tokenID;
      string uri;
      address owner; 
      address guarantor;
      uint256 price;
      bool sold;
      uint256 soldAT;
      uint256 createdAT;
      uint256 removedAT;
    }

    function topPrice() external view returns(uint256);

    function singleNFTInfo(uint256 tokenIndex) external view returns(OneToken memory);

    function nftInfoList()
    external 
    view
    returns(OneToken[] memory);

    function addNFT(address nftContractAddress, uint256 tokenID, address recipient, uint256 price)
    external
    returns(bool);

    function removeNFT(uint256 tokenIndex)
    external
    returns(bool);

    function buyNFT(uint256 tokenIndex)
    external
    returns(bool);

    function sellNFT(uint256 tokenIndex)
    external
    returns(bool);

    event Mint(address indexed nftContractAddress, uint256 indexed tokenID, address indexed recipient, uint256 amount);

    event Buy(address indexed nftContractAddress, uint256 indexed tokenID, address indexed buyer, uint256 amount);

    event Sell(address indexed nftContractAddress, uint256 indexed tokenID, address indexed seller, uint256 amount);
    
    event Remove(uint256 indexed tokenID);
}