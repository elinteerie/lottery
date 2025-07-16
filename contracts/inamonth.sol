// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@coti-io/coti-contracts/contracts/utils/mpc/MpcCore.sol";
import "hardhat/console.sol";

contract WalletDistributor {
    /// @notice Track the next willId per user
    mapping(address => uint256) public nextWillId;

    /// @notice Track all willIds per user
    mapping(address => uint256[]) public userWillIds;

    /// @notice owner => willId => (sub-wallet => percentage)
    mapping(address => mapping(uint256 => mapping(address => uint256))) private distributions;

    /// @notice owner => willId => list of sub-wallets
    mapping(address => mapping(uint256 => address[])) private subWallets;

    /// @notice owner => willId => total assigned percentage
    mapping(address => mapping(uint256 => uint256)) private totalPercentage;

    /// @notice owner => willId => amount to share
    mapping(address => mapping(uint256 => utUint64)) private amountToShare;
    mapping(address => mapping(uint256 => uint256)) public inactivityPeriod;


    /// @notice owner => willId => distribution time (UNIX timestamp)
    mapping(address => mapping(uint256 => uint256)) private distributionTimestamp;
    mapping(address => mapping(uint256 => uint256)) public willBalances;


    event WillDistributed(
    address indexed owner,
    uint256 indexed willId,
    address indexed inheritor,
    uint256 amount
);


    constructor() {}

    /// @notice Create a new will & initialize its distribution
    function initializeDistribution(
        address[] memory wallets,
        uint256[] memory percentages,
        uint256 timestamp,                 // optional: if 0, ignored
        uint256 inactivityMonths          // optional: if 0, ignored
    ) public returns (uint256 willId) {
        require(wallets.length == percentages.length, "Mismatched input lengths");

        address owner = msg.sender;

        willId = nextWillId[owner];
        nextWillId[owner]++;

        // At least one of the two conditions must be specified
        require(timestamp > 0 || inactivityMonths > 0, "At least one condition required");

        uint256 total = 0;

        for (uint256 i = 0; i < wallets.length; i++) {
            require(percentages[i] > 0, "Percentage must be > 0");
            address wallet = wallets[i];
            uint256 percentage = percentages[i];

            require(distributions[owner][willId][wallet] == 0, "Wallet already added");

            distributions[owner][willId][wallet] = percentage;
            subWallets[owner][willId].push(wallet);
            total += percentage;
        }

        require(total == 100, "Total percentage must be exactly 100");

        totalPercentage[owner][willId] = 100;
        distributionTimestamp[owner][willId] = timestamp;
        inactivityPeriod[owner][willId] = inactivityMonths;

        // Initialize encrypted amount to 0
        gtUint64 gtZero = MpcCore.setPublic64(0);
        amountToShare[owner][willId] = MpcCore.offBoardCombined(gtZero, owner);

        userWillIds[owner].push(willId);

        return willId;
    }
    /// @notice Set amount to share for a specific will
    function setAmountToShare(uint256 willId, itUint64 calldata value) external payable {
        require(msg.value > 0, "You must send some Ether");

        gtUint64 value_ = MpcCore.validateCiphertext(value);
        gtUint64 sum_ = MpcCore.onBoard(amountToShare[msg.sender][willId].ciphertext);

        sum_ = MpcCore.add(sum_, value_);

        amountToShare[msg.sender][willId] = MpcCore.offBoardCombined(sum_, msg.sender);
        willBalances[msg.sender][willId] += msg.value;

    }

    /// @notice Distribute funds for a specific will
    /// @notice Distribute funds for a specific will
    /// observedInactivityMonths: pass 0 if not checking inactivity
    function distribute(address owner, uint256 willId, uint256 observedInactivityMonths) public {
    uint256 total = willBalances[owner][willId];
    uint256 requiredInactivity = inactivityPeriod[owner][willId];
    uint256 timestamp = distributionTimestamp[owner][willId];

    require(total > 0, "No amount to distribute");
    require(totalPercentage[owner][willId] == 100, "Total % != 100");

    bool hasTimestamp = (timestamp != 0);
    bool hasInactivity = (requiredInactivity > 0);

    require(hasTimestamp || hasInactivity, "No condition set");

    require(
        _conditionMet(timestamp, requiredInactivity, observedInactivityMonths),
        "Neither condition met"
    );

    _distributeFunds(owner, willId, total);
}

function _conditionMet(
    uint256 timestamp,
    uint256 requiredInactivity,
    uint256 observedInactivityMonths
) internal view returns (bool) {
    bool releaseTimeReached = (timestamp != 0 && block.timestamp >= timestamp);
    bool inactivityMet = (requiredInactivity != 0 && observedInactivityMonths >= requiredInactivity);
    return releaseTimeReached || inactivityMet;
}

function _distributeFunds(
    address owner,
    uint256 willId,
    uint256 total
) internal {
    address[] memory wallets = subWallets[owner][willId];
    for (uint256 i = 0; i < wallets.length; i++) {
        address wallet = wallets[i];
        uint256 share = (total * distributions[owner][willId][wallet]) / 100;

        (bool sent, ) = wallet.call{value: share}("");
        require(sent, "Transfer failed");

        emit WillDistributed(owner, willId, wallet, share);
    }

    willBalances[owner][willId] = 0;
    distributionTimestamp[owner][willId] = 0;
}

    /// @notice Get details of your specific will
    function getMyDistributionDetails(uint256 willId)
        external
        view
        returns (
            address[] memory wallets,
            uint256[] memory percentages,
            uint256 timestamp
        )
    {
        address owner = msg.sender;
        address[] memory _wallets = subWallets[owner][willId];
        uint256[] memory _percentages = new uint256[](_wallets.length);

        for (uint256 i = 0; i < _wallets.length; i++) {
            _percentages[i] = distributions[owner][willId][_wallets[i]];
        }

        return (_wallets, _percentages, distributionTimestamp[owner][willId]);
    }

    /// @notice Get details of any user’s specific will
    function getUserDistributionDetails(address owner, uint256 willId)
        external
        view
        returns (
            address[] memory wallets,
            uint256[] memory percentages,
            uint256 timestamp
        )
    {
        address[] memory _wallets = subWallets[owner][willId];
        uint256[] memory _percentages = new uint256[](_wallets.length);

        for (uint256 i = 0; i < _wallets.length; i++) {
            _percentages[i] = distributions[owner][willId][_wallets[i]];
        }

        return (_wallets, _percentages, distributionTimestamp[owner][willId]);
    }

    /// @notice Get encrypted amount to share for your specific will
    function getMyAmountToShare(uint256 willId) external view returns (ctUint64) {
        return amountToShare[msg.sender][willId].userCiphertext;
    }

    /// @notice Check if a specific will’s distribution is valid
    function isValidDistribution(uint256 willId) public view returns (bool) {
        address owner = msg.sender;
        return totalPercentage[owner][willId] == 100;
    }

    /// @notice Get all your willIds
    function getMyWillIds() external view returns (uint256[] memory) {
        return userWillIds[msg.sender];
    }

    /// @notice Get all willIds for any user
    function getUserWillIds(address owner) external view returns (uint256[] memory) {
        return userWillIds[owner];
    }

}