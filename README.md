# LoopLens - Smart Contracts

Solidity smart contracts for AI vs Human prediction markets on Base.

## 📝 Deployed Contracts (Base Sepolia)

- **PredictionMarket:** `0xb69477DBeB7C0CD962D88D25024F1e4f6FCD3a99`
- **USDC:** `0x036CbD53842c5426634e7929541eC2318f3dCF7e` (Circle official)

View on Basescan: [PredictionMarket](https://sepolia.basescan.org/address/0xb69477DBeB7C0CD962D88D25024F1e4f6FCD3a99)

## 🎯 Contract Features

- ✅ Create prediction markets with AI confidence levels
- ✅ Users bet with USDC (with or against AI)
- ✅ Secure betting with ReentrancyGuard
- ✅ Owner-controlled market resolution
- ✅ Proportional winnings distribution
- ✅ 2% platform fee

## 🛠 Tech Stack

- Solidity 0.8.20
- Hardhat
- OpenZeppelin Contracts
- Ethers.js v6

## 🏗 Architecture
```solidity
PredictionMarket {
  - createMarket(title, duration, aiConfidence)
  - placeBet(marketId, withAI, amount)
  - resolveMarket(marketId, aiWon)
  - claim(marketId)
}
```

## 🚀 Local Development
```bash
npm install
npx hardhat compile
```

## 📦 Deploy
```bash
npx hardhat run scripts/deploy.js --network baseSepolia
```

## 🧪 Test
```bash
npx hardhat test
```

## 🔗 Related Repos

- Frontend: [looplens-market-deck](https://github.com/Breden21/looplens-market-deck)
- AI Agent: [looplens-ai-agent](https://github.com/Breden21/looplens-ai-agent)

## 🔐 Security

- OpenZeppelin ReentrancyGuard
- Ownable access control
- Tested on Base Sepolia testnet

## 📄 License

MIT
