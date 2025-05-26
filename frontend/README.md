# 🔷 Bonded Finance

![Bonded Finance Banner](public/banner.png)

## 🏆 Re{ignite} Starknet Hackathon Project

Bonded Finance is a fixed-yield protocol built on Starknet that enables users to create and trade yield tokens. Our platform introduces innovative financial instruments to the Starknet ecosystem, allowing users to lock in future yields and trade them in a decentralized manner.

### 🎯 Problem Statement

In the current DeFi landscape, yield rates are highly volatile and unpredictable. Users seeking stable returns often struggle to find reliable solutions that guarantee fixed yields without sacrificing capital efficiency.

### 💡 Solution

Bonded Finance introduces Principal Tokens (PT) and Yield Tokens (YT), allowing users to:
- Lock in future yields today
- Trade yield expectations
- Create efficient fixed-rate lending and borrowing markets
- Access immediate liquidity for future yield

## 🛠 Technical Stack

- **Frontend**: React, TypeScript, TailwindCSS
- **Smart Contracts**: Cairo 1.0
- **Network**: Starknet
- **Testing**: Scarb, Starknet-devnet
- **Deployment**: Starknet Testnet (Sepolia)

## 🚀 Features

- 📊 Real-time price charts and order books
- 💱 Seamless swapping between underlying assets and PTs/YTs
- 🔒 Secure wallet integration with Argent X and Braavos
- 📈 Advanced yield trading mechanisms
- 🎯 Intuitive user interface for both beginners and advanced traders

## 🏃‍♂️ Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/bonded-finance.git

# Install dependencies
cd bonded-finance
yarn install

# Start the development server
yarn start
```

## 🔧 Smart Contract Deployment

Our contracts are deployed on Starknet Sepolia Testnet:
- Market Contract: `0x...`
- Router Contract: `0x...`
- Factory Contract: `0x...`

## 🎮 Usage

1. **Connect Wallet**: Use Argent X or Braavos wallet
2. **Create Order**: Lock in future yield by creating PT/YT pairs
3. **Trade**: Swap between underlying assets and PTs/YTs
4. **Monitor**: Track your positions and yields in real-time

## 🏗 Architecture

```
bonded-finance/
├── src/
│   ├── components/     # React components
│   ├── hooks/         # Custom hooks for contract interactions
│   ├── context/       # React context providers
│   └── abi/          # Contract ABIs
├── contracts/        # Cairo smart contracts
└── public/          # Static assets
```

## 🔬 Testing

```bash
# Run frontend tests
yarn test

# Run contract tests
scarb test
```

## 🤝 Contributing

We welcome contributions! Please check our [Contributing Guidelines](CONTRIBUTING.md) for details.

## 👥 Team

- **Hugo** - Full Stack Developer & Smart Contract Engineer
- [Add other team members]

## 🏆 Hackathon Achievements

- 🥇 Participated in Re{ignite} by Starknet
- [Add specific achievements/features completed during hackathon]

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Starknet Foundation for organizing Re{ignite}
- [Other acknowledgments]

---

<p align="center">Built with ❤️ for the Starknet ecosystem</p>
