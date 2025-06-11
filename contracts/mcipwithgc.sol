// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@coti-io/coti-contracts/contracts/utils/mpc/MpcCore.sol";



contract cipManager {

    event TotalAmountDecrypted(uint64 amount);

    address public manager;

    struct Inheritor {
        address payable wallet;
        uint256 percentage;
    }

    struct Will {
        Inheritor[] inheritors;
        uint64 releaseTime;
        uint64 depositedAmount; // encrypted
        bool exists;
        bool distributed;
    }

    mapping(address => Will) private wills;

    function createWill(Inheritor[] memory _inheritors, uint64 _releaseTime) public {
        require(!wills[msg.sender].exists, "Will already exists");
        require(_releaseTime > uint64(block.timestamp), "Release time must be future");

        uint256 totalPercent = 0;
        for (uint i = 0; i < _inheritors.length; i++) {
            totalPercent += _inheritors[i].percentage;
        }
        require(totalPercent == 100, "Total percentage must equal 100");

        Will storage newWill = wills[msg.sender];
        newWill.releaseTime = _releaseTime;
        newWill.exists = true;
        newWill.depositedAmount = 0;  // initialize as encrypted zero

        for (uint i = 0; i < _inheritors.length; i++) {
            newWill.inheritors.push(_inheritors[i]);
        }
    }

    function getWill(address willer) public view returns (
        address[] memory inheritorAddresses,
        uint256[] memory inheritorPercentages,
        uint64 releaseTime,
        //uint64 depositedAmount,  // decrypted view
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
        //depositedAmount = MpcCore.offBoard(will.depositedAmount);
        //depositedAmount = MpcCore.decrypt(MpcCore.offBoard(will.depositedAmount));
        //ctUint64 balance = MpcCore.offBoard(will.depositedAmount);
        //gtUint64 balanceGt = MpcCore.onBoard(balance);
        //depositedAmount = MpcCore.decrypt(balanceGt);
        exists = will.exists;
        distributed = will.distributed;
    
    }

    function fundWill() public payable {
        Will storage will = wills[msg.sender];
        require(will.exists, "Will does not exist");
        require(msg.value > 0, "Must send some ETH");

        will.depositedAmount += uint64(msg.value);


        //Make Private now
         
        gtUint64 deposited = MpcCore.setPublic64(uint64(will.depositedAmount));
        ctUint64 balance = MpcCore.offBoard(deposited);
        gtUint64 balanceGt = MpcCore.onBoard(balance);

        //gtUint64 toadd = MpcCore.add(will.depositedAmount, MpcCore.setPublic64(uint64(msg.value)));

        // Validate and onboard user input
       // will.depositedAmount = toadd;


       
        //gtUint64  encryptedValue = MpcCore.setPublic64(uint64(4));

       // will.depositedAmount += encryptedValue;

        //gtUint64 total = MpcCore.add(encryptedValue,will.depositedAmount);
        //will.depositedAmount = total;


        
        

        // Onboard stored balance, compute addition
        //gtUint64 storedVal = MpcCore.onBoard(will.depositedAmount);
        //gtUint64 oldval = will.depositedAmount;
        //gtUint64 newVal = MpcCore.add(encryptedValue,oldval);

        // Offboard back to stored ciphertext

    }



     function distributeWill(address willer) public  {
    Will storage will = wills[willer];
    require(will.exists, "Will does not exist");
    require(!will.distributed, "Will has been disbursed");
    require(block.timestamp >= will.releaseTime, "Release time not reached");
    //ctUint64 balance = MpcCore.offBoard(will.depositedAmount);
    //gtUint64 balanceGt = MpcCore.onBoard(balance);
    //uint64 totalAmount = MpcCore.decrypt(balanceGt);
    uint256 totalAmount = uint64(will.depositedAmount);
    
    //uint64 totalAmount = 1;
    require(uint256(totalAmount)  > 0, "No funds to distribute");

    //uint256 totalAmount = will.depositedAmount;
    //will.depositedAmount = 0; // reset before transfers for safety
    will.distributed = true;  // mark as distributed

    for (uint i = 0; i < will.inheritors.length; i++) {
        Inheritor memory inheritor = will.inheritors[i];
        uint256 share = (uint256(totalAmount) * inheritor.percentage) / 100;
        (bool sent, ) = inheritor.wallet.call{value: share}("");
        require(sent, "Failed to send Ether");
    }
}

}
