# Chainlink Functions SXT Demo (Avalanche Fuji)

This project demonstrates how to use Chainlink Functions on the Avalanche Fuji testnet to fetch data from Space and Time (SXT) using DON-hosted secrets and deliver it to a smart contract.

The specific example fetches the average Bitcoin transaction fee from the `BITCOIN.STATS` table in SXT.

## Prerequisites

- **Foundry:** Install Foundry for smart contract development and testing. Follow the instructions [here](https://book.getfoundry.sh/getting-started/installation). If you've already installed it then run `foundryup` to get the latest updates.fo
- **Node.js & npm/yarn:** Install Node.js (v18+ recommended) and npm or yarn for running JavaScript scripts (secrets upload).
- **Avalanche Fuji Testnet RPC URL:** Get an RPC endpoint for Avalanche Fuji Testnet (try [public Avalanche RPC](https://build.avax.network/docs/tooling/rpc-providers#http) ). The `.env.example` file currently has the public RPC URL provided for you.
- **Funded Wallet:** A private key for an account funded with Fuji AVAX testnet tokens. Get tokens from the [Fuji Faucet](https://faucet.avax.network/). Also fund the same wallet with LINK tokens on Avalanche Fuji by going [here](https://faucets.chain.link/fuji) and clicking on LINK on the upper right.
- **SXT API Key:** Obtain an API key from [Space and Time](https://www.spaceandtime.io/). Create an account by launching the SXT Studio. The free tier is sufficient for this demo. Once you've created your account and logged into Studio, go to `My Account` >> `Developers & APIs` >> `API Authentication` and `Create API key`.
- **Chainlink Functions Subscription:** You will create this in the setup steps.

## Gitbook Walk Through

The entire code walkthrough, with screenshots and explanations are available in our [Gitbook for this LinkLab](https://cll-devrel.gitbook.io/sxt-and-cl-functions).

## Setup

For the canonical list, go to the Gitbook here: https://cll-devrel.gitbook.io/sxt-and-cl-functions

1.  **Install Dependencies:**

    - Install Foundry libraries:

      ```bash
      forge install
      ```

      If successful you should notice a gitignored `./lib` folder in project root.

    - Install Node.js dependencies for the secrets script:

      ```bash
      npm install # or yarn install or pnpm install
      ```

      _Note: Ensure that the `ethers` package is pinned to v5.7 as thats the version that Chainlink Functions Toolkit depends on_

      If successful you should see a gitignored `./node_modules` folder in project root.

2.  **Set Up Environment Variables:**

    - Create a `.env` file in the project root by copying the example env file provided:
      ```bash
      cp .env.example .env
      ```
    - Replace the placeholders with your actual values.

3.  **Create Chainlink Functions Subscription:**

    - Go to the [Chainlink Functions UI](https://functions.chain.link/).
    - Connect your wallet (ensure it's set to Avalanche Fuji).
    - Create a new subscription.
    - Fund the subscription with testnet LINK (available from faucets linked in the Chainlink documentation).
    - Copy the **Subscription ID** and add it to your `.env` file as `FUNCTIONS_SUBSCRIPTION_ID`.

## Execution Steps

4.  **Source Environment Variables:**

    - Load the variables into your current shell session:
      ```bash
      source .env
      ```

    You can confirm that your .env file is loaded in your current terminal session by running `echo $SXT_API_KEY` in your terminal.

5.  **Upload Secrets:**

    - Run the script to upload your SXT API Key to the DON:
      ```bash
      node script/uploadSecrets.js
      ```
    - The script will output a **version number**. Copy this number and add it to your `.env` file as `FUNCTIONS_SECRETS_VERSION`.
    - Re-load the environment variables into your terminal session:
      ```bash
      source .env
      ```

6.  **Deploy the Contract:**

    - Deploy the `SxtNumericQuery` contract using Forge:

      ```bash
      forge script script/DeploySxtNumericQuery.s.sol --rpc-url $RPC_URL --broadcast -vvvv
      ```

      If successful you should see output like:

      ```
      ==========================
      ✅  [Success] Hash: 0x60280f10aff3d71a2ec99b0bd77ac45b7098f5f88002b78b3fa179ac099f1103
        Contract Address: 0x3974ddCFc2108DC5491fC26bc10AEaa3e07cD3C1
        Block: 40310993
        Paid: 0.000000000008217714 ETH (4108857 gas * 0.000000002 gwei)

        ✅ Sequence #1 on fuji | Total Paid: 0.000000000008217714 ETH (4108857 gas * avg 0.000000002 gwei)
      ==========================
      ```

    - Copy the deployed **Contract Address** from the output. Add it to your `.env` file as `CONTRACT_ADDRESS` (or export it).
    - Re-source the environment variables if you added it to the file:
      ```bash
      source .env
      ```

7.  **Set the SQL Query on the Contract:**

    - After deploying the contract and setting its address in your environment, set the SQL query that the contract will use.
    - Run the `SetSxtSqlQuery` script:
      ```bash
      forge script script/SetSxtSqlQuery.s.sol --rpc-url $RPC_URL --broadcast -vvvv
      ```
    - This script uses the `CONTRACT_ADDRESS` (which you should have set in your `.env` file from the previous step) and `PRIVATE_KEY` from your `.env` file to call the `setSqlQuery` function on your deployed contract.

8.  **Add Consumer to Subscription:**

    - Go back to your [Chainlink Functions subscription page](functions.chain.link) in the UI.
    - Add the deployed **Contract Address** (from Step 6) as an authorized consumer.

9.  **Request Data:**

    - Run the request script:
      ```bash
      forge script script/RequestSxtData.s.sol --rpc-url $RPC_URL --broadcast -vvvv
      ```
    - This sends a transaction to your contract, triggering the Chainlink Function request. If successful you should see something like:

    ```
    ==========================
      ✅  [Success] Hash: 0xc28a13e56691f672d654ff23208f829ccd0ccbb504bfa0ea1b9467ec49de1191
      Block: 40311120
      Paid: 0.00026475500052951 ETH (529510 gas * 0.500000001 gwei)

      ✅ Sequence #1 on fuji | Total Paid: 0.00026475500052951 ETH (529510 gas * avg 0.500000001 gwei)
    ==========================
    ```

10. **Check the Result:**

    - Wait ~1-2 minutes for the DON to process the request and fulfill it on-chain.
    - Use `cast` to read the `latestNumericResult` from your contract:
      ```bash
      cast call $CONTRACT_ADDRESS "latestNumericResult()(uint256)" --rpc-url $RPC_URL
      ```
    - You should see the latest average Bitcoin fee (as an integer, potentially scaled if the JS code were doing that) returned by SXT.

    If you need to check the actual response that was returned by your Functions source run `cast call $CONTRACT_ADDRESS "latestNumericResult()(uint256)" --rpc-url $RPC_URL`. This gives you the results in `bytes`, which needs to be converted into `string`.

    You can convert in your terminal with `cast --to-ascii <<0x_hex_string>>`

## Trouble shooting

1. If you run a script like `.uploadSecrets.js` and get an error like `Error: Cannot find module \'bcrypto.node\'` then you may need to delete `node_modules` and run `pnpm install` then run `pnpm approve-builds` and use the spacebar to select the `bcrypto` package and build its source. This should get rid of the error.

2. If your call to `latestNumericResult` returns `0` there is a chance that there was an error. You can check the error by calling `cast call $CONTRACT_ADDRESS "latestError()(bytes)" --rpc-url $RPC_URL`. Once again, you'd need to convert `bytes` to `string` as shown above in the **Check the Result** section.
