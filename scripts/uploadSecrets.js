// scripts/uploadSecrets.js

import { SecretsManager } from "@chainlink/functions-toolkit";
import { Wallet, providers } from "ethers";

import dotenv from "dotenv";

dotenv.config();

// Load environment variables using standard process.env
// Ensure you have set PRIVATE_KEY, RPC_URL, and SXT_API_KEY in your environment
// (e.g., by exporting them or using a `.env` file and `source .env`)

// Ensure required environment variables are set
if (!process.env.PRIVATE_KEY) {
  throw new Error("PRIVATE_KEY environment variable is not set.");
}
if (!process.env.RPC_URL) {
  throw new Error("RPC_URL environment variable (for Avalanche Fuji) is not set.");
}
if (!process.env.SXT_API_KEY) {
  throw new Error("SXT_API_KEY environment variable is not set.");
}

// Configuration for Avalanche Fuji - Get From https://docs.chain.link/chainlink-functions/supported-networks#avalanche-fuji-testnet
const routerAddress = "0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0";
const donId = "fun-avalanche-fuji-1"; // Fuji DON ID
// Multiple gateways can be used for redundancy
const gatewayUrls = [
  "https://01.functions-gateway.testnet.chain.link/",
  "https://02.functions-gateway.testnet.chain.link/",
];
const slotId = 0; // Slot 0 for general user secrets
const minutesUntilExpiration = 1440; // Reduced to 1 day (was 43800)

const uploadSecrets = async () => {
  // Initialize ethers provider and signer
  const provider = new providers.JsonRpcProvider(process.env.RPC_URL);
  const wallet = new Wallet(process.env.PRIVATE_KEY);
  const signer = wallet.connect(provider);

  // Initialize SecretsManager
  const secretsManager = new SecretsManager({
    signer: signer,
    functionsRouterAddress: routerAddress,
    donId: donId,
  });
  await secretsManager.initialize();

  // Define the secrets object
  const secrets = { sxtApiKey: process.env.SXT_API_KEY };
  console.log("Encrypting secrets:", JSON.stringify(secrets, null, 2).slice(0, 30) + "...\n}\n"); // Be careful logging secrets, even keys, in production

  // Encrypt secrets
  const encryptedSecretsObj = await secretsManager.encryptSecrets(secrets);
  console.log("Secrets encrypted.");

  // Upload secrets to the DON
  console.log(`Uploading secrets to DON... using slotId ${slotId} and expiration ${minutesUntilExpiration} minutes`);

  const uploadResult = await secretsManager.uploadEncryptedSecretsToDON({
    encryptedSecretsHexstring: encryptedSecretsObj.encryptedSecrets,
    gatewayUrls: gatewayUrls,
    slotId: slotId,
    minutesUntilExpiration: minutesUntilExpiration,
  });

  console.log("\nUpload Result:", uploadResult);

  if (!uploadResult.success) {
    console.error("\nSecrets upload failed!", uploadResult);
    if (uploadResult.errorMessage) {
      console.error("Error Message:", uploadResult.errorMessage);
    }
    throw new Error("Secrets upload failed.");
  }

  console.log(`\nSecrets uploaded successfully! slotId ${slotId} | version ${uploadResult.version}`);
  console.log(
    `\nPlease store the version number securely (e.g., in .env as FUNCTIONS_SECRETS_VERSION=${uploadResult.version}) for the next steps.`
  );

  return uploadResult.version;
};

uploadSecrets().catch(e => {
  console.error("Error uploading secrets:", e);
  process.exit(1);
});
