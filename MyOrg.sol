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
        int influence; 
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
        int voteFor;
        int voteAgainst;
        bool passed;
    }

    // This is a type for a single proposal.
    struct Proposal {
        bytes32 name;   // short name (up to 32 bytes)
        string description;
        
        //Class 0: add member proposal
        //Class 1: removing member proposal
        //Class 2: everything else

        uint class;
        int cost;
        address info;
        address initiator;
        //The person to execute the proposal for class 2 proposals
        //Defualt to 0 for class 0 and 1
        address executor; 


        bool archived; 
        int voteFor;
        int voteAgainst;
        bool passed; 

        ProposalVerifier verify;

    }



    int public startInfluence;
    int public numMembers;
    uint public numProposals;
    int public proposalCost;
    int public votingCost;
    uint80 constant None = uint80(0); 

    mapping (address => Member) getMember;
    
    mapping (address => uint) idOf;
    
    mapping (address => uint) public influenceOf;

    mapping (string => uint) idOfProposal;


    //Mapping implicitly initalize to all zeros
    //zero indicates that the said person has not voted
    //1-3 means 1-3 votes are casted 
    mapping (uint => mapping(address => int)) voteHistory;

    mapping (uint => mapping(address => bool)) hasVerified;


    Proposal[] proposals;
    

    // This is the constructor whose code is
    // run only when the contract is created.
    constructor(int startInf, int pcost, int vcost) public{
        startInfluence = startInf;
        numMembers = 1;
        numProposals = 0;
        proposalCost = pcost;
        votingCost = vcost; 
        getMember[msg.sender] = Member({
            exists: 1,
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

    function emptyVerifier() private pure returns (ProposalVerifier){
        ProposalVerifier memory PV = 
        ProposalVerifier({
            proof: "",

            archived: false,

            voteFor: 0,

            voteAgainst: 0,

            passed: false
        });
        return PV;
    }
    
    
    //Create a Proposal to addMember
    //All existing members need to vote on this proposal
    function addMember(address Address, string desc, int c) public {
        uint id = numProposals; 
        proposals.push(Proposal({
            name: "Adding member on this address",
            description: desc,
            class: 0,
            cost: c, 
            info: Address,
            initiator: msg.sender,
            executor: 0,
            archived: false,
            voteFor: 1,
            voteAgainst: 0,
            passed: false,
            verify: emptyVerifier()
        }));
        numProposals += 1; 
        getMember[msg.sender].influence -= c;
        idOfProposal[desc] = id; 
    }

    
    function removeMember(address Address, string desc, int c) public{
        uint id = numProposals;
        proposals.push(Proposal({
            name: "Remove member with this address",
            description: desc,
            class: 1, 
            cost: c,
            info: Address,
            initiator: msg.sender,
            executor: 0, 
            archived: false,
            voteFor: 1,
            voteAgainst: 0,
            passed: false,
            verify: emptyVerifier()
        }));
        numProposals += 1; 
        getMember[msg.sender].influence -= c;
        idOfProposal[desc] = id; 
    }

    function propose(bytes32 n, string desc, int c, address eaddress) public payable {
        uint id = numProposals;
        proposals.push(Proposal({

            name: n,
            description: desc,
            class: 2,
            cost: c,
            info: 0,
            initiator: msg.sender,
            executor: eaddress, 
            archived: false,
            voteFor: 1,
            voteAgainst: 0,
            passed: false,
            verify: emptyVerifier()
        }));
        numProposals += 1;

        getMember[msg.sender].influence -= c;

        idOfProposal[desc] = id; 

    }
    

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
        else if (p.class ==2){
            //Currently nothing
        }
    }


    //Utility functions to help award/penalize individuals

    function awardClass01(Proposal p, int ibonus) private{
        getMember[p.initiator].influence += ibonus;
    }

    function awardClass2(Proposal p, int ibonus, int ebonus) private{
        getMember[p.initiator].influence += ibonus;
        getMember[p.executor].influence += ebonus;
    }

    function penaltyClass2(Proposal p, int ipenal, int epenal) private{
        getMember[p.initiator].influence -= ipenal;
        getMember[p.executor].influence -= epenal;
    }
    
    //voteNum = number of votes casted 
    //vc = vote cost, compute externally
    function voteOnProposal(uint id, int voteNum, int vc, int ibonus) public payable {
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
            voteHistory[id][msg.sender] == 0,
            "You must not revote if you have already voted!"
        );

        require(
            voteNum >= -3,
            "You can cast no more than 3 against votes!"
        );

        require(
            voteNum <= 3,
            "You can cast no more than 3 for votes!"
        );

    
            
        getMember[msg.sender].influence -= vc;

        Proposal storage P = proposals[id];

        if(voteNum > 0){
            P.voteFor += voteNum;
        }
        else{
            P.voteAgainst -= voteNum;
        }

        voteHistory[id][msg.sender] = voteNum;


        int totalVotes;
        totalVotes = P.voteFor + P.voteAgainst;

        if (totalVotes >= numMembers && P.verify.archived){
            P.archived = true;
            if(P.voteFor > P.voteAgainst){
                P.passed = true;
                handleProposal(P);

                if(P.class != 2){
                    awardClass01(P, ibonus);
                }

            }
            else{
                P.passed = false;
            }
        }

    }

    //Helper for the app to upload proof onto the blockchain
    function uploadProof(Proposal P, string pf) public pure{
        P.verify.proof = pf;
    }

    //ibonus and ebonus calculated offline
    function proposal_verify(uint id, bool agree, int ibonus, int ebonus, int ipenal, int epenal) public{
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
        require(
            proposals[id].class == 2,
            "You can only verify class 2 proposals"
        );
        require(
            hasVerified[id][msg.sender] = false,
            "You have already voted for verification on this proposal!"
        );

        Proposal storage P = proposals[id];
        ProposalVerifier storage PV = proposals[id].verify;

        hasVerified[id][msg.sender] = true; 
        if (agree){
            PV.voteFor += 1;
        }
        else{
            PV.voteAgainst += 1;
        }

        if(PV.voteFor >= numMembers / 2){
            PV.passed = true;
            awardClass2(P, ibonus, ebonus);
        }
        else if(PV.voteAgainst >= numMembers / 2){
            PV.passed = false;
            penaltyClass2(P, ipenal, epenal);
        }

        PV.archived = true;

    }
}
