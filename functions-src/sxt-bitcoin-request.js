const sqlQuery = args[0];
const sxtApiKey = secrets.sxtApiKey;

if (!sxtApiKey) {
  throw Error("SXT API Key is not set in secrets.");
}
if (!sqlQuery) {
  throw Error("SQL Query not provided in args[0]");
}

const sxtApiUrl = "https://proxy.api.spaceandtime.dev/v1/sql"; // SXT Gateway Proxy SQL Endpoint

console.log(`Executing SXT SQL Query: ${sqlQuery}`);

const sxtRequest = Functions.makeHttpRequest({
  url: sxtApiUrl,
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    apikey: sxtApiKey, // Use the SXT API Key from secrets
    accept: "application/json",
  },
  data: {
    sqlText: sqlQuery,
    // resourceId: "" // Optional: Specify if targeting a private resource
  },
  // Adjust timeout if needed, SXT queries can sometimes take a few seconds
  timeout: 25000, // Increased to 25 seconds (was 10000)
});

// Execute the request
const sxtResponse = await sxtRequest;
const responseJsonString = JSON.stringify(sxtResponse, null, 2);

if (sxtResponse.error) {
  console.error("SXT API Request Error:", responseJsonString);
  throw Error(`SXT API request failed: ${sxtResponse.response ? responseJsonString : "Network Error or Timeout"}`);
}

console.log("SXT API Response Data:", sxtResponse.data);

// Assuming the response data is an array of objects, e.g., [{"AVG_FEE": 123.456}]
// Adjust parsing based on the actual SXT response structure if necessary
if (!sxtResponse.data || !Array.isArray(sxtResponse.data) || sxtResponse.data.length === 0) {
  throw Error("Unexpected response structure from SXT API");
}

// SXT returns column names in uppercase by default
const avgFee = sxtResponse.data[0].AVG_FEE;

if (avgFee === undefined || avgFee === null) {
  throw Error("Could not find AVG_FEE in SXT response");
}

// Directly parse the value as an integer (assuming it's returned as a string or number)
const integerAvgFee = parseInt(avgFee, 10); // Use parseInt with radix 10
if (isNaN(integerAvgFee)) {
  throw Error(`AVG_FEE value is not an integer: ${avgFee}`);
}

console.log(`Integer AVG_FEE from SXT: ${integerAvgFee}`);

// No scaling needed if it's already an integer

console.log(`Returning AVG_FEE (uint256): ${integerAvgFee}`);

// Return the result as uint256
// Use BigInt() to handle potentially large integers correctly for encoding
return Functions.encodeUint256(BigInt(integerAvgFee));
