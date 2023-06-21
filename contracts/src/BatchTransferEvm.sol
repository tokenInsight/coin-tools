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

contract BatchTransferEvm {
    function batchTransferEther(address payable[] calldata recipients, uint256[] calldata amounts) external payable {
        _batchTransferEther(recipients, amounts, 2300);
    }

    function batchTransferEtherCustomGas(
        address payable[] calldata recipients,
        uint256[] calldata amounts,
        uint256 transferGas
    ) external payable {
        _batchTransferEther(recipients, amounts, transferGas);
    }

    // Batch transfer Ether
    function _batchTransferEther(address payable[] calldata recipients, uint256[] calldata amounts, uint256 transferGas)
        internal
    {
        uint256 len = recipients.length;
        require(len == amounts.length, "Recipients and amounts arrays must have the same length");

        for (uint256 i = 0; i < len;) {
            (bool succ,) = recipients[i].call{value: amounts[i], gas: transferGas}("");
            require(succ, "Failed to send Ether");
            unchecked {
                ++i;
            }
        }

        uint256 remainingBalance = address(this).balance;
        require(remainingBalance == 0, "Total transfer amount and individual transactions do not match");
    }

    // Batch transfer ERC20 tokens
    function batchTransferToken(address token, address[] calldata recipients, uint256[] calldata amounts) external {
        uint256 len = recipients.length;
        require(len == amounts.length, "Recipients and amounts arrays must have the same length");
        uint256 totalTokens = 0;
        for (uint256 i = 0; i < len;) {
            totalTokens += amounts[i];
            unchecked {
                ++i;
            }
        }

        safeTransferFrom(token, msg.sender, address(this), totalTokens);
        for (uint256 i = 0; i < len;) {
            safeTransfer(token, recipients[i], amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function batchTransferTokenSimple(address token, address[] calldata recipients, uint256[] calldata amounts)
        external
    {
        require(recipients.length == amounts.length, "Recipients and amounts arrays must have the same length");
        uint256 len = recipients.length;
        for (uint256 i = 0; i < len;) {
            safeTransferFrom(token, msg.sender, recipients[i], amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function safeTransfer(address token, address to, uint256 value) internal virtual {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }
}
