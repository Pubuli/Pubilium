// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BuyPubulium is Ownable {
    address public _pubuliumAddress;
    address public _usdtAddress;
    uint256 public _ratioOnePubulium;

    constructor(address pubuliumaddress,address usdtaddress,uint256 ratio) {
        _pubuliumAddress=pubuliumaddress;
        _usdtAddress=usdtaddress;
        _ratioOnePubulium=ratio;
    }

    function ratio() public view virtual returns (uint256) {
        return _ratioOnePubulium;
    }
    function getRemainingFund() public view virtual returns (uint256) {
        ERC20 pubulium=ERC20(_pubuliumAddress);
        return pubulium.balanceOf(address(this));
    }
    function calgulateFromUsdt(uint256 amount) public view virtual returns (uint256) {
        return amount/_ratioOnePubulium;
    }
    function calgulateFromPubulium(uint256 amount) public view virtual returns (uint256) {
        return amount*_ratioOnePubulium;
    }



    function setRatio(uint256 ratio)
    public
    onlyOwner
    returns(bool)
    {
        _ratioOnePubulium=ratio;
        emit setRati(ratio);
        return true;
    }


    function buy(uint256 usdtAmount)
    public
    returns(bool)
    {
        ERC20 pubulium=ERC20(_pubuliumAddress);
        ERC20 usdt=ERC20(_usdtAddress);
        require(usdt.allowance(_msgSender(),address(this))>=usdtAmount,"BuyPubulium: Sender must approve amount!");
        uint256 pubuliumAmount=usdtAmount/_ratioOnePubulium;
        require(pubulium.balanceOf(address(this))>=pubuliumAmount,"BuyPubulium: Infufficient fund!");
        usdt.transferFrom(_msgSender(),address(this),usdtAmount);
        pubulium.transfer(_msgSender(),pubuliumAmount);
        emit buyPubulium(_msgSender(),pubuliumAmount,usdtAmount);
        return true;
    }


    function withdrawUsdt()
    public
    onlyOwner
    returns(bool)
    {
        ERC20 usdt=ERC20(_usdtAddress);
        uint256 balance=usdt.balanceOf(address(this));
        usdt.transfer(_msgSender(),balance);
        emit withdrewUsdt(balance);
        return true;
    }


    function withdrawPubulium()
    public
    onlyOwner
    returns(bool)
    {
        ERC20 pubulium=ERC20(_pubuliumAddress);
        uint256 balance=pubulium.balanceOf(address(this));
        pubulium.transfer(_msgSender(),balance);
        emit withdrewPubulium(balance);
        return true;
    }

    event setRati(uint256 indexed ratio);
    event buyPubulium(address indexed buyer,uint256 indexed pubuliumAmount,uint256 indexed usdtAmount);
    event withdrewUsdt(uint256 indexed amount);
    event withdrewPubulium(uint256 indexed amount);
}