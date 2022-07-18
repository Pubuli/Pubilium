// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPubulium is IERC20 {

    function decimals() external view returns (uint8);

    function addStoreContract(address contractAddress)
    external
    returns(bool);

    function removeStoreContract(address contractAddress)
    external
    returns(bool);

    function mintFromStore(address recipient,uint256 amount)
    external
    returns(bool);

    function burnFromStore(address from,uint256 amount)
    external
    returns(bool);
}