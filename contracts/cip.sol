// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint);
}

contract Inheritance {

    address public willer; 
    uint public totalInheritors;
    uint public releaseTime;
    

    struct Inheritor {
        address payable inheritor;
        uint percentage; // e.g., 25 = 25%
    }

    Inheritor[] public  inheritors;

    constructor(){
        willer = msg.sender;
    }

    modifier onlyWiller() {
        require(msg.sender == willer, "Only the willer can do this");
        _;
    }

    function enterInheritorsWithPercentages(
        address payable[] memory _inheritors,
        uint[] memory _percentages
    ) public payable onlyWiller {
        require(_inheritors.length == _percentages.length, "Length mismatch");
        require(_inheritors.length > 0, "At least one inheritor required");

        uint totalPercent = 0;

        for (uint i = 0; i < _inheritors.length; i++) {
            totalPercent += _percentages[i];
            inheritors.push(Inheritor({
                inheritor: _inheritors[i],
                percentage: _percentages[i]
            }));
        }

        require(totalPercent == 100, "Total percentage must equal 100");
    }

    function getAllInheritors() public view returns (address payable[] memory, uint[] memory) {
    uint length = inheritors.length;
    address payable[] memory addresses = new address payable[](length);
    uint[] memory percentages = new uint[](length);

    for (uint i = 0; i < length; i++) {
        addresses[i] = inheritors[i].inheritor;
        percentages[i] = inheritors[i].percentage;
    }

    return (addresses, percentages);
}

    function setReleaseTime(uint timestamp) public onlyWiller {
        require(timestamp > block.timestamp, "Must be future time");
        releaseTime = timestamp;
    }

    function getReleaseTime() public view returns (uint) {
    return releaseTime;
}


    function fundWill() public payable onlyWiller {
    require(msg.value > 0, "You must send some ETH");
    // ETH sent is now stored in the contract
}

    function distributeWill() public onlyWiller {
    require(block.timestamp >= releaseTime, "Will is still locked");
    require(inheritors.length > 0, "No inheritors set");
    uint totalBalance = address(this).balance;
    require(totalBalance > 0, "No ETH to distribute");

    uint totalPercent = 0;

    for (uint i = 0; i < inheritors.length; i++) {
        totalPercent += inheritors[i].percentage;
    }

    require(totalPercent == 100, "Total percentage must be 100");

    for (uint i = 0; i < inheritors.length; i++) {
        uint amount = (totalBalance * inheritors[i].percentage) / 100;
        inheritors[i].inheritor.transfer(amount);
    }

    // Optional: clear inheritors after distribution
    //delete inheritors;
}


    function distributeToken(address tokenAddress) public onlyWiller {
    require(block.timestamp >= releaseTime, "Will is still locked");

    IERC20 token = IERC20(tokenAddress);
    uint totalBalance = token.balanceOf(address(this));
    require(totalBalance > 0, "No tokens to distribute");

    uint totalPercent = 0;
    for (uint i = 0; i < inheritors.length; i++) {
        totalPercent += inheritors[i].percentage;
    }
    require(totalPercent == 100, "Total percent must equal 100");

    for (uint i = 0; i < inheritors.length; i++) {
        uint amount = (totalBalance * inheritors[i].percentage) / 100;
        require(token.transfer(inheritors[i].inheritor, amount), "Token transfer failed");
    }

    delete inheritors;
}






    //function getInheritors() public view returns (address payable[] memory) {
    //    return _inheritor;

    //}




}