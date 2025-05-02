# Chainlink Functions SXT Demo (Avalanche Fuji)

This project demonstrates how to use Chainlink Functions on the Avalanche Fuji testnet to fetch data from Space and Time (SXT) using DON-hosted secrets and deliver it to a smart contract.

The specific example fetches the average Bitcoin transaction fee from the `BITCOIN.STATS` table in SXT.

## Prerequisites

*   **Foundry:** Install Foundry for smart contract development and testing. Follow the instructions [here](https://book.getfoundry.sh/getting-started/installation).
*   **Node.js & npm/yarn:** Install Node.js (v18+ recommended) and npm or yarn for running JavaScript scripts (secrets upload).
*   **Avalanche Fuji Testnet RPC URL:** Get an RPC endpoint for Fuji (e.g., from Alchemy, Infura, QuickNode, or the public Avalanche RPC).
*   **Funded Wallet:** A private key for an account funded with Fuji AVAX testnet tokens. Get tokens from the [Fuji Faucet](https://faucet.avax.network/).
*   **SXT API Key:** Obtain an API key from [Space and Time](https://www.spaceandtime.io/). The free tier is sufficient for this demo.
*   **Chainlink Functions Subscription:** You will create this in the setup steps.

## Setup & Execution Steps

1.  **Install Dependencies:**
    *   Install Foundry libraries:
        ```bash
        forge install
        ```
    *   Install Node.js dependencies for the secrets script:
        ```bash
        npm install # or yarn install
        ```
        *Note: A `package.json` specifying `@chainlink/functions-toolkit` and `ethers` is required.*

2.  **Set Up Environment Variables:**
    *   Create a `.env` file in the project root:
        ```bash
        cp .env.example .env
        ```
    *   Replace the placeholders with your actual values.

3.  **Create Chainlink Functions Subscription:**
    *   Go to the [Chainlink Functions UI](https://functions.chain.link/).
    *   Connect your wallet (ensure it's set to Avalanche Fuji).
    *   Create a new subscription.
    *   Fund the subscription with testnet LINK (available from faucets linked in the Chainlink documentation).
    *   Copy the **Subscription ID** and add it to your `.env` file as `FUNCTIONS_SUBSCRIPTION_ID`.

4.  **Source Environment Variables:**
    *   Load the variables into your current shell session:
        ```bash
        source .env
        ```

5.  **Upload Secrets:**
    *   Run the script to upload your SXT API Key to the DON:
        ```bash
        node scripts/uploadSecrets.js
        ```
    *   The script will output a **version number**. Copy this number and add it to your `.env` file as `FUNCTIONS_SECRETS_VERSION`.
    *   Re-source the environment variables:
        ```bash
        source .env
        ```

6.  **Deploy the Contract:**
    *   Deploy the `SxtNumericQuery` contract using Forge:
        ```bash
        forge script script/DeploySxtNumericQuery.s.sol --rpc-url $RPC_URL --broadcast -vvvv
        ```
    *   Copy the deployed **Contract Address** from the output. Add it to your `.env` file as `CONTRACT_ADDRESS` (or export it).
    *   Re-source the environment variables if you added it to the file:
        ```bash
        source .env
        ```

7.  **Add Consumer to Subscription:**
    *   Go back to your Chainlink Functions subscription page in the UI.
    *   Add the deployed **Contract Address** (from Step 7) as an authorized consumer.

8.  **Request Data:**
    *   Run the request script:
        ```bash
        forge script script/RequestSxtData.s.sol --rpc-url $RPC_URL --broadcast -vvvv
        ```
    *   This sends a transaction to your contract, triggering the Chainlink Function request.

9. **Check the Result:**
    *   Wait ~1-2 minutes for the DON to process the request and fulfill it on-chain.
    *   Use `cast` to read the `latestNumericResult` from your contract:
        ```bash
        cast call $CONTRACT_ADDRESS "latestNumericResult()(uint256)" --rpc-url $RPC_URL
        ```
    *   You should see the latest average Bitcoin fee (as an integer, potentially scaled if the JS code were doing that) returned by SXT.
