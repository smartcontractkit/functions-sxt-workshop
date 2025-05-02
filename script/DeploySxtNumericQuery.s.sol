// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {SxtNumericQuery} from "../src/SxtNumericQuery.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol"; // Import needed for Request struct if used directly, though not here.

/**
 * @notice Deploys the SxtNumericQuery contract.
 * @dev Reads required values (RPC_URL, PRIVATE_KEY, FUNCTIONS_SUBSCRIPTION_ID)
 *      from environment variables. Ensure they are set before running.
 *      Example: source .env
 * Reads the JavaScript source code from functions-src/sxt-bitcoin-request.js.
 * Run with: forge script script/DeploySxtNumericQuery.s.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
 */
contract DeploySxtNumericQuery is Script {
    string constant JS_SOURCE_PATH = "functions-src/sxt-bitcoin-request.js";

    function run() external {
        // --- Configuration ---

        // Get Subscription ID from environment variable
        uint256 subscriptionId_uint256 = vm.envOr("FUNCTIONS_SUBSCRIPTION_ID", uint256(0));
        if (subscriptionId_uint256 == 0) {
            revert("FUNCTIONS_SUBSCRIPTION_ID environment variable not set or is 0.");
        }
        // Check if the value fits in uint64 before casting
        if (subscriptionId_uint256 > type(uint64).max) {
            revert("FUNCTIONS_SUBSCRIPTION_ID is too large to fit in uint64.");
        }
        uint64 subscriptionId = uint64(subscriptionId_uint256);

        console.log("Using Functions Subscription ID:", subscriptionId);

        // Read JavaScript source code from file
        string memory sourceCode = vm.readFile(JS_SOURCE_PATH);
        if (bytes(sourceCode).length == 0) {
            revert("Failed to read JavaScript source code from file or file is empty.");
        }

        // Get deployer private key from environment variable
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0));
         if (deployerPrivateKey == 0) {
            revert("PRIVATE_KEY environment variable not set.");
        }

        // --- Deployment ---
        console.log("Starting deployment...");

        vm.startBroadcast(deployerPrivateKey);

        SxtNumericQuery sxtContract = new SxtNumericQuery(subscriptionId, sourceCode);

        vm.stopBroadcast();

        console.log("SxtNumericQuery contract deployed at:", address(sxtContract));
    }
} 