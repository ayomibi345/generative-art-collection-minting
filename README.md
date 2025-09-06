# Generative Art Collection Minting

A decentralized generative art NFT collection minting system built on the Stacks blockchain using Clarity smart contracts. This project enables the creation, minting, and management of generative art collections with on-chain metadata generation and rarity calculation.

## 🎨 Overview

This project consists of two main smart contracts that work together to provide a complete generative art NFT minting solution:

1. **Collection Factory** - Handles NFT minting, ownership tracking, and collection management
2. **Metadata Generator** - Manages trait generation, rarity calculations, and metadata assembly

## 🏗️ Architecture

### Collection Factory Contract
- **NFT Minting**: Create unique tokens with sequential IDs
- **Ownership Management**: Track token ownership and transfers
- **Collection Controls**: Set max supply, pricing, and admin privileges
- **Payment Processing**: Handle STX payments for minting
- **Event Logging**: Emit events for all major operations

### Metadata Generator Contract
- **Trait Libraries**: On-chain storage of trait categories and options
- **Pseudo-Random Generation**: Deterministic trait selection using block hashes
- **Rarity Calculation**: Dynamic rarity scoring based on trait frequency
- **Metadata Assembly**: Generate complete JSON metadata for each token

## 🚀 Features

### Core Functionality
- ✅ Generative art NFT minting
- ✅ On-chain metadata generation
- ✅ Rarity-based trait distribution
- ✅ Collection management (max supply, pricing)
- ✅ Ownership tracking and transfers
- ✅ Admin controls for collection management
- ✅ Event emission for transparency

### Generative Art System
- **Dynamic Traits**: Background, colors, shapes, patterns, effects
- **Rarity Tiers**: Common, uncommon, rare, epic, legendary
- **Pseudo-Random Selection**: Uses block hash for deterministic randomness
- **Metadata Standards**: Compatible with standard NFT metadata format

## 📋 Smart Contract Details

### Collection Factory
```clarity
;; Main functions:
- mint-nft: Mint new NFT tokens
- transfer: Transfer tokens between users
- get-owner: Retrieve token owner
- set-mint-price: Update minting cost
- set-max-supply: Set collection size limit
```

### Metadata Generator
```clarity
;; Main functions:
- generate-metadata: Create complete metadata for token
- get-trait-rarity: Calculate trait rarity scores
- add-trait-category: Admin function to add new traits
- get-random-trait: Pseudo-random trait selection
```

## 🛠️ Development Setup

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) - Clarity development environment
- [Node.js](https://nodejs.org/) - For testing and development tools
- [Git](https://git-scm.com/) - Version control

### Installation
```bash
# Clone the repository
git clone https://github.com/ayomibi345/generative-art-collection-minting.git
cd generative-art-collection-minting

# Install dependencies
npm install

# Check contract syntax
clarinet check
```

## 🧪 Testing

Run the test suite to verify contract functionality:

```bash
# Run all tests
npm test

# Run specific contract tests
clarinet test tests/collection-factory_test.ts
clarinet test tests/metadata-generator_test.ts

# Check contract syntax
clarinet check
```

## 📊 Usage Examples

### Minting NFTs
```clarity
;; Mint a new NFT (requires STX payment)
(contract-call? .collection-factory mint-nft)
```

### Generating Metadata
```clarity
;; Generate metadata for token ID 1
(contract-call? .metadata-generator generate-metadata u1)
```

### Admin Operations
```clarity
;; Set mint price (admin only)
(contract-call? .collection-factory set-mint-price u5000000) ;; 5 STX

;; Add new trait category (admin only)
(contract-call? .metadata-generator add-trait-category "Eyes" (list "Blue" "Green" "Brown"))
```

## 💡 Rarity System

The metadata generator implements a sophisticated rarity system:

- **Common** (60%): Basic traits with high occurrence
- **Uncommon** (25%): Slightly rare traits
- **Rare** (10%): Limited availability traits
- **Epic** (4%): Very rare combinations
- **Legendary** (1%): Extremely rare, unique traits

Rarity is calculated based on:
1. Individual trait frequency
2. Trait combination rarity
3. Overall collection distribution

## 🔐 Security Features

- **Admin Controls**: Restricted administrative functions
- **Input Validation**: Comprehensive parameter checking
- **Overflow Protection**: Safe arithmetic operations
- **Access Control**: Owner-only operations for transfers
- **Event Logging**: Complete audit trail

## 📁 Project Structure

```
generative-art-collection-minting/
├── contracts/
│   ├── collection-factory.clar     # Main NFT contract
│   └── metadata-generator.clar     # Metadata generation
├── tests/
│   ├── collection-factory_test.ts
│   └── metadata-generator_test.ts
├── settings/
│   ├── Devnet.toml
│   ├── Testnet.toml
│   └── Mainnet.toml
├── Clarinet.toml
├── package.json
└── README.md
```

## 🌐 Deployment

### Devnet Deployment
```bash
# Deploy to local devnet
clarinet integrate

# Deploy specific contracts
clarinet deployments generate --devnet
clarinet deployments apply --devnet
```

### Testnet/Mainnet Deployment
Update the respective configuration files in `settings/` directory and deploy:

```bash
# Generate deployment plan
clarinet deployments generate --testnet

# Apply deployment
clarinet deployments apply --testnet
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Repository**: [GitHub](https://github.com/ayomibi345/generative-art-collection-minting)
- **Stacks Blockchain**: [Stacks.co](https://www.stacks.co/)
- **Clarity Documentation**: [Clarity Book](https://book.clarity-lang.org/)
- **Clarinet Documentation**: [Hiro Docs](https://docs.hiro.so/clarinet)

## ⚡ Quick Start

Get up and running in 3 steps:

1. **Clone & Install**
   ```bash
   git clone https://github.com/ayomibi345/generative-art-collection-minting.git
   cd generative-art-collection-minting
   npm install
   ```

2. **Check Contracts**
   ```bash
   clarinet check
   ```

3. **Run Tests**
   ```bash
   npm test
   ```

Start building your generative art collection minting system today! 🎨✨
