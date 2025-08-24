# StudentGov

A decentralized voting system smart contract for student government and university elections on the Stacks blockchain.

## Overview

StudentGov is a transparent, secure voting platform built using Clarity smart contracts. It enables universities and educational institutions to conduct fair student government elections with built-in safeguards against double voting, unauthorized access, and election manipulation.

## Features

- **Secure Election Management**: Create and manage multiple concurrent elections
- **Candidate Registration**: Add candidates with detailed profiles and descriptions  
- **Voter Eligibility Control**: Restrict voting to pre-approved eligible participants
- **Double-Vote Prevention**: Built-in mechanisms to prevent duplicate voting
- **Transparent Vote Counting**: Real-time vote tallying with immutable records
- **Block-Based Timing**: Elections run on blockchain block heights for precise timing
- **Administrative Controls**: Owner-only functions for election administration
- **Election Status Tracking**: Monitor election phases (upcoming, active, ended)

## Technical Specifications

- **Blockchain**: Stacks
- **Smart Contract Language**: Clarity v2
- **Epoch**: 2.5
- **Testing Framework**: Vitest with Clarinet SDK
- **Development Tools**: Clarinet, TypeScript

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks smart contract development toolkit
- [Node.js](https://nodejs.org/) v16+ and npm
- [Stacks Wallet](https://wallet.hiro.so/) for mainnet interactions

### Setup

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd StudentGov
   ```

2. Navigate to the contract directory:
   ```bash
   cd StudentGov_contract
   ```

3. Install dependencies:
   ```bash
   npm install
   ```

4. Verify installation:
   ```bash
   clarinet check
   ```

## Usage

### Running Tests

```bash
# Run all tests
npm run test

# Run tests with coverage and cost analysis
npm run test:report

# Watch mode (auto-run tests on file changes)
npm run test:watch
```

### Deployment

#### Local Development (Devnet)
```bash
clarinet integrate
```

#### Testnet Deployment
```bash
clarinet deploy --testnet
```

#### Mainnet Deployment
```bash
clarinet deploy --mainnet
```

## Contract Functions

### Administrative Functions (Owner Only)

#### `create-election`
Creates a new election with specified parameters.

**Parameters:**
- `title` (string-ascii 100): Election title
- `description` (string-ascii 500): Election description
- `duration-blocks` (uint): Election duration in blocks

**Returns:** Election ID

**Example:**
```clarity
(contract-call? .StudentGov create-election 
  "Student Council President 2024" 
  "Annual election for student council president position"
  u1440) ;; ~10 days assuming 10-minute blocks
```

#### `add-candidate`
Registers a candidate for a specific election.

**Parameters:**
- `election-id` (uint): Target election ID
- `name` (string-ascii 50): Candidate name
- `description` (string-ascii 200): Candidate platform/bio
- `candidate-address` (principal): Candidate's Stacks address

**Returns:** Candidate ID

#### `add-eligible-voter`
Authorizes a user to vote in a specific election.

**Parameters:**
- `election-id` (uint): Target election ID
- `voter` (principal): Voter's Stacks address

**Returns:** Success confirmation

#### `end-election`
Manually ends an election before its scheduled end block.

**Parameters:**
- `election-id` (uint): Election to end

**Returns:** Success confirmation

### Voting Functions

#### `cast-vote`
Allows eligible voters to cast their vote in an active election.

**Parameters:**
- `election-id` (uint): Election ID
- `candidate-id` (uint): Chosen candidate ID

**Returns:** Success confirmation

**Validation:**
- Voter must be eligible
- Election must be active and within voting period
- Voter cannot have already voted
- Candidate must exist

### Read-Only Functions

#### `get-election`
Retrieves election details by ID.

#### `get-candidate`
Gets candidate information for a specific election.

#### `get-candidate-count`
Returns the number of candidates in an election.

#### `has-voted`
Checks if a specific voter has already voted in an election.

#### `get-vote`
Retrieves vote details for a voter in an election.

#### `is-eligible-voter`
Verifies if a user is authorized to vote in an election.

#### `get-election-status`
Returns comprehensive election status including timing information.

#### `get-next-election-id`
Gets the next available election ID.

#### `get-contract-owner`
Returns the contract owner's address.

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | `ERR_NOT_AUTHORIZED` | Caller lacks required permissions |
| 101 | `ERR_ELECTION_NOT_FOUND` | Election ID does not exist |
| 102 | `ERR_ELECTION_NOT_ACTIVE` | Election is not currently active |
| 103 | `ERR_ALREADY_VOTED` | Voter has already cast their vote |
| 104 | `ERR_CANDIDATE_NOT_FOUND` | Candidate ID does not exist |
| 105 | `ERR_ELECTION_ENDED` | Election has already ended |
| 106 | `ERR_INVALID_VOTER` | Voter is not eligible for this election |
| 107 | `ERR_ELECTION_ALREADY_EXISTS` | Election ID already in use |

## Data Structures

### Elections Map
```clarity
{
  title: (string-ascii 100),
  description: (string-ascii 500), 
  start-block: uint,
  end-block: uint,
  is-active: bool,
  creator: principal
}
```

### Candidates Map
```clarity
{
  name: (string-ascii 50),
  description: (string-ascii 200),
  vote-count: uint,
  candidate-address: principal
}
```

### Votes Map
```clarity
{
  candidate-id: uint,
  block-height: uint
}
```

## Security Considerations

### Access Control
- Only contract owner can create elections and add candidates/voters
- Strict validation on all public functions
- Immutable vote records once cast

### Vote Integrity
- One vote per eligible voter per election
- Votes are recorded with block height for auditability
- No vote modification after casting

### Election Security
- Block-based timing prevents manipulation
- Elections can only be created by authorized administrators
- Voter eligibility must be explicitly granted

### Best Practices
1. **Voter Registration**: Add eligible voters before election start
2. **Candidate Setup**: Register all candidates before voting begins
3. **Timing**: Allow sufficient blocks for voting period
4. **Testing**: Thoroughly test on devnet/testnet before mainnet deployment

## Development

### Project Structure
```
StudentGov/
├── README.md
└── StudentGov_contract/
    ├── Clarinet.toml          # Clarinet configuration
    ├── contracts/
    │   └── StudentGov.clar    # Main smart contract
    ├── tests/
    │   └── StudentGov.test.ts # Contract tests
    ├── settings/              # Network configurations
    │   ├── Devnet.toml
    │   ├── Testnet.toml
    │   └── Mainnet.toml
    └── package.json           # Node.js dependencies
```

### Contributing
1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the ISC License.

## Support

For questions, issues, or contributions, please open an issue in the project repository.

---

**⚠️ Disclaimer**: This smart contract is for educational and development purposes. Conduct thorough security audits before deploying to mainnet for production use.