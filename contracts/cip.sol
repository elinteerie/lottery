// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Inheritance {

    address public willer; 
    uint public totalInheritors;
    

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






    //function getInheritors() public view returns (address payable[] memory) {
    //    return _inheritor;

    //}




}