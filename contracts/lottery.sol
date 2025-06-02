// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {

    address public manager; 
    address payable[] public players; // payable addresses so we can transfer Ether
    address payable public winner;

    constructor(){
        manager = msg.sender;
    }


    function enter() public payable  {
        require(msg.value > 100000000000000000, "You have to send it 1 Ether");
        players.push(payable(msg.sender));

    }

    function random() private view returns (uint) {
        return uint((keccak256(abi.encodePacked(block.difficulty, block.timestamp, players))));
    }


    function pickWinner() public restricted {
        uint index = random() % players.length;
        winner = players[index];
        winner.transfer(address(this).balance);
        delete players; // ✅ Clears the array properly

    }


    modifier restricted() {
    require(msg.sender == manager, "Only manager can call this");
    _;
}

    function getPlayer() public view returns (address payable[] memory) {
        return players;

    }




}