// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint);
}


contract cipManager {

    address public manager;

    struct Inheritor {
    address payable wallet;
    uint256 percentage; // for example, 25 for 25%
    }


   struct Will {
    Inheritor[] inheritors;
    uint256 releaseTime;
    uint256 depositedAmount;
    bool exists;
    bool distributed;
}

    mapping(address => Will) private wills;


    function createWill(Inheritor[] memory _inheritors, uint256 _releaseTime) public {
    require(!wills[msg.sender].exists, "Will already exists");
    require(_releaseTime > block.timestamp, "Release time must be in the future");

    uint256 totalPercent = 0;
    for (uint i = 0; i < _inheritors.length; i++) {
        totalPercent += _inheritors[i].percentage;
    }
    require(totalPercent == 100, "Total percentage must equal 100");

    Will storage newWill = wills[msg.sender];
    newWill.releaseTime = _releaseTime;
    newWill.exists = true;

    for (uint i = 0; i < _inheritors.length; i++) {
        newWill.inheritors.push(_inheritors[i]);
    }
}

    function getWill(address willer) public view returns (
    address[] memory inheritorAddresses,
    uint256[] memory inheritorPercentages,
    uint256 releaseTime,
    uint256 depositedAmount,
    bool exists,
    bool distributed
) {
    Will storage will = wills[willer];
    require(will.exists, "Will does not exist");

    uint256 count = will.inheritors.length;

    inheritorAddresses = new address[](count);
    inheritorPercentages = new uint256[](count);

    for (uint i = 0; i < count; i++) {
        inheritorAddresses[i] = will.inheritors[i].wallet;
        inheritorPercentages[i] = will.inheritors[i].percentage;
    }

    releaseTime = will.releaseTime;
    depositedAmount = will.depositedAmount;
    exists = will.exists;
    distributed = will.distributed;
}

    function fundWill() public payable {
    Will storage will = wills[msg.sender];
    require(will.exists, "Will does not exist");
    require(msg.value > 0, "Must send some ETH to fund the will");

    will.depositedAmount += msg.value;
}



    function distributeWill(address willer) public {
    Will storage will = wills[willer];
    require(will.exists, "Will does not exist");
    require(block.timestamp >= will.releaseTime, "Release time not reached");
    require(will.depositedAmount > 0, "No funds to distribute");

    uint256 totalAmount = will.depositedAmount;
    will.depositedAmount = 0; // reset before transfers for safety
    will.distributed = true;  // mark as distributed

    for (uint i = 0; i < will.inheritors.length; i++) {
        Inheritor memory inheritor = will.inheritors[i];
        uint256 share = (totalAmount * inheritor.percentage) / 100;
        (bool sent, ) = inheritor.wallet.call{value: share}("");
        require(sent, "Failed to send Ether");
    }
}




}