// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

// Contract for creating smart contract
contract projectFactory{
    // create project directory file
    project[] public projrectDirectory;
    
    // create new project smart contract
    function createProject(string memory _name, string memory _description, uint _goal, uint _minGoal) public {
        project newProject = new project(_name, _description, _goal,_minGoal,msg.sender);
        projrectDirectory.push(newProject);
    }
    
    // return arrays of address of all projects
    function getProjectDirectory() public view returns (project[] memory){
        return projrectDirectory;
    }
    
}

contract project{
    using SafeMath for uint;
    // create a contract while assigning minimum capital require and owner of the project
    constructor(string memory _name, string memory _description,uint _goal, uint _minGoal, address _creator) public {
        name = _name;
        description = _description;
        projectOwner = _creator;
        goal = _goal;
        minGoal = _minGoal;
    }
    
    // only projectOwner can access the money in the vault
    modifier authorization(){
        require(msg.sender == projectOwner);
        _;
    }
    
    //Log for record the tx of projectOwner with moeny in the vault
    //Request[] public requests;
    // projectOwner address variable
    string name;
    string description;
    address public projectOwner;
    uint public goal;
    uint public minGoal;
    
    uint public remaining_goal;
    uint public totalVote;
    mapping(address => uint) public contribute_amount;
    mapping(address => bool) public votingRights;
    uint public totalContributeAmount;
    
    address[] public address_all_participant;
    uint all_participant_count;
    
    bool isOpen;
    // minimum goal, or inital amount that will be distributed to projectOwner
    // check who participate in the project
    // e.g. address => 1 eth

    // address of participant

    
    
    // if the totalContributeAmount > supply/2 then we can conclude the approval
    
    
    // fall back function
    fallback() external payable{
        require(msg.value <= goal, "Value is higher than maximum value");
        contribute_amount[msg.sender] = contribute_amount[msg.sender].add(msg.value);
        totalContributeAmount = totalContributeAmount.add(msg.value);
    }
    
    // function to receive money
    function contribute() public payable{
        require(msg.value <= remaining_goal, "Value is higher than maximum value");
        contribute_amount[msg.sender] = contribute_amount[msg.sender].add(msg.value);
        totalContributeAmount = totalContributeAmount.add(msg.value);
        address_all_participant.push(msg.sender);
        all_participant_count++;
    }
    
    // voting system
    function vote() public {
        require(contribute_amount[msg.sender] > 0, "You are not participant in this project");
        require(votingRights[msg.sender] == true , "You already voted" );
        totalVote = totalVote.add(contribute_amount[msg.sender]);
        votingRights[msg.sender] == false;
    }
    
    function redeem() public {
        require(projectOwner == msg.sender, "You are not the owner of the project");
        if (totalContributeAmount == goal){
            isOpen = false;
            for (uint i=0; i<all_participant_count;i++){
                contribute_amount[address_all_participant[i]] = (contribute_amount[address_all_participant[i]].mul(minGoal)).div(totalContributeAmount);
                votingRights[address_all_participant[i]] = true;
            }
            totalContributeAmount = totalContributeAmount.sub(minGoal);
        }
                    
    }
    
    function getisOpen() view public returns(bool) {
        return(isOpen);
    }
    
}
