// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// imoprts

import "./PriceConverter.sol";

// Error codes

error FundMe__NotOwner();

// contract

/**
 * @title Acontract for crowd funding
 * @author Evans Atoko
 * @notice This contract is to demo a sample funding contract
 * @dev This implements price feeds as our library
 */

contract FundMe {
    // type declarations
    using PriceConverter for uint256;

    // state variables
    uint256 public constant MINUMUM_USD = 50 * 1e18;
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountSend;
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    //Modifiers

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

 

    /**
     * @notice This function funds this contract
     */

    function fund() public payable {
        // Want to be able to set the minimu fund amount in usd
        // 1 how do we send ETH to this contract
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINUMUM_USD,
            "didn't send enough"
        );
        s_funders.push(msg.sender);
        s_addressToAmountSend[msg.sender] = msg.value;
    }

    function withdraw() public payable onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountSend[funder] = 0;
        }
        // reset the array
        s_funders = new address[](0);

        // actually withdraw the funds

        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "call failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountSend[funder] = 0;
        }
        s_funders = new address[](0);

        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountSend(
        address funder
    ) public view returns (uint256) {
        return s_addressToAmountSend[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
