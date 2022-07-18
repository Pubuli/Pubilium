//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PubuliA is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private _totalSupply;

    address public _parentNFTContract;

    uint256 public _parentTokenID;

    bool public _parentNFTTransferred;

    mapping(uint256 => address) private _nftGuarantorWallets;

    mapping(uint256 => address) private _nftOperatorWallets;

    mapping(uint256 => uint256) private _nftDividendBalances;

    mapping(uint256 => uint256) private _totalNftDividendBalances;

    mapping(address => uint256[]) private _ownerNFTs;

    address private _dividendContract;

    mapping(uint256 => uint256) private _nftBonusBalances;

    mapping(uint256 => uint256) private _totalNftBonusBalances;

    address private _bonusContract;

    modifier onlyPayloadSize(uint size) {
          assert(msg.data.length >= size + 4);
      _;
    }

    constructor(address dividendContract_,address bonusContract_,address parentNFTContract_,uint256 parentTokenID_) ERC721("PubuliA", "PBA") {
        _dividendContract=dividendContract_;
        _bonusContract=bonusContract_;
        _parentNFTContract=parentNFTContract_;
        _parentTokenID=parentTokenID_;
        _parentNFTTransferred=false;
    }

    function transferParentNft()
    onlyOwner
    public
    returns (bool)
    {
        ERC721 parent=ERC721(_parentNFTContract);
        require(parent.getApproved(_parentTokenID)==address(this),"PubuliA: Token not usable.");
        parent.transferFrom(_msgSender(),address(this),_parentTokenID);
        _parentNFTTransferred=true;
        return true;
    }

    function mintNFT(address recipient,address guarantorWallet,address operatorWallet)
    public onlyOwner
    returns (uint256)
    {
        require(_parentNFTTransferred==true,"PubuliA: Parent token not transferred.");

        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _totalSupply++;
        _ownerNFTs[recipient].push(newItemId);
        _nftGuarantorWallets[newItemId]=guarantorWallet;
        _nftOperatorWallets[newItemId]=operatorWallet;
        emit Mint(newItemId,recipient,operatorWallet);
        return newItemId;
    }


    function setURI(uint256 tokenID,string memory _tokenURI)
    public onlyOwner
    returns(bool)
    {
        require(bytes(tokenURI(tokenID)).length == 0,"PubuliA: Signed PFD URI already set!");
        _setTokenURI(tokenID, _tokenURI);
        emit SetURI(tokenID,_tokenURI);
        return true;
    }

    function totalSupply() public view returns(uint256)
    {
        return _totalSupply;
    }

    function maxTokenId() public view returns(uint256)
    {
        return _tokenIds.current();
    }

    function tokenInfo(uint256 tokenID)
    public
    view
    returns(string memory uri, uint256 dividend, uint256 total_dividend, address owner, address guarantor, uint256 bonus, uint256 total_bonus)
    {
        uri=tokenURI(tokenID);
        dividend=_nftDividendBalances[tokenID];
        total_dividend=_totalNftDividendBalances[tokenID];
        owner=ownerOf(tokenID);
        guarantor=_nftGuarantorWallets[tokenID];
        bonus=_nftBonusBalances[tokenID];
        total_bonus=_totalNftBonusBalances[tokenID];
    }

    function sendDividend(uint256 tokenID,uint256 dividend)
    public onlyOwner
    returns(bool)
    {
        require(_msgSender()==_nftOperatorWallets[tokenID],"PubuliA: Sender must be operator!");
        IERC20 token=IERC20(_dividendContract);
        require(token.allowance(_msgSender(), address(this))>=dividend,"PubuliA: Sender must approve dividend!");
        _nftDividendBalances[tokenID]+=dividend;
        _totalNftDividendBalances[tokenID]+=dividend;
        require(token.transferFrom(_msgSender(),address(this),dividend));
        emit SentDividend(tokenID,dividend);
        return true;
    }

    function withdrawDividend(uint256 tokenID)
    public
    returns(bool)
    {
        require(ownerOf(tokenID)==_msgSender(),"PubuliA: Sender must have this token!");
        IERC20 token=IERC20(_dividendContract);
        uint256 balance=_nftDividendBalances[tokenID];
        _nftDividendBalances[tokenID]=0;
        require(token.transfer(_msgSender(),balance));
        emit WithdrewDividend(tokenID,balance);
        return true;
    }

    function sendBonus(uint256 tokenID,uint256 bonus)
    public
    returns(bool)
    {
        IERC20 token=IERC20(_bonusContract);
        require(token.allowance(_msgSender(), address(this))>=bonus,"PuBuLi: Sender must approve bonus!");
        _nftBonusBalances[tokenID]+=bonus;
        _totalNftBonusBalances[tokenID]+=bonus;
        require(token.transferFrom(_msgSender(),address(this),bonus));
        emit SentBonus(tokenID,bonus);
        return true;
    }

    function withdrawBonus(uint256 tokenID)
    public
    returns(bool)
    {
        require(ownerOf(tokenID)==_msgSender(),"PuBuLi: Sender must have this token!");
        IERC20 token=IERC20(_bonusContract);
        uint256 balance=_nftBonusBalances[tokenID];
        _nftBonusBalances[tokenID]=0;
        require(token.transfer(_msgSender(),balance));
        emit WithdrewBonus(tokenID,balance);
        return true;
    }

    function withdrawParent()
    public
    returns(bool){
        bool procced=true;
        for(uint8 i=1; i<=_tokenIds.current(); i++){
            if(ownerOf(i)!=_msgSender()){
                procced=false;
                break;
            }
        }
        require(procced==true,"PubuliA: Sender must have all tokens!");
        _parentNFTTransferred=false;
        ERC721 parent = ERC721(_parentNFTContract);
        parent.transferFrom(address(this),_msgSender(),_parentTokenID);
        return true;
    }

    /*function withdrawParentDividend()
    public
    returns(bool){
        ERC721 parent = ERC721(_parentNFTContract);
    }

    function withdrawParentBonus()
    public
    returns(bool){
        ERC721 parent = ERC721(_parentNFTContract);
    }*/

    function ownerNFTs(address owner)
    public
    view
    returns(uint256[] memory)
    {
        return _ownerNFTs[owner];
    }

    function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
    ) internal override virtual {
        if(from==address(0)){
            return;
        }
        uint256[] memory newSenderTokens = new uint256[]( _ownerNFTs[from].length-1 );
        uint256 cnt=0;
        for(uint256 i = 0; i< _ownerNFTs[from].length; i++){
            if(_ownerNFTs[from][i] != tokenId){
                newSenderTokens[cnt]=_ownerNFTs[from][i];
                cnt++;
            }
        }
        _ownerNFTs[from]=newSenderTokens;
        _ownerNFTs[to].push(tokenId);
    }

    function burn(uint256 tokenID)
    public
    onlyOwner
    returns(bool)
    {
        require(_msgSender()==_nftGuarantorWallets[tokenID],"PubuliA: Sender mustbe guarantor!");
        require(ownerOf(tokenID)==_msgSender(),"PubuliA: Sender must have this token!");
        require(_totalNftDividendBalances[tokenID]==0,"PubuliA: token must not have dividend!");
        _burn(tokenID);
        emit Burned(tokenID);
        return true;
    }
    
    event Mint(uint256 indexed tokenID, address indexed recipient, address indexed operator);

    event SetURI(uint256 indexed tokenID, string indexed URI);

    event SentDividend(uint256 indexed tokenID,uint256 indexed value);

    event WithdrewDividend(uint256 indexed tokenID,uint256 indexed value);

    event SentBonus(uint256 indexed tokenID,uint256 indexed value);

    event WithdrewBonus(uint256 indexed tokenID,uint256 indexed value);                                                                                                                                                                                                                         

    event Burned(uint256 indexed tokenID);
}
