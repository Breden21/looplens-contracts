const hre = require("hardhat");

async function main() {
  console.log("🚀 Deploying to Base Sepolia...\n");

  // Use official Base Sepolia USDC
  const usdcAddress = "0x036CbD53842c5426634e7929541eC2318f3dCF7e";
  console.log("✅ Using official USDC on Base Sepolia:", usdcAddress);

  // Deploy PredictionMarket
  console.log("\n📝 Deploying PredictionMarket...");
  const PredictionMarket = await hre.ethers.getContractFactory("PredictionMarket");
  const market = await PredictionMarket.deploy(usdcAddress);
  await market.waitForDeployment();
  const marketAddress = await market.getAddress();
  console.log("✅ PredictionMarket deployed to:", marketAddress);

  // Display results
  console.log("\n" + "=".repeat(60));
  console.log("🎉 DEPLOYMENT COMPLETE!");
  console.log("=".repeat(60));
  console.log("\n📋 SAVE THESE ADDRESSES:\n");
  console.log("USDC (Base Sepolia):", usdcAddress);
  console.log("PredictionMarket:", marketAddress);
  console.log("\n🔗 View on Basescan:");
  console.log("USDC:", `https://sepolia.basescan.org/address/${usdcAddress}`);
  console.log("PredictionMarket:", `https://sepolia.basescan.org/address/${marketAddress}`);
  console.log("\n" + "=".repeat(60));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });