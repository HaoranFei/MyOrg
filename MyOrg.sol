//9/1/2018
//by Yuchi Zhang, Haoran Fei
//This is the first version of a solidity smart contract under development. It will be used for a DAPP that helps 
//manage a decentralized, automonous and democratic organization of small scale.
 
//Sources and Reference:
//Util code:
//https://stackoverflow.com/questions/43016011/getting-the-length-of-public-array-variable-getter
//https://ethereum.stackexchange.com/questions/8346/convert-address-to-string
//Tutorials and Examples:
//https://solidity.readthedocs.io/en/v0.4.24/solidity-by-example.html
//https://coursetro.com/posts/code/100/Solidity-Events-Tutorial---Using-Web3.js-to-Listen-for-Smart-Contract-Events


//version number
pragma solidity ^0.4.21;  



contract MyOrg {

    // This declares a new complex type which will
    // be used for variables later.
    // It will represent a single voter.
    struct Member {
        uint exists; 
        
        //Token for memeber's right to participate in the organization.
        uint influence; 
        // Member's ethereum address
        address Address;  
        bool isDelegating; 
        address delegate; 
        //ID of the proposal that is under voting.
        uint votingOn;
        bool vote; 
    }

    struct ProposalVerifier{
        string proof; //Might need to encode image outside of smart contract
        bool archived;
        uint voteFor;
        uint voteAgainst;
        bool passed;
        mapping (address => bool) public hasVoted;
    }

    // This is a type for a single proposal.
    struct Proposal {
        bytes32 name;   // short name (up to 32 bytes)
        string description;
        
        //Class 0: add member proposal
        //Class 1: removing member proposal
        //Class 2: everything else

        uint class;
        uint proposeCost;
        address info;
        address initiator;

        //Mapping implicitly initalize to all zeros
        //zero indicates that the said person has not voted
        //1-3 means 1-3 votes are casted 
        mapping (address => uint) voteHistory;

        bool archived; 
        uint voteFor;
        uint voteAgainst;
        bool passed; 

        ProposalVerifier verify;

    }



    uint public startInfluence;
    uint public numMembers;
    uint public numProposals;
    uint public proposalCost;
    uint public votingCost;
    uint80 constant None = uint80(0); 

    mapping (address => Member) getMember;
    
    mapping (address => uint) idOf;
    
    mapping (address => uint) public influenceOf;

    mapping (string => uint) idOfProposal;

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
    function addMember(address Address, string desc) public {
        uint id = numProposals; 
        proposals.push(Proposal({
            name: "Adding member on this address",
            description: desc,
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
        idOfProposal[desc] = id; 
    }

    
    function removeMember(address Address, string desc) public{
        uint id = numProposals;
        proposals.push(Proposal({
            name: "Remove member with this address",
            description: desc,
            class: 1, 
            info: Address,
            initiator: msg.sender,
            archived: false,
            voteFor: 1,
            voteAgainst: 0,
            passed: false
        }));
        numProposals += 1; 
        getMember[msg.sender].influence -= proposalCost;
        idOfProposal[desc] = id; 
    }

    //function propose()
    

    function handleProposal(Proposal p) private{
        if(p.class == 0){
            getMember[p.info] = Member({
            exists: 1, 
            influence: startInfluence,
            Address: p.info,
            isDelegating: false,
            delegate: 0,
            votingOn: 0,
            vote: false
            });
            numMembers += 1;
        }
        else if (p.class == 1){
            getMember[p.info].exists = 0; 
            numMembers -= 1; 
        }
    }
    
    //voteNum = number of votes casted 
    //vc = vote cost, compute externally
    function voteOnProposal(uint id, int voteNum, uint vc) public payable {
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
        require(
            voteNum >= -3,
            "You can cast no more than 3 against votes!"
        );
        require
            voteNum <= 3,
            "You can cast no more than 3 for votes!"
        );
    
            
        getMember[msg.sender].influence -= vc;

        P = proposals[id];

        if(voteNum > 0){
            P.voteFor += voteNum;
        }
        else{
            P.voteAgainst -= voteNum;
        }

        P.voteHistory[msg.sender] = voteNum;


        uint totalVotes;
        totalVotes = proposals[id].voteFor + proposals[id].voteAgainst;

        if (totalVotes >= numMembers && proposals[id].verify.archived){
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
}

    function proposal_verify(uint id, bool agree){
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
            "You cannot supervise a proposal that is already closed!"
        );
        ProposalVerifier PV = proposals[id].verify;
        PV.hasVoted[msg.sender] = true; 
        if (agree){
            PV.voteFor += 1;
        }else{
            PV.voteAgainst += 1;
        }
        if(PV.voteFor >= numMembers / 2){
            PV.passed = true
            PV.archived = true
        }else if(PV.voteAgainst >= numMembers / 2){
            PV.passed = false
            PV.archived = true
        }

    }
}
