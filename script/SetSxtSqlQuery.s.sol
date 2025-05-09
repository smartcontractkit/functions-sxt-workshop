// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {SxtNumericQuery} from "../src/SxtNumericQuery.sol";

/**
 * @title SetSxtSqlQuery
 * @notice Sets the SQL query on a deployed SxtNumericQuery contract.
 * @dev Reads the target contract address (CONTRACT_ADDRESS) and broadcaster's
 *      private key (PRIVATE_KEY) from environment variables.
 *      Ensure environment variables are set (e.g., export CONTRACT_ADDRESS=...; source .env).
 * Run with: forge script script/SetSxtSqlQuery.s.sol --rpc-url $RPC_URL --broadcast -vvvv
 */
contract SetSxtSqlQuery is Script {
    // The SXT SQL query to set
    // Note: This query was previously in RequestSxtData.s.sol
    string public constant NEW_SXT_QUERY =
        "SELECT AVG(BITCOIN.STATS.AVG_FEERATE) AS AVG_FEE FROM BITCOIN.STATS WHERE TIME_STAMP >= CURRENT_DATE - INTERVAL 7 days AND TIME_STAMP < CURRENT_DATE + INTERVAL 1 day;";

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

        vm.startBroadcast(broadcasterPrivateKey);

        SxtNumericQuery sxtContract = SxtNumericQuery(contractAddress);

        console.log("Setting SQL query on contract:", address(sxtContract));
        console.log("New query:", NEW_SXT_QUERY);

        sxtContract.setSqlQuery(NEW_SXT_QUERY);

        vm.stopBroadcast();

        console.log("Successfully set SQL query on SxtNumericQuery contract.");
    }
} 
