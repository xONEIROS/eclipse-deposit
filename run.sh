#!/bin/bash

echo "           $$$$$$\  $$\   $$\ $$$$$$$$\ $$$$$$\ $$$$$$$\   $$$$$$\   $$$$$$\  "
echo "          $$  __$$\ $$$\  $$ |$$  _____|\_$$  _|$$  __$$\ $$  __$$\ $$  __$$\ "
echo "$$\   $$\ $$ /  $$ |$$$$\ $$ |$$ |        $$ |  $$ |  $$ |$$ /  $$ |$$ /  \__|"
echo "\$$\ $$  |$$ |  $$ |$$ $$\$$ |$$$$$\      $$ |  $$$$$$$  |$$ |  $$ |\$$$$$$\  "
echo " \$$$$  / $$ |  $$ |$$ \$$$$ |$$  __|     $$ |  $$  __$$< $$ |  $$ | \____$$\ "
echo " $$  $$<  $$ |  $$ |$$ |\$$$ |$$ |        $$ |  $$ |  $$ |$$ |  $$ |$$\   $$ |"
echo "$$  /\$$\  $$$$$$  |$$ | \$$ |$$$$$$$$\ $$$$$$\ $$ |  $$ | $$$$$$  |\$$$$$$  |"
echo "\__/  \__| \______/ \__|  \__|\________|\______|\__|  \__| \______/  \______/ "
echo "                                                                              "
echo "                                                                              "
echo "                                                                              "

sleep 2

# Function to display the menu
display_menu() {
    echo "1. Edit wallet address"
    echo "2. Edit private key file path"
    echo "3. Edit Solana destination address"
    echo "4. Edit amount of Ether to deposit"
    echo "5. Select network (mainnet or sepolia)"
    echo "6. Edit JSON RPC URL (optional)"
    echo "7. Set number of transactions"
    echo "8. Start transactions"
    echo "9. Exit"
}

# Load previous settings if they exist
if [ -f ~/.eclipse_deposit_settings ]; then
    source ~/.eclipse_deposit_settings
fi

# Function to edit variables
edit_variable() {
    case $1 in
        1) read -p "Enter your wallet address: " wallet_address ;;
        2) read -p "Enter the path to your private key file: " key_file ;;
        3) read -p "Enter the Solana destination address: " destination_address ;;
        4) read -p "Enter the amount of Ether to deposit: " amount ;;
        5) 
            read -p "Enter the network (mainnet or sepolia): " network 
            if [[ "$network" != "mainnet" && "$network" != "sepolia" ]]; then
                echo "Invalid network. Please enter either 'mainnet' or 'sepolia'."
                edit_variable 5
            fi
            ;;
        6) read -p "Enter the JSON RPC URL (optional): " rpc_url ;;
        7) read -p "Enter the number of transactions to perform: " num_transactions ;;
    esac
}

# Check if we have previous settings
if [ -n "$wallet_address" ] && [ -n "$key_file" ] && [ -n "$destination_address" ] && [ -n "$amount" ] && [ -n "$network" ] && [ -n "$num_transactions" ]; then
    echo "Previous settings found."
    read -p "Do you want to continue with the previous settings? (y/n): " use_previous
    if [[ "$use_previous" != "y" ]]; then
        while true; do
            display_menu
            read -p "Choose an option: " choice
            case $choice in
                1|2|3|4|5|6|7) edit_variable $choice ;;
                8) break ;;
                9) exit 0 ;;
                *) echo "Invalid option. Please try again." ;;
            esac
        done
    fi
else
    while true; do
        display_menu
        read -p "Choose an option: " choice
        case $choice in
            1|2|3|4|5|6|7) edit_variable $choice ;;
            8) break ;;
            9) exit 0 ;;
            *) echo "Invalid option. Please try again." ;;
        esac
    done
fi

# Save settings for future use
echo "wallet_address=\"$wallet_address\"" > ~/.eclipse_deposit_settings
echo "key_file=\"$key_file\"" >> ~/.eclipse_deposit_settings
echo "destination_address=\"$destination_address\"" >> ~/.eclipse_deposit_settings
echo "amount=\"$amount\"" >> ~/.eclipse_deposit_settings
echo "network=\"$network\"" >> ~/.eclipse_deposit_settings
echo "rpc_url=\"$rpc_url\"" >> ~/.eclipse_deposit_settings
echo "num_transactions=\"$num_transactions\"" >> ~/.eclipse_deposit_settings

# Installation steps and requirements
echo "Checking for required tools..."

# Check for Yarn
if ! command -v yarn &> /dev/null
then
    echo "Yarn not found. Installing Yarn..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install yarn
    else
        npm install -g yarn
    fi
else
    echo "Yarn is already installed."
fi

# Instructions for Ethereum Wallet (Metamask)
echo "Please ensure you have an Ethereum wallet such as Metamask."
echo "For Metamask:"
echo "1. Choose the account you wish to use and copy its address."
echo "2. Visit the Sepolia faucet to airdrop tokens to yourself, if using Sepolia."
echo "3. Navigate to 'account details' in MetaMask and select 'reveal private key'. Store this key in a secure file."
sleep 4
# Check for Solana CLI
if ! command -v solana &> /dev/null
then
    echo "Solana CLI not found. Installing Solana CLI tools..."
    sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
else
    echo "Solana CLI is already installed."
fi

# Instructions for generating a Solana wallet
echo "To generate a Solana wallet for deposits:"
echo "1. Execute solana-keygen new --no-outfile or solana-keygen new --outfile my-wallet.json."
echo "2. Copy the public key from the output, which should resemble 6g8wB6cJbodeYaEb5aD9QYqhdxiS8igfcHpz36oHY7p8."

# Clone the repository and install dependencies
if [ ! -d ~/eclipse-deposit ]; then
    echo "Cloning the repository..."
    git clone https://github.com/Eclipse-Laboratories-Inc/eclipse-deposit.git ~/eclipse-deposit
    cd ~/eclipse-deposit
    echo "Installing dependencies..."
    yarn install
else
    echo "Repository already cloned and dependencies installed."
    cd ~/eclipse-deposit
fi

# Perform transactions
for ((i=1; i<=num_transactions; i++))
do
  echo "Performing transaction $i..."
  
  # Construct the command
  command="node bin/cli.js -k \"$key_file\" -d \"$destination_address\" -a \"$amount\""
  
  # Add network option
  if [ -n "$network" ];then
    command="$command --$network"
  fi

  # Add RPC URL option if provided
  if [ -n "$rpc_url" ]; then
    command="$command -r \"$rpc_url\""
  fi

  # Execute the transaction command
  eval $command

  # Check if the transaction was successful
  if [ $? -eq 0 ]; then
    echo "Transaction $i completed successfully."
  else
    echo "Transaction $i failed."
    exit 1
  fi
done

echo "All transactions completed."
