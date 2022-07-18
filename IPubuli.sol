//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPubuli is IERC721{

    function mintNFT(address recipient,address guarantorWallet,address operatorWallet)
    external
    returns (uint256);


    function setURI(uint256 tokenID,string memory _tokenURI)
    external
    returns(bool);

    function totalSupply() external view returns(uint256);

    function maxTokenId() external view
    returns(uint256);

    function tokenInfo(uint256 tokenID)
    external
    view
    returns(string memory uri, uint256 dividend, address owner, address guarantor);

    function sendDividend(uint256 tokenID,uint256 dividend)
    external
    returns(bool);

    function withdrawDividend(uint256 tokenID)
    external
    returns(bool);

    function sendBonus(uint256 tokenID,uint256 bonus)
    external
    returns(bool);

    function withdrawBonus(uint256 tokenID)
    external
    returns(bool);

    function ownerNFTs(address owner)
    external
    view
    returns(uint256[] memory);

    function burn(uint256 tokenID)
    external
    returns(bool);
    
    event Mint(uint256 indexed tokenID, address indexed recipient, address indexed operator);

    event SetURI(uint256 indexed tokenID, string indexed URI);

    event SentDividend(uint256 indexed tokenID,uint256 indexed value);

    event WithdrewDividend(uint256 indexed tokenID,uint256 indexed value);

    event Burned(uint256 indexed tokenID);
}
