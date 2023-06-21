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

import "../../src/BatchTransferEvm.sol";

contract BatchTransferTron is BatchTransferEvm {
    address public tronusdt;

    function setTronusdt(address _a) public {
        tronusdt = _a;
    }

    function safeTransfer(address token, address to, uint256 value) internal override {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        if (token == tronusdt) {
            (bool success,) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
            require(success, "TransferHelper: TRANSFER_FAILED, tron-usdt");
            return;
        }
        super.safeTransfer(token, to, value);
    }
}
