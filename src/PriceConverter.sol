// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter{
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256){
        //address 0x694AA1769357215DE4FAC081bf1f309aDC325306
        //ABI
        (,int256 price,,,) = priceFeed.latestRoundData();
        //price of eth in usd 2000.00000000
        return uint256(price* 1e10);
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal  view returns (uint256){
        //ETH?
        //2000_000000000000000000
        uint256 ethPrice = getPrice(priceFeed);
        //(2000_000000000000000000*1_000000000000000000)/1e18;
        //$2000 = 1ETH
        uint256 ethAmountInUSD = ( ethPrice * ethAmount )/1e18;
        return ethAmountInUSD;
    }
}
