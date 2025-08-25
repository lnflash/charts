#!/usr/bin/env node

const axios = require("axios");
const nostrTools = require("nostr-tools");

const GRAPHQL_URL = "https://api.flashapp.me/graphql"; // Replace with your actual GraphQL endpoint

const rl = require("readline").createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false,
});

const checkWhitelist = async (hexPubkey) => {
  try {
    let npub = nostrTools.nip19.npubEncode(hexPubkey);
    const query = `
      query Query($input: IsFlashNpubInput!) {
        isFlashNpub(input: $input) {
          isFlashNpub
        }
      }
    `;

    const variables = {
      input: { npub: npub },
    };

    console.error(
      "Making API request with variables:",
      JSON.stringify(variables)
    ); // Log request to stderr

    try {
      const response = await axios.post(
        GRAPHQL_URL,
        {
          query,
          variables,
        },
        {
          headers: { "Content-Type": "application/json" },
        }
      );
      console.error("API response:", response.data); // Log response to stderr
      return response.data.data.isFlashNpub.isFlashNpub;
    } catch (error) {
      console.error("Error fetching whitelist status:", error.message);
      console.error("Request variables were:", JSON.stringify(variables));
      return false;
    }
  } catch (error) {
    console.error("Error encoding pubkey:", error.message);
    return false;
  }
};

rl.on("line", async (line) => {
  let req;
  let res = {};

  // Parse the input line
  try {
    req = JSON.parse(line);
  } catch (error) {
    console.error("Invalid JSON format:", error.message);
    console.log(
      JSON.stringify({
        action: "reject",
        msg: "invalid JSON format",
      })
    );
    return;
  }

  // Check if the request has an event ID
  if (!req.event || !req.event.id) {
    console.error("Missing event ID");
    console.log(
      JSON.stringify({
        action: "reject",
        msg: "missing event ID",
      })
    );
    return;
  }

  // Set the event ID for the response
  res.id = req.event.id;

  // Check request type
  if (req.type !== "new") {
    console.error("Unexpected request type:", req.type);
    res.action = "reject";
    res.msg = "unexpected request type";
    console.log(JSON.stringify(res));
    return;
  }

  // Check for p tag
  const hexPubkey = req.event.tags.filter((t) => t[0] === "p")[0]?.[1];
  console.error("Hex pubkey is", hexPubkey, "Request event is", req.event);

  if (!hexPubkey) {
    console.error("No referenced pubkey");
    res.action = "reject";
    res.msg = "no referenced pubkey (p tag)";
    console.log(JSON.stringify(res));
    return;
  }

  // Check if the pubkey is on the whitelist via GraphQL query
  const isWhitelisted = await checkWhitelist(hexPubkey);

  if (isWhitelisted) {
    res.action = "accept";
  } else {
    res.action = "reject";
    res.msg = "blocked: not on white-list";
  }

  console.log(JSON.stringify(res));
});
