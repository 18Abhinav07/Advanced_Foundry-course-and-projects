// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {ManualToken} from "src/ERC20_Token/ManualMyToken.sol";

contract DeployManualMyToken is Script {
    uint256 public constant INITIAL_SUPPLY = 1000000;
    string public constant TOKEN_NAME = "MYTOKEN";
    string public constant TOKEN_SYMBOL = "MTC";

    function run() external returns (ManualToken) {
        console2.log("Deploying ManualMyToken");

        vm.startBroadcast();
        ManualToken _manualToken = new ManualToken(
            INITIAL_SUPPLY,
            TOKEN_NAME,
            TOKEN_SYMBOL
        );
        vm.stopBroadcast();
        return _manualToken;
    }
}
