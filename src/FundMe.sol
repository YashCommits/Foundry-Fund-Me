// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {

    using PriceConverter for uint256; 
    
    uint256 public constant minUSD = 5e18;

    address[] private s_funders;
    mapping (address => uint256 ) private s_addressToAmountFunded;

    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner=msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        //myvalue = myvalue + 2;
        require(msg.value.getConversionRate(s_priceFeed) >= minUSD, "didn't sended enough Eth");
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = s_addressToAmountFunded[msg.sender] + msg.value;
    }

    function getVersion() public view returns (uint256){
        return  s_priceFeed.version();       
    }

    function cheaperWithdraw() public onlyOwner{
        uint256 funderLength = s_funders.length;
        for(uint256 funderIndex=0; funderIndex<funderLength; funderIndex++){
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder]=0;
        }
        s_funders= new address[](0);
        (bool callSuccess, )= payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "call failed");
    }

    function withdraw() public onlyOwner{
        //require(msg.sender==owner, "must be owner!!!");
        for(uint256 funderIndex=0; funderIndex<s_funders.length; funderIndex++){
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder]=0;
        }

        //reset the array
        s_funders= new address[](0);

        //actually withdraw the funds
        //transfer
        //payable(msg.sender).transfer(address(this).balance);
        //send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess,"send failed");
        //call
        (bool callSuccess, )= payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "call failed");
    }

    modifier onlyOwner(){
        //require(msg.sender==i_owner,"Sender is not owner!");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    //what is someone send eth with fund function
    //recieve & fallback special function
    receive() external payable { fund(); }
    fallback() external payable { fund(); }
    
        /* view /pure functions (getters)*/
    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256){
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address){
        return s_funders[index];
    }

    function getOwner() external view returns (address){
        return i_owner;
    }
}
