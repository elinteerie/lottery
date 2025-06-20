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

    // Set percentage distribution for sub-wallets and Due Date
    function initializeDistribution(
    address[] memory wallets,
    uint256[] memory percentages,
    uint256 timestamp
) public {
    require(wallets.length == percentages.length, "Mismatched input lengths");

    address owner = msg.sender;

    // Ensure distributions and timestamp haven't already been set
    require(subWallets[owner].length == 0, "Distributions already set");
    require(distributionTimestamp[owner] == 0, "Timestamp already set");
    require(timestamp > block.timestamp, "Timestamp must be in the future");

    uint256 total = 0;

    for (uint256 i = 0; i < wallets.length; i++) {
        require(percentages[i] > 0, "Percentage must be greater than 0");
        address wallet = wallets[i];
        uint256 percentage = percentages[i];

        require(distributions[owner][wallet] == 0, "Wallet already added");

        distributions[owner][wallet] = percentage;
        subWallets[owner].push(wallet);
        total += percentage;
    }

    require(total == 100, "Total percentage must be exactly 100");

    totalPercentage[owner] = 100;
    distributionTimestamp[owner] = timestamp;
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

function getMyDistributionDetails()
    external
    view
    returns (
        address[] memory wallets,
        uint256[] memory percentages,
        uint256 timestamp
    )
{
    address owner = msg.sender;
    address[] memory _wallets = subWallets[owner];
    uint256[] memory _percentages = new uint256[](_wallets.length);

    for (uint256 i = 0; i < _wallets.length; i++) {
        _percentages[i] = distributions[owner][_wallets[i]];
    }

    return (_wallets, _percentages, distributionTimestamp[owner]);
}



function getUserDistributionDetails(address owner)
    external
    view
    returns (
        address[] memory wallets,
        uint256[] memory percentages,
        uint256 timestamp
    )
{
    
    address[] memory _wallets = subWallets[owner];
    uint256[] memory _percentages = new uint256[](_wallets.length);

    for (uint256 i = 0; i < _wallets.length; i++) {
        _percentages[i] = distributions[owner][_wallets[i]];
    }

    return (_wallets, _percentages, distributionTimestamp[owner]);
}


    function getMyAmountToShare() external view returns (ctUint64) {
    return amountToShare[msg.sender].userCiphertext;
}


    // Check if the owner's total percentage equals 100
    function isValidDistribution() public view returns (bool) {
        address owner = msg.sender;
        return totalPercentage[owner] == 100;
    }
}
