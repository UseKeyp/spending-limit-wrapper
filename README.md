# ERC20SpendingLimit

## About This Project
#### ERC20 token that enforces custom spending limits, approvals periods and half-life decay rates

Cryptocurrency is decentralized and not beholden to any 3rd party authorities, which increases token owner autonomy. However, lacking a 3rd party to monitor transactions, flag suspicious behaviour, and freeze accounts leaves token owners vulnerable to complete asset liquidations if their private key, seed phrase, or wallet login process is exposed to hostile actors. Furthermore, many non-native web3 users are not prepared to take full responsibility for their onchain assets.

The ERC20SpendingLimit token provides the convenient security protections of traditional banking, but implements through an ERC20 smart contract to keep token owners' assets decentralized and autonomous beyond the reach of any 3rd party authority. 

These extended limits are enforced through the user's customizable configuration, which can also be set to default parameters:
```
     spent           = sum of `_transfer` during `allowancePeriod`
     spendingLimit   = spending limit during `allowancePeriod`
     allowanceStart  = allowance start-time, set with `spendingLimit`
     allowancePeriod = allowance period before `spent` is reset
     approvalPeriod  = allowance period for token approvals before expiration
     decayInterval   = decay rate half-life of token approvals
     approvalStart   = allowance expiration of token approvals
     
     ---
     
    struct UserConfig {
        uint256 spent;
        uint256 spendingLimit;
        uint256 allowanceStart;
        uint256 allowancePeriod;
        uint256 approvalPeriod;
        uint256 decayInterval;
        mapping(address => uint256) approvalStart;
    }
```

## Install Foundry/Forge
#### Foundry Book: https://book.getfoundry.sh/getting-started/installation

After Foundry is installed and this repo has been cloned, run the following commands:

`forge build`

`forge test`

## How It Works

All ERC20 functionality is assumed. Any address can recieve ERC20SpendingLimit tokens, however outbound spending cannot be executed until the owner of the tokens sets up their `UserConfig`, which enforces their spending limit, allowance period, approval period, and approval decay rate for individual approvals. The user can opt out of any or all limits by setting their configuration to infinite values (max int = 2**256 - 1).


## Contract Verification

#### Forge Verify-Contract: https://book.getfoundry.sh/reference/forge/forge-verify-contract

Token Verification

`forge verify-contract --chain <ID> --flatten --watch --compiler-version "v0.8.11+commit.d7f03943" <CONTRACT_ADDRESS> ERC20SpendingLimit $BLOCK_EXPLORER_KEY`

## License

MIT License

Copyright (c) 2023 Hunter King

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
