// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

/**
 * @title SxtNumericQuery
 * @notice A generalized contract that requests a numeric result from an SXT query via Chainlink Functions.
 * Uses DON-hosted secrets for the SXT API Key.
 */
contract SxtNumericQuery is FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;

    // Chainlink Functions configuration for Avalanche Fuji
    address private constant ROUTER_ADDRESS = 0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0;
    bytes32 private constant DON_ID = 0x66756e2d6176616c616e6368652d66756a692d31000000000000000000000000; // fun-avalanche-fuji-1

    // State variables
    uint64 public subscriptionId;
    uint32 public gasLimit = 300000; // Adjust gas limit as needed
    bytes public latestResponse; // Raw response from the DON
    bytes public latestError;    // Raw error from the DON
    uint256 public latestNumericResult; // Stores the latest numeric result (scaled)

    // JavaScript source code for the Function
    string public source;

    // Event emitted when a new numeric result is successfully received
    event LatestNumericResultReceived(bytes32 indexed requestId, uint256 latestResult);
    // Event emitted on function error
    event RequestErrored(bytes32 indexed requestId, bytes error);

    /**
     * @param _subscriptionId Chainlink Functions subscription ID
     * @param _source JavaScript source code for the Function execution
     */
    constructor(uint64 _subscriptionId, string memory _source)
        FunctionsClient(ROUTER_ADDRESS)
        ConfirmedOwner(msg.sender)
    {
        subscriptionId = _subscriptionId;
        source = _source;
    }

    /**
     * @notice Triggers a Chainlink Functions request to execute the specified SXT query.
     * @param _query The SXT SQL query to execute.
     * @param slotID The DON secrets slot ID containing the SXT API Key.
     * @param version The DON secrets version.
     * @return requestId The ID of the sent request.
     */
    function requestNumericResult(
        string memory _query,
        uint8 slotID,
        uint64 version
    )
        external
        onlyOwner
        returns (bytes32 requestId)
    {
        string[] memory args = new string[](1);
        args[0] = _query;
        // API key is NOT in args, it comes from secrets

        FunctionsRequest.Request memory req;

        // Initialize request normally
        FunctionsRequest.initializeRequestForInlineJavaScript(req, source);

        // Set arguments separately
        FunctionsRequest.setArgs(req, args);

        // Add DON-hosted secrets reference using the library function
        FunctionsRequest.addDONHostedSecrets(req, slotID, version);

        if (bytes(source).length == 0) {
            revert("Source code not set");
        }

        // Standard _sendRequest
        requestId = _sendRequest(
            FunctionsRequest.encodeCBOR(req),
            subscriptionId,
            gasLimit,
            DON_ID
        );

        return requestId;
    }

     /**
     * @notice Callback function for Chainlink Functions response.
     * @param requestId The ID of the original request.
     * @param response The response data received from the DON (expected to be uint256).
     * @param err The error data received from the DON (if any).
     */
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        latestResponse = response;
        latestError = err;

        if (err.length > 0) {
            emit RequestErrored(requestId, err);
        } else {
            // Decode the uint256 response
            latestNumericResult = abi.decode(response, (uint256));
            emit LatestNumericResultReceived(requestId, latestNumericResult);
        }
    }

    // --- Admin Functions ---

    function setSubscriptionId(uint64 _subscriptionId) external onlyOwner {
        subscriptionId = _subscriptionId;
    }

    function setSource(string memory _source) external onlyOwner {
        source = _source;
    }

    function setGasLimit(uint32 _gasLimit) external onlyOwner {
        gasLimit = _gasLimit;
    }
} 