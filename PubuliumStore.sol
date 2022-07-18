// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/utils/Context.sol";
import "./IPubuli.sol";
import "./IPubulium.sol";

contract PubuliumStore is Ownable{
    uint256 private _currentTokenIndex;

    string private _name;

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

    mapping(uint256 => OneToken) private _nftTokens;

    uint256 private _topPrice=0;

    address _pubuliumAddress;

    constructor(address pubuliumAddress_,string memory name_) {
        _currentTokenIndex=0;
        _pubuliumAddress=pubuliumAddress_;
        _name=name_;
    }

    function topPrice() public view returns(uint256){
        return _topPrice;
    }

    function singleNFTInfo(uint256 tokenIndex) public  view returns(OneToken memory)
    {
        return _nftTokens[tokenIndex];
    }

    function nftInfoList()
    public 
    view
    returns(OneToken[] memory)
    {
        OneToken[] memory tokens=new OneToken[]( (_currentTokenIndex+1) );
        for(uint8 i=1; i<=_currentTokenIndex; i++){
            tokens[i]=_nftTokens[i];
        }
        return tokens;
    }

    function addNFT(address nftContractAddress, uint256 tokenID, address recipient, uint256 price)
    public
    onlyOwner
    returns(bool)
    {
        uint256 newTokenIndex=_currentTokenIndex+1;
        require(_nftTokens[newTokenIndex].createdAT==0,"Pubulium: Token already added.");
        IPubuli nftContract=IPubuli(nftContractAddress);
        require(nftContract.getApproved(tokenID)==address(this),"Pubulium: Token not usable.");
        (string memory uri, uint256 dividend, address owner, address guarantor) = nftContract.tokenInfo(tokenID);
        require(bytes(uri).length > 0,"Pubulium: Token signed PDF uri not setted.");
        OneToken memory newToken = OneToken(nftContractAddress,tokenID,uri,owner,guarantor,price,false,0,block.timestamp,0);
        _currentTokenIndex=newTokenIndex;
        _nftTokens[newTokenIndex]=newToken;
        _mint(recipient, price);
        nftContract.transferFrom(_msgSender(),address(this),tokenID);
        _topPrice+=price;
        emit Mint(nftContractAddress,tokenID,recipient,price);
        return true;
    }

    function removeNFT(uint256 tokenIndex)
    public
    onlyOwner
    returns(bool)
    {
        require(tokenIndex<=_currentTokenIndex,"Pubulium: Index Is Wrong.");
        OneToken memory nfToken = _nftTokens[tokenIndex];
        IPubuli nftContract=IPubuli(nfToken.nftContractAddress);
        require(nftContract.ownerOf(nfToken.tokenID)==address(this),"Pubulium: NFT sold!.");
        require(nfToken.sold==false,"Pubulium: NFT Sold!.");
        require(balanceOf(_msgSender())>=nfToken.price,"Pubulium: insufficient balance!.");
        _burn(_msgSender(),nfToken.price);
        nfToken.removedAT=block.timestamp;
        _nftTokens[tokenIndex]=nfToken;
        nftContract.transferFrom(address(this),_msgSender(),nfToken.tokenID);
        _topPrice-=nfToken.price;
        emit Remove(tokenIndex);
        return true;
    }

    function buyNFT(uint256 tokenIndex)
    public
    returns(bool){
        require(_nftTokens[tokenIndex].createdAT!=0,"Pubulium: Token not avaible.");
        OneToken memory nfToken = _nftTokens[tokenIndex];
        require(nfToken.sold==false,"Pubulium: Token already sold.");
        require(balanceOf(_msgSender())>=nfToken.price,"Pubulium: Insufficient balance.");
        IPubuli nftContract=IPubuli(nfToken.nftContractAddress);
        nfToken.sold=true;
        nfToken.soldAT=block.timestamp;
        _nftTokens[tokenIndex]=nfToken;
        _burn(_msgSender(),nfToken.price);
        nftContract.transferFrom(address(this),_msgSender(),nfToken.tokenID);
        emit Buy(nfToken.nftContractAddress,nfToken.tokenID, _msgSender(), nfToken.price);
        return true;
    }

    function calgulateSellNFT(uint256 tokenIndex)
    public
    view
    returns(uint256)
    {
        require(_nftTokens[tokenIndex].createdAT!=0,"Pubulium: Token not avaible.");
        OneToken memory nfToken = _nftTokens[tokenIndex];
        IPubuli nftContract=IPubuli(nfToken.nftContractAddress);
        uint256 time = block.timestamp-nfToken.soldAT;
        require(nftContract.getApproved(nfToken.tokenID)==address(this),"Pubulium: NFT not transferable.");
        require(nftContract.ownerOf(nfToken.tokenID)==_msgSender(),"Pubulium: Seller are not token owner.");
        require(time>=3*60,"Pubulium: NFT can not sell back yet.");
        uint256 commision=0;
        if( time>=(3*60) &&  time<(6*60)){
            commision=(nfToken.price/100)*3;
        }else if( time>=(6*60) &&  time<(9*60)){
            commision=(nfToken.price/100)*2;
        }else if( time>=(9*60) &&  time<(12*60)){
            commision=(nfToken.price/100)*1;
        }

        uint256 finalPrice=nfToken.price;
        if(commision>0){
        uint256 allPrice=0;
        for(uint256 i=1; i<=_currentTokenIndex; i++){
            if(_nftTokens[i].sold==false){
                allPrice+=_nftTokens[i].price;
            }
        }
        uint256 topComission=0;
        uint256 oneTokenComission=(((10**14)*(commision/100))/((10**6)*(allPrice/100)));
        for(uint256 i=1; i<=_currentTokenIndex; i++){
            if(_nftTokens[i].sold==false){
                uint256 singularComission=((oneTokenComission*(_nftTokens[i].price/100))/10**8)*100;
                topComission+=singularComission;
            }
        }
        finalPrice=finalPrice-topComission;
        }
        return finalPrice;
    }

    function sellNFT(uint256 tokenIndex)
    public
    returns(bool)
    {
        require(_nftTokens[tokenIndex].createdAT!=0,"Pubulium: Token not avaible.");
        OneToken memory nfToken = _nftTokens[tokenIndex];
        IPubuli nftContract=IPubuli(nfToken.nftContractAddress);
        IPubulium pubulium = IPubulium(_pubuliumAddress);
        uint256 time = block.timestamp-nfToken.soldAT;
        require(nftContract.getApproved(nfToken.tokenID)==address(this),"Pubulium: NFT not transferable.");
        require(nftContract.ownerOf(nfToken.tokenID)==_msgSender(),"Pubulium: Seller are not token owner.");
        require(time>=3*60,"Pubulium: NFT can not sell back yet.");
        uint256 commision=0;
        if( time>=(3*60) &&  time<(6*60)){
            commision=(nfToken.price/100)*3;
        }else if( time>=(6*60) &&  time<(9*60)){
            commision=(nfToken.price/100)*2;
        }else if( time>=(9*60) &&  time<(12*60)){
            commision=(nfToken.price/100)*1;
        }

        uint256 finalPrice=nfToken.price;
        if(commision>0){
        uint256 allPrice=0;
        for(uint256 i=1; i<=_currentTokenIndex; i++){
            if(_nftTokens[i].sold==false){
                allPrice+=_nftTokens[i].price;
            }
        }
        uint256 topComission=0;
        uint256 oneTokenComission=(((10**14)*(commision/100))/((10**6)*(allPrice/100)));
        for(uint256 i=1; i<=_currentTokenIndex; i++){
            if(_nftTokens[i].sold==false){
                uint256 singularComission=((oneTokenComission*(_nftTokens[i].price/100))/10**8)*100;
                topComission+=singularComission;
                _mint(address(this), singularComission);
                pubulium.approve(_nftTokens[i].nftContractAddress,singularComission);
                nftContract.sendBonus(_nftTokens[i].tokenID,singularComission);
            }
        }
        finalPrice=finalPrice-topComission;
        }

        _mint(_msgSender(), finalPrice);
        nfToken.sold=false;
        nfToken.soldAT=0;
        _nftTokens[tokenIndex]=nfToken;
        nftContract.transferFrom(_msgSender(),address(this),nfToken.tokenID);
        emit Sell(nfToken.nftContractAddress, nfToken.tokenID, _msgSender(), nfToken.price);
        return true;
    }

    function balanceOf(address from)
    internal
    virtual
    returns(uint256)
    {
        IPubulium pubulium = IPubulium(_pubuliumAddress);
        return pubulium.balanceOf(from);
    }

    function _mint(address recipient,uint256 amount)
    internal
    {
        IPubulium pubulium = IPubulium(_pubuliumAddress);
        pubulium.mintFromStore(recipient,amount);
    }

    function _burn(address from,uint256 amount)
    internal
    {
        IPubulium pubulium = IPubulium(_pubuliumAddress);
        pubulium.burnFromStore(from,amount);
    }

    event Mint(address indexed nftContractAddress, uint256 indexed tokenID, address indexed recipient, uint256 amount);

    event Buy(address indexed nftContractAddress, uint256 indexed tokenID, address indexed buyer, uint256 amount);

    event Sell(address indexed nftContractAddress, uint256 indexed tokenID, address indexed seller, uint256 amount);
    
    event Remove(uint256 indexed tokenID);
}