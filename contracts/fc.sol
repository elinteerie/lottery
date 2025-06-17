// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


import "@coti-io/coti-contracts/contracts/utils/mpc/MpcCore.sol";
import "hardhat/console.sol";

contract WalletDistributor {
    // Mapping from owner to (sub-wallet => percentage)
    mapping(address => mapping(address => uint256)) private distributions;

    // owner => list of sub-wallets
    mapping(address => address[]) private subWallets;

    // owner => total assigned percentage
    mapping(address => uint256) private totalPercentage;

    // owner => amount to share
    mapping(address => utUint64) private amountToShare;

    // owner => distribution time (UNIX timestamp)
    mapping(address => uint256) private distributionTimestamp;


    constructor(){
        gtUint64 gtZero = MpcCore.setPublic64(0);
        amountToShare[msg.sender] = MpcCore.offBoardCombined(gtZero, msg.sender); 

    }

    // Set percentage distribution for sub-wallets
    function setDistribution(address wallet, uint256 percentage) public {
    address owner = msg.sender;
    uint256 current = distributions[owner][wallet];

    require(
        totalPercentage[owner] - current + percentage <= 100,
        "Total percentage cannot exceed 100"
    );

    if (current == 0 && percentage > 0) {
        subWallets[owner].push(wallet);
    }

    totalPercentage[owner] = totalPercentage[owner] - current + percentage;
    distributions[owner][wallet] = percentage;
}

    // Owner sets the amount they want to share
    function setAmountToShare(itUint64 calldata value) external payable {
        require(msg.value > 0, "You must send some Ether");
        gtUint64 value_ = MpcCore.validateCiphertext(value);
        gtUint64 sum_ = MpcCore.onBoard(amountToShare[msg.sender].ciphertext);

        sum_ = MpcCore.add(sum_, value_);

        amountToShare[msg.sender] = MpcCore.offBoardCombined(sum_, msg.sender);

       // amountToShare[msg.sender] += msg.value;
    }

    // Owner sets the future time when distribution is allowed
    function setDistributionTimestamp(uint256 timestamp) external {
    require(distributionTimestamp[msg.sender] == 0, "Timestamp already set");
    require(timestamp > block.timestamp, "Timestamp must be in the future");

    distributionTimestamp[msg.sender] = timestamp;
}

    // Distribute funds if conditions are met
    function distribute() public {
        address owner = msg.sender;
        gtUint64 sum_ = MpcCore.onBoard(amountToShare[owner].ciphertext);
        uint64 oya = MpcCore.decrypt(sum_);
        
        //uint256 total = amountToShare[owner];
        uint256 total = uint256(oya);
        console.log("Total to Share:", total);
        require(total > 0, "No amount to distribute");
        require(totalPercentage[owner] == 100, "Total percentage must be 100%");
        require(distributionTimestamp[owner] != 0, "Distribution time not set");
        require(block.timestamp >= distributionTimestamp[owner], "Too early to distribute");

        address[] memory wallets = subWallets[owner];
        for (uint256 i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];
            uint256 share = (total * distributions[owner][wallet]) / 100;
            (bool sent, ) = wallet.call{value: share}("");
            require(sent, "Transfer failed");
        }

        // Reset
        gtUint64 gtZero = MpcCore.setPublic64(0);
        amountToShare[msg.sender] = MpcCore.offBoardCombined(gtZero, msg.sender);
        //amountToShare[owner] = 0;
        distributionTimestamp[owner] = 0;
    }

    // Get sub-wallets list for an owner
    function getSubWallets() public view returns (address[] memory) {
        address owner = msg.sender;
        return subWallets[owner];
    }

    function getMyAmountToShare() external view returns (ctUint64) {
    return amountToShare[msg.sender].userCiphertext;
}

    // Remove a sub-wallet and update totals
    function removeWallet(address owner, address wallet) public {
        uint256 existing = distributions[owner][wallet];
        require(existing > 0, "Wallet not found");

        totalPercentage[owner] -= existing;
        delete distributions[owner][wallet];

        address[] storage wallets = subWallets[owner];
        for (uint256 i = 0; i < wallets.length; i++) {
            if (wallets[i] == wallet) {
                wallets[i] = wallets[wallets.length - 1];
                wallets.pop();
                break;
            }
        }
    }

    // Check if the owner's total percentage equals 100
    function isValidDistribution() public view returns (bool) {
        address owner = msg.sender;
        return totalPercentage[owner] == 100;
    }
}
