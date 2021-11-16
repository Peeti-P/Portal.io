pragma solidity ^0.7;
using SafeMath for uint256
// Contract for creating smart contract
contract projectFactory{
    // create project directory file
    address[] public projrectDirectory;
    
    // create new project smart contract
    function createProject(uint goal, uint minGoal) public {
        address newProject = new project(goal,minGoal,msg.sender);
        projrectDirectory.push(newProject);
    }
    
    // return arrays of address of all projects
    function getProjectDirectory() public view returns (address[]){
        return projrectDirectory;
    }
    
}

contract project{
    
    // create a contract while assigning minimum capital require and owner of the project
    constructor(uint goal, uint minGoal, address creator) public {
        projectOwner = creator;
        minimumContribution = minimum;
    }
    
    // only projectOwner can access the money in the vault
    modifier authorization(){
        require(msg.sender == projectOwner);
        _;
    }
    
    //Log for record the tx of projectOwner with moeny in the vault
    Request[] public requests;
    // projectOwner address variable
    address public projectOwner;
    // goal amount variable
    uint public goal
    // minimum goal, or inital amount that will be distributed to projectOwner
    uint public minGoal;
    // check who participate in the project
    // e.g. address => 1 eth
    mapping(address => uint) public contribute_amount;
    // if the totalContributeAmount > supply/2 then we can conclude the approval
    uint public totalContributeAmount;
    
    // fall back function
    function() public payable{
        require(msg.value <= goal, "Value is higher than maximum value")
        approver_amount[msg.sender] += msg.value;
    }
    
    // function to receive money
    function contribute() public payable{
        require(msg.value <= goal, "Value is higher than maximum value")
        approver_amount[msg.sender] += msg.value;
    }
    
    // voting system
    function vote() public {
        require(contribute_amount[msg.sender] > 0, "You are not participant in this project")

    }
    
    
    
}
