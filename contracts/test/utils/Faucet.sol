// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Faucet is Ownable {
    /// Address of the token that this faucet drips
    IERC20 public token;

    /// For rate limiting
    mapping(address => uint256) public nextRequestAt;
    /// Max token limit per request
    uint256 public limit = 100;

    /// @param _token The address of the faucet's token
    constructor(IERC20 _token) {
        token = _token;
    }

    /// Used to send the tokens
    /// @param _recipient The address of the tokens recipient
    /// @param _amount The amount of tokens required from the faucet
    function drip(address _recipient, uint256 _amount) external {
        require(_recipient != address(0), "INVALID_RECIPIENT");

        require(_amount <= limit, "EXCEEDS_LIMIT");

        require(nextRequestAt[_recipient] <= block.timestamp, "TRY_LATER");
        nextRequestAt[_recipient] = block.timestamp + (5 minutes);

        token.transfer(_recipient, _amount);
    }

    /// Used to set the max limit per request
    /// @dev This method is restricted and should be called only by the owner
    /// @param _limit The new limit for the tokens per request
    function setLimit(uint256 _limit) external onlyOwner {
        limit = _limit;
    }
}
