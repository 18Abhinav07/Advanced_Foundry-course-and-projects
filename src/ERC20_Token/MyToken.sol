// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title  My Token
 * @author Abhinav Pangaria
 * @notice This is a simple ERC20 based token.
 */

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    constructor() ERC20("MyToken", "MTC") {
        _mint(msg.sender, 1000 ether);
    }
}
