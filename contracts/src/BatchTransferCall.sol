/* tokeninsight.com
                                                                                       
     ,--.         ,--.                  ,--.               ,--.       ,--.       ,--.   
   ,-'  '-. ,---. |  |,-. ,---. ,--,--, |  |,--,--,  ,---. `--' ,---. |  ,---. ,-'  '-. 
   '-.  .-'| .-. ||     /| .-. :|      \|  ||      \(  .-' ,--.| .-. ||  .-.  |'-.  .-' 
     |  |  ' '-' '|  \  \\   --.|  ||  ||  ||  ||  |.-'  `)|  |' '-' '|  | |  |  |  |   
     `--'   `---' `--'`--'`----'`--''--'`--'`--''--'`----' `--'.`-  / `--' `--'  `--'   
                                                               `---'     
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Simplified IERC20 interface containing only the required functions for this contract
interface IERC20 {
    function transfer(address recipient, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
}

contract BatchTransferCall {
    uint256 private _inProgress = 1;
    // simple modifier to prevent reentrancy

    modifier preventReentrancy() {
        require(_inProgress != 2, "Batch transfer already in progress");
        _inProgress = 2;
        _;
        _inProgress = 1;
    }

    function batchTransferEther(address payable[] calldata recipients, uint256[] calldata amounts)
        external
        payable
        preventReentrancy
    {
        require(recipients.length == amounts.length, "Recipients and amounts arrays must have the same length");

        for (uint256 i = 0; i < recipients.length; i++) {
            (bool succ,) = recipients[i].call{value: amounts[i]}("");
            require(succ, "Failed to send Ether");
        }

        uint256 remainingBalance = address(this).balance;
        require(remainingBalance == 0, "Total transfer amount and individual transactions do not match");
    }

    // Batch transfer ERC20 tokens
    function batchTransferToken(IERC20 token, address[] calldata recipients, uint256[] calldata amounts) external {
        require(recipients.length == amounts.length, "Recipients and amounts arrays must have the same length");

        uint256 totalTokens = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            totalTokens += amounts[i];
        }

        token.transferFrom(msg.sender, address(this), totalTokens);

        for (uint256 i = 0; i < recipients.length; i++) {
            token.transfer(recipients[i], amounts[i]);
        }
    }

    function batchTransferTokenSimple(IERC20 token, address[] calldata recipients, uint256[] calldata amounts)
        external
    {
        require(recipients.length == amounts.length, "Recipients and amounts arrays must have the same length");
        for (uint256 i = 0; i < recipients.length; i++) {
            token.transferFrom(msg.sender, recipients[i], amounts[i]);
        }
    }
}
