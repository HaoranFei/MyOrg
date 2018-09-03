//9/1/2018
//by Haoran Fei
//This is the first version of a solidity smart contract under development. It will be used for a DAPP that helps 
//manage a decentralized, automonous and democratic organization of small scale.
 
//Sources and Reference:
//Util code:
//https://stackoverflow.com/questions/43016011/getting-the-length-of-public-array-variable-getter
//https://ethereum.stackexchange.com/questions/8346/convert-address-to-string
//Tutorials and Examples:
//https://solidity.readthedocs.io/en/v0.4.24/solidity-by-example.html
//https://coursetro.com/posts/code/100/Solidity-Events-Tutorial---Using-Web3.js-to-Listen-for-Smart-Contract-Events



pragma solidity ^0.4.21;

contract MyOrg {

        // This declares a new complex type which will
    // be used for variables later.
    // It will represent a single voter.
    struct Member {
        uint influence;
        address Address; 
        bool isDelegating; 
        address delegate; 
        uint votingOn;
        bool vote; 
    }

    // This is a type for a single proposal.
    struct Proposal {
        bytes32 name;   // short name (up to 32 bytes)
        string description;
        
        //Class 0: add member proposal
        //Class 1: everything else
        uint class;
        address info;
        address initiator;

        bool archived; 
        uint voteFor;
        uint voteAgainst;
        bool passed; 
    }
    
    uint public startInfluence;
    uint public numMembers;
    uint public numProposals;
    uint public proposalCost;
    uint public votingCost;
    mapping (address => Member) getMember;
    mapping (address => uint) idOf;
    mapping (address => uint) public influenceOf;
    Proposal[] proposals;
    

    // This is the constructor whose code is
    // run only when the contract is created.
    constructor(uint startInf, uint pcost, uint vcost) public{
        startInfluence = startInf;
        numMembers = 1;
        numProposals = 0;
        proposalCost = pcost;
        votingCost = vcost; 
        getMember[msg.sender] = Member({
            influence: startInf,
            Address: msg.sender,
            isDelegating: false,
            delegate: 0,
            votingOn: 0,
            vote: false
        });
    }
    
    //String utility function found online
    function toString(address x) private pure returns (string) {
        bytes memory b = new bytes(20);
        for (uint i = 0; i < 20; i++)
            b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
        return string(b);
    }
    
    
    //Create a Proposal to addMember
    //All existing members need to vote on this proposal
    function addMember(address Address) public {
        proposals.push(Proposal({
            name: "Adding member on this address",
            description: toString(Address),
            class: 0,
            info: Address,
            initiator: msg.sender,
            archived: false,
            voteFor: 1,
            voteAgainst: 0,
            passed: false
        }));
        numProposals += 1; 
        getMember[msg.sender].influence -= proposalCost;
    }

    function handleProposal(Proposal p) private{
        if(p.class == 0){
            getMember[p.info] = Member({
            influence: startInfluence,
            Address: p.info,
            isDelegating: false,
            delegate: 0,
            votingOn: 0,
            vote: false
            });
        }
    }
    
    function voteOnProposal(uint id, bool agree) public payable {
        require(
            id >= 0,
            "Id has to be at least 0!"
        );
        require(
            id < numProposals,
            "Id cannot be larger than number of Proposals!"
        );
        require(
            proposals[id].archived == false,
            "You cannot vote on a proposal that is already closed!"
        );

        getMember[msg.sender].influence -= votingCost;

        if(agree){
            proposals[id].voteFor += 1;
        }
        else{
            proposals[id].voteAgainst += 1;
        }
        uint totalVotes;
        totalVotes = proposals[id].voteFor + proposals[id].voteAgainst;
        if (totalVotes >= numMembers){
            proposals[id].archived = true;
            if(proposals[id].voteFor > proposals[id].voteAgainst){
                proposals[id].passed = true;
                handleProposal(proposals[id]);

                getMember[proposals[id].initiator].influence += 2 * proposalCost;
            }
            else{
                proposals[id].passed = false;
            }
        }

    }