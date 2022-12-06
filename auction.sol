//SPDX-License-Identifier:MIT
pragma solidity ^0.8.8;

contract auction{

    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;

    enum state {started,running,ended,cancelled}
    state public auctionState;


    uint public highestBindingBid;
    address payable public highestBidder;

    mapping(address=>uint )public bids;
    uint bidIncrement;

    constructor(){
        owner = payable(msg.sender);
        auctionState=state.running;
        startBlock=block.number;
        endBlock=startBlock+3;
        bidIncrement=100000000000;
        ipfsHash="";
    }

    modifier notOwner(){
        require(msg.sender!=owner);
        _;
    }

    modifier afterStart(){
        require(block.number>=startBlock);
        _;
    }
    
    modifier beforeEnd(){
        require(block.number<=endBlock);
        _;
    }

    modifier onlyOwner(){
            require(msg.sender == owner);
            _;
        }


    function min(uint a,uint b)pure internal returns(uint){
        
        if(a<=b){
            return a;
        }else{
            return b;
        }
    }


      // only the owner can cancel the Auction before the Auction has ended
        function cancelAuction() public beforeEnd onlyOwner{
            auctionState = state.cancelled;
        }



     // the main function called to place a bid
        function placeBid() public payable notOwner afterStart beforeEnd returns(bool){
            // to place a bid auction should be running
            require(auctionState == state.running);
            // minimum value allowed to be sent
            // require(msg.value > 0.0001 ether);
            
            uint currentBid = bids[msg.sender] + msg.value;
            
            // the currentBid should be greater than the highestBindingBid. 
            // Otherwise there's nothing to do.
            require(currentBid > highestBindingBid);
            
            // updating the mapping variable
            bids[msg.sender] = currentBid;
            
            if (currentBid <= bids[highestBidder]){ // highestBidder remains unchanged
                highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
            }else{ // highestBidder is another bidder
                 highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
                 highestBidder = payable(msg.sender);
            }
        return true;
        }



    function finalizeAuction() public {

        require(auctionState==state.cancelled||block.number>endBlock);
        require(msg.sender==owner||bids[msg.sender]>0);

        address payable recipient;

        uint value;

        if(auctionState==state.cancelled){
            recipient=payable(msg.sender);
            value=bids[msg.sender];
        }else{
            if(msg.sender==owner){
                recipient=owner;
                value=highestBindingBid;
            }else{
                if(msg.sender==highestBidder){
                    recipient=highestBidder;
                    value=bids[highestBidder]-highestBindingBid;
                }else{
                    recipient=payable(msg.sender);
                    value=bids[msg.sender];
                }
            }
        }

        bids[recipient] = 0;

        recipient.transfer(value);

    }

}