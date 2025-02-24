# RealtyVault: Blockchain Escrow System for Property Transactions

## Overview

RealtyVault is a secure and transparent blockchain-based escrow system designed specifically for real estate transactions. Built on the Clarity smart contract language, RealtyVault provides a trustless environment for property transfers, protecting both buyers and sellers throughout the transaction process.

## Features

- **Secure Escrow**: Holds buyer's deposit in a secure, tamper-proof contract
- **Property Registration**: Allows property details to be permanently recorded on-chain
- **Inspection Integration**: Supports third-party property inspections with on-chain verification
- **Automatic Deadlines**: Enforces transaction timeframes with blockchain-based timestamps
- **Transparent Payments**: Tracks all financial transactions with immutable records
- **Maintenance Fund**: Optional property maintenance reserve functionality

## How It Works

1. **Escrow Initialization**: The contract admin establishes an escrow between verified seller and buyer
2. **Property Registration**: Seller registers property details (location, size, construction date)
3. **Buyer Deposit**: Buyer sends earnest money deposit (typically 10% of property value)
4. **Inspection**: An authorized inspector records inspection results on-chain
5. **Payment Completion**: Upon passing inspection, buyer completes the remaining payment
6. **Transaction Finalization**: Property ownership transfers, and the contract records completion

## Smart Contract Functions

### Admin Functions

- `initialize-escrow`: Set up a new property transaction with verified parties
- `record-inspection`: Record results of property inspection
- `refund-deposit`: Return deposit to buyer if transaction fails

### Seller Functions

- `register-property`: Record property details on the blockchain

### Buyer Functions

- `send-deposit`: Submit earnest money deposit to the escrow
- `finalize-payment`: Complete the full payment to finalize transaction
- `add-maintenance-funds`: Optionally add funds for property maintenance

### Read-Only Functions

- `get-escrow-details`: Retrieve current escrow status and details
- `get-transaction-details`: View transaction history for a payment
- `get-property-details`: Access registered property information
- `is-approved-participant`: Check if an account is verified in the system
- `get-time-remaining`: Calculate remaining time before deadline

## Security Features

- **Time-Locked Transactions**: All actions must occur within predefined timeframes
- **Participant Verification**: Only approved accounts can participate in transactions
- **Overflow Protection**: Arithmetic guards prevent numeric overflows
- **Data Validation**: Extensive validation of all property data and transaction amounts
- **Status Checks**: Strict state machine ensures operations happen in correct sequence

## Technical Requirements

- Clarity-compatible blockchain (e.g., Stacks)
- Access to blockchain node for deployment
- Private keys for contract interaction

## Getting Started

### Deployment

1. Install a Clarity development environment
2. Deploy the contract to your chosen network
3. Initialize the contract with admin credentials

### Usage Example

```clarity
;; Initialize a new escrow
(contract-call? .realtyvault initialize-escrow 
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM  ;; Seller
  'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG  ;; Buyer
  u500000  ;; Price (in microstacks)
  u30)      ;; Duration (in days)

;; Register property
(contract-call? .realtyvault register-property 
  u12345  ;; Property ID
  "123 Blockchain Avenue, Cryptoville"  ;; Address
  u2500  ;; Square footage
  u2015)  ;; Year built
```

## Best Practices

- Always verify transaction parties before initializing escrow
- Set reasonable timeframes based on expected closing processes
- Conduct all property inspections prior to deposit submission
- Maintain secure key management for all participants
- Review all transaction details before finalization

## License

This project is licensed under [LICENSE TYPE] - see the LICENSE file for details.

## Contribution

Contributions are welcome! Please see CONTRIBUTING.md for details on how to participate.

## Disclaimer

This software is provided as-is, without warranty of any kind. Users are responsible for ensuring compliance with all applicable laws and regulations related to real estate transactions in their jurisdictions.