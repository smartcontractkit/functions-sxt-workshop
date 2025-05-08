// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {SxtNumericQuery} from "../src/SxtNumericQuery.sol"; // Import the correct contract

/**
 * @title RequestSxtData
 * @notice Sends a request to the SxtNumericQuery contract.
 * @dev Reads the target contract address from the CONTRACT_ADDRESS environment variable.
 *      Reads RPC_URL and PRIVATE_KEY from environment variables.
 *      Ensure environment variables are set (e.g., export CONTRACT_ADDRESS=...; source .env).
 * Run with: forge script script/RequestSxtData.s.sol --rpc-url $RPC_URL --broadcast -vvvv
 */
contract RequestSxtData is Script {
    // The SXT SQL query to execute
    string public constant SXT_QUERY =
        "SELECT AVG(BITCOIN.STATS.AVG_FEERATE) FROM BITCOIN.STATS WHERE TIME_STAMP >= CURRENT_DATE - INTERVAL '3 days' AND TIME_STAMP < CURRENT_DATE + INTERVAL '1 day';";

    // DON secrets slot ID (assuming 0)
    uint8 constant SLOT_ID = 0;

    function run() external {
        // Get the contract address from the environment variable
        address contractAddress = vm.envAddress("CONTRACT_ADDRESS");
        if (contractAddress == address(0)) {
            revert("CONTRACT_ADDRESS environment variable not set or invalid");
        }

        // Get the broadcaster/sender private key from environment variable
        uint256 broadcasterPrivateKey = vm.envUint("PRIVATE_KEY");
        if (broadcasterPrivateKey == 0) {
            revert("PRIVATE_KEY environment variable not set.");
        }

        // Get Functions Secrets version from environment variable
        uint256 secretsVersion_uint256 = vm.envUint("FUNCTIONS_SECRETS_VERSION");
        if (secretsVersion_uint256 == 0) {
            revert("FUNCTIONS_SECRETS_VERSION environment variable not set or is 0.");
        }
        if (secretsVersion_uint256 > type(uint64).max) {
            revert("FUNCTIONS_SECRETS_VERSION is too large to fit in uint64.");
        }
        uint64 secretsVersion = uint64(secretsVersion_uint256);

        vm.startBroadcast(broadcasterPrivateKey);

        SxtNumericQuery sxtContract = SxtNumericQuery(contractAddress);

        // Call the request function passing query, slot ID, and version
        bytes32 requestId = sxtContract.requestNumericResult(SXT_QUERY, SLOT_ID, secretsVersion);

        vm.stopBroadcast();
    }
}
