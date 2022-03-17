// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MyDefiProject {
    IERC20 dai;

    constructor(address daiAddress) public {
        // Address of deployed Interact_with_Dai.sol
        dai = IERC20(daiAddress);
    }

    function foo(address recipient, uint256 amount) external {
        // do something
        dai.transfer(recipient, amount); // from IERC20
        // note 10^(18) = 1 whole DAI (just like ether and wei)
    }
}
