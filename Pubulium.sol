// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IStore.sol";

contract Pubulium is ERC20, Ownable {

    mapping(address => uint256) private _balances;

    mapping(uint256 => address) private _storeContracts;
    uint256 _maxcid=0;

    mapping(address => uint256) private _storeContractPermissions;

    constructor() ERC20("Pubulium", "PBL") {
    }

    function decimals() public view virtual override returns (uint8) {
        return 2;
    }

    function addStoreContract(address contractAddress)
    onlyOwner
    public
    returns(bool)
    {
        _maxcid++;
        _storeContracts[_maxcid]=contractAddress;
        _storeContractPermissions[contractAddress]=1;
        return true;
    }

    function removeStoreContract(address contractAddress)
    onlyOwner
    public
    returns(bool)
    {
        IPubuliumStore ps = IPubuliumStore(contractAddress);
        require(balanceOf(_msgSender())>=ps.topPrice(),"Pubulium: Insufficient balance!");
        _storeContractPermissions[contractAddress]=0;
        _burn(_msgSender(), ps.topPrice());
        return true;
    }

    function mintFromStore(address recipient,uint256 amount)
    public
    returns(bool){
        require(_storeContractPermissions[_msgSender()]==1,"Pubulium: Access denied!");
        _mint(recipient, amount);
        return true;
    }

    function burnFromStore(address from,uint256 amount)
    public
    returns(bool){
        require(_storeContractPermissions[_msgSender()]==1,"Pubulium: Access denied!");
        _burn(from, amount);
        return true;
    }
}