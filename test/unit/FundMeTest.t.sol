// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import  {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
// import {StdCheats} from "forge-std/StdCheats.sol";
// import {HelperConfig} from "../script/HelperConfig.s.sol";

contract FundMeTest is Test{
    uint256 number=1;
    FundMe public fundMe;

    address USER =makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_Price=1;
    //address public constant USER = address(1);


    function setUp()  external {
        //number=2;
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive()  public {
        assertEq(fundMe.minUSD(), 5e18);
    }

    function testOwnerIsMsgSender()  public {
        assertEq(fundMe.getOwner() , msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }
    
    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); // hey, the next line, should revert!
        //assert(this tx fails/reverts)
        //uint256 cat =1;
        fundMe.fund(); //send 0 eth so it should fail
    }

    function testFundUpdatesFundedDataStructure() public{
        vm.prank(USER);// the next TX will be from USER
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(address(USER));
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddFunderToArrayOFunders() public {
        vm.prank(USER);// the next TX will be from USER
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded{
        vm.prank(USER);
        vm.expectRevert(); 
        fundMe.withdraw();        
    }

    function testWithdrawWithASingleFunder() public funded {
        //arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_Price);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 gasEnd=gasleft();
        uint256 gasUsed= (gasStart - gasEnd)* tx.gasprice;
        console.log(gasUsed);

        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance,endingOwnerBalance /* + gasUsed*/);
     }

     function testWithdrawFromMultipleFounders() public funded{

        //Arrange
        uint160 numberOfFunders=10;
        uint160 startingFunderIndex=1;
        for (uint160 i= startingFunderIndex; i<numberOfFunders; i++){
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value:SEND_VALUE}();
        }

        uint256 startingOwnerBalance=fundMe.getOwner().balance;
        uint256 startingFundMeBalance= address(fundMe).balance;

        //act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //assert
        assert(address(fundMe).balance==0);
        assert(startingFundMeBalance+startingOwnerBalance==fundMe.getOwner().balance);
    }

     function testWithdrawFromMultipleFoundersCheaper() public funded{

        //Arrange
        uint160 numberOfFunders=10;
        uint160 startingFunderIndex=1;
        for (uint160 i= startingFunderIndex; i<numberOfFunders; i++){
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value:SEND_VALUE}();
        }

        uint256 startingOwnerBalance=fundMe.getOwner().balance;
        uint256 startingFundMeBalance= address(fundMe).balance;

        //act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //assert
        assert(address(fundMe).balance==0);
        assert(startingFundMeBalance+startingOwnerBalance==fundMe.getOwner().balance);
     }
    // function testDemo()  public {
    //     // console.log(number);
    //     // console.log("hii devs");
    //     // assertEq(number, 2);
    // }
}