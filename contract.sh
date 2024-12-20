#!/bin/bash
# Logo
curl -s https://raw.githubusercontent.com/ToanBm/user-info/main/logo.sh | bash
sleep 3

show() {
    echo -e "\033[1;35m$1\033[0m"
}

# Step 1: Install hardhat
echo "Install Hardhat..."
npm init -y
npm install --save-dev hardhat @nomiclabs/hardhat-ethers ethers @openzeppelin/contracts
echo "Install dotenv..."
npm install dotenv

# Step 2: Automatically choose "Create an empty hardhat.config.js"
echo "Creating project with an empty hardhat.config.js..."
yes "3" | npx hardhat init

# Step 3: Create MyToken.sol contract
echo "Create ERC20 contract..."
mkdir contracts 
cat <<'EOF' > contracts/MyToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Chainbase Token Test", "CBT") {
        _mint(msg.sender, initialSupply);
    }
}
EOF

# Step 4: Create .env file for storing private key
echo "Create .env file..."

read -p "Enter your EVM wallet private key (without 0x): " PRIVATE_KEY
cat <<EOF > .env
PRIVATE_KEY=$PRIVATE_KEY
EOF

# Step 5: Update hardhat.config.js with the proper configuration
echo "Creating new hardhat.config file..."
rm hardhat.config.js

cat <<'EOF' > hardhat.config.js
/** @type import('hardhat/config').HardhatUserConfig */
require('dotenv').config();
require("@nomiclabs/hardhat-ethers");

module.exports = {
  solidity: "0.8.20",
  networks: {
    chainbase: {
      url: "https://testnet.s.chainbase.com",
      chainId: 2233,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
  }
};
EOF

# Step 6: Create deploy script
echo "Creating deploy script..."
mkdir scripts

cat <<'EOF' > scripts/deploy.js
const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    const initialSupply = ethers.utils.parseUnits("1000", "ether");

    const Token = await ethers.getContractFactory("MyToken");
    const token = await Token.deploy(initialSupply);

    console.log("Token deployed to:", token.address);
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
EOF

# Step 7: Compile contracts
echo "Compile your contracts..."
npx hardhat compile

# "Waiting before deploying..."
sleep 3
# Yêu cầu nhập số lượng contract cần deploy
read -p "Enter the number of contracts to deploy: " NUMBER_OF_CONTRACTS

# Kiểm tra số lượng có phải là số hợp lệ không
if ! [[ "$NUMBER_OF_CONTRACTS" =~ ^[0-9]+$ ]]; then
  echo "Invalid input. Please enter a valid number."
  exit 1
fi

# Lặp lệnh deploy
for ((i=1; i<=NUMBER_OF_CONTRACTS; i++)); do
  print_command "Deploying contract #$i..."
  npx hardhat run scripts/deploy.js --network chainbase

  # Thời gian chờ ngẫu nhiên từ 3 đến 7 giây
  RANDOM_DELAY=$(shuf -i 3-7 -n 1)  # Chọn số ngẫu nhiên từ 3 đến 7
  echo "Waiting for $RANDOM_DELAY seconds before next deploy..."
  sleep $RANDOM_DELAY
done

print_command "Successfully deployed $NUMBER_OF_CONTRACTS smart contracts!"
echo "Thank you!"
