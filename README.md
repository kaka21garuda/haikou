# Haikou: Stablecoin-Based Decentralized Voting System

## Overview
Haikou is a revolutionary decentralized voting system that leverages stablecoins (USDC and USDT) to create a more stable and equitable governance mechanism. By using stablecoins instead of volatile governance tokens, Haikou provides a more predictable and fair voting power distribution while encouraging long-term participation through time-weighted voting mechanisms.

## Architecture
```mermaid
flowchart TD
    User[User] --> |Interacts with| FE[Frontend dApp]
    FE --> |Calls| WC[Web3 Connection]
    
    subgraph SmartContracts[Smart Contracts Layer]
        SV[StablecoinVault]
        VS[VotingSystem]
        PE[ProposalExecutor]
        DR[DelegateRegistry]
        TA[Timelock Admin]
    end
    
    WC --> |Deposit/Withdraw| SV
    WC --> |Create Proposal/Vote| VS
    VS --> |Execute Passed Proposal| PE
    VS --> |Check Voting Power| SV
    DR --> |Manage Delegations| VS
    
    SV --> |Lock/Unlock Funds| VS
    PE --> |Queue Actions| TA
    TA --> |Execute Actions| ExtC[External Contracts]
    
    subgraph OffChain[Off-chain Services]
        SG[Subgraph Indexer]
        AS[Analytics Service]
        NS[Notification Service]
    end
    
    SV --> |Index Events| SG
    VS --> |Index Events| SG
    PE --> |Index Events| SG
    
    SG --> |Query Data| FE
    SG --> |Provide Data| AS
    
    NS --> |Push Updates| FE
    AS --> |Display Analytics| FE
    
    style SmartContracts fill:#f9f,stroke:#333,stroke-width:4px
    style OffChain fill:#bbf,stroke:#333,stroke-width:4px
    style SV fill:#d742f5,stroke:#333,stroke-width:2px,color:#fff
    style VS fill:#d742f5,stroke:#333,stroke-width:2px,color:#fff
    style PE fill:#d742f5,stroke:#333,stroke-width:2px,color:#fff
    style DR fill:#d742f5,stroke:#333,stroke-width:2px,color:#fff
    style TA fill:#d742f5,stroke:#333,stroke-width:2px,color:#fff
    style ExtC fill:#5c7aff,stroke:#333,stroke-width:2px,color:#fff
    style SG fill:#2a9d8f,stroke:#333,stroke-width:2px,color:#fff
    style AS fill:#2a9d8f,stroke:#333,stroke-width:2px,color:#fff
    style NS fill:#2a9d8f,stroke:#333,stroke-width:2px,color:#fff
```

## Project Structure
```
haikou/
├── contracts/           # Smart contract source files
├── frontend/           # React-based web application
├── subgraph/           # TheGraph indexing services
├── scripts/            # Deployment and maintenance scripts
├── test/              # Test suites
├── ignition/          # Deployment configurations
├── hardhat.config.ts  # Hardhat configuration
└── package.json       # Project dependencies
```

## Key Features
- **Stablecoin-Based Voting**: Uses USDC and USDT for stable voting power
- **Time-Weighted Voting**: Encourages long-term participation
- **Multiple Voting Mechanisms**: Supports various voting strategies
- **Delegation System**: Allows vote delegation to active participants
- **On-Chain Execution**: Automatic execution of passed proposals
- **Real-Time Analytics**: Comprehensive voting and participation metrics
- **Gas-Optimized**: Efficient implementation for cost-effective participation

## Getting Started

### Prerequisites
- Node.js v16+
- Yarn or npm
- MetaMask or similar Web3 wallet

### Installation
```bash
# Clone the repository
git clone https://github.com/yourusername/haikou.git

# Install dependencies
cd haikou
yarn install

# Install frontend dependencies
cd frontend
yarn install

# Start local development environment
yarn dev
```

### Smart Contract Deployment
```bash
# Deploy to local network
yarn hardhat deploy --network localhost

# Deploy to testnet
yarn hardhat deploy --network goerli
```

### Running Tests
```bash
# Run all tests
yarn test

# Run specific test file
yarn test test/StablecoinVault.test.ts
```

## Documentation

- [Smart Contracts Documentation](./contracts/README.md)
- [Frontend Documentation](./frontend/README.md)
- [Subgraph Documentation](./subgraph/README.md)
- [API Documentation](./docs/API.md)

## Security

### Audits
- Audit reports will be published in the `/audits` directory soon
- Security review scheduled soon

### Bug Bounty
Our bug bounty program details will be available at [bug-bounty-platform]

## Contributing
We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.