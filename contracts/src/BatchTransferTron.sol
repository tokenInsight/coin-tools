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

import "./BatchTransferEvm.sol";

contract BatchTransferTron is BatchTransferEvm {
    function safeTransfer(address token, address to, uint256 value) internal override {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        if (token == 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C) {
            (bool success,) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
            require(success, "TransferHelper: TRANSFER_FAILED, tron-usdt");
            return;
        }
        super.safeTransfer(token, to, value);
    }
}
