# Tokenized Decentralized Garden Hose Nozzle Networks

A blockchain-based system for managing community garden hose nozzles with tokenized ownership, sharing coordination, and automated maintenance tracking.

## Overview

This project implements a decentralized network for managing garden hose nozzles through smart contracts on the Stacks blockchain. The system enables community members to share, maintain, and upgrade nozzles while tracking usage, performance, and maintenance needs.

## Smart Contracts

### 1. Pressure Regulation Contract (`pressure-regulation.clar`)
- Manages water flow control settings
- Handles spray pattern configurations
- Tracks pressure levels and adjustments
- Maintains nozzle performance metrics

### 2. Leak Detection Contract (`leak-detection.clar`)
- Monitors connection integrity
- Detects seal deterioration
- Tracks leak incidents and repairs
- Maintains connection health scores

### 3. Sharing Coordination Contract (`sharing-coordination.clar`)
- Organizes nozzle lending between community members
- Manages reservation systems
- Tracks usage history and availability
- Handles sharing rewards and penalties

### 4. Maintenance Tracking Contract (`maintenance-tracking.clar`)
- Schedules cleaning and repair activities
- Tracks maintenance history
- Manages maintenance worker assignments
- Monitors nozzle condition over time

### 5. Upgrade Management Contract (`upgrade-management.clar`)
- Coordinates nozzle replacements
- Manages technology upgrades
- Tracks upgrade costs and benefits
- Handles upgrade voting and consensus

## Features

- **Tokenized Ownership**: Each nozzle is represented as a unique token
- **Community Sharing**: Decentralized lending and borrowing system
- **Automated Maintenance**: Smart contract-driven maintenance scheduling
- **Performance Tracking**: Real-time monitoring of nozzle performance
- **Upgrade Coordination**: Community-driven upgrade decisions

## Getting Started

### Prerequisites
- Stacks blockchain node
- Clarity development environment
- Node.js for testing

### Installation
1. Clone the repository
2. Install dependencies: `npm install`
3. Run tests: `npm test`
4. Deploy contracts to Stacks testnet

### Usage
1. Deploy all five smart contracts
2. Initialize nozzle tokens
3. Set up community sharing parameters
4. Begin tracking maintenance and performance

## Contract Interactions

Each contract operates independently while maintaining data consistency through standardized data structures and event emissions.

### Key Data Structures
- **Nozzle**: Unique identifier, owner, specifications, condition
- **User**: Principal address, reputation score, activity history
- **Maintenance Record**: Timestamp, type, performer, results
- **Sharing Agreement**: Borrower, lender, duration, terms

## Testing

The project includes comprehensive Vitest tests for all contract functions:
- Unit tests for individual contract methods
- Integration tests for cross-contract workflows
- Performance tests for high-load scenarios

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement changes with tests
4. Submit a pull request

## License

MIT License - see LICENSE file for details
