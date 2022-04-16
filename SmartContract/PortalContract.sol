// SPDX-License-Identifier: GPL-3.0
// This code is a prototype, so it is just for MVP product not for Real World Usage.
pragma solidity ^0.8;
// impoart required OpenZeppelin's contracts
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol";

// contract to create other smart contract (factory)
contract projectFactory{
    // create project directory
    project[] public projrectDirectory;
    // create project token directory
    ERC20[] public ERC20Directory;
    // mapping project name with the project token address
    mapping(string => ERC20) tokenApprove;
    // mapping project name with the project smart contract address
    mapping(string => project) projectApprove;

    
    // create smart contract for a new project
    function createProject(string memory _name, string memory _description, uint _goal, uint _minGoal, address _address) public {
        project newProject = new project(_name, _description, _goal,_minGoal, _address);
        ERC20 newCoin = new ERC20(_name,_name);
        ERC20Directory.push(newCoin);
        tokenApprove[_name] = newCoin;
        projectApprove[_name] = newProject;
        projrectDirectory.push(newProject);
    }
    
    // return arrays of address of all projects
    function getProjectDirectory() public view returns (project[] memory){
        return projrectDirectory;
    }

    // return arrays of address of all token projects
    function getCoinDirectory() public view returns (ERC20[] memory){
        return ERC20Directory;
    }
    
    // return project token address by inputing project name 
    function getCoinAddress(string memory _name) public view returns (ERC20){
        return tokenApprove[_name];
    }

    // return project address by inputing project name     
    function getProjectAddress(string memory _name) public view returns (project){
        return projectApprove[_name];
    }
}

// individual project smart contract
contract project {
    // Using SafeMath to deal with overflow/underflow issue
    using SafeMath for uint;
    // create a contract while assigning project information
    constructor(string memory _name, string memory _description,uint _goal, uint _minGoal, address _creator) public {
        name = _name;
        description = _description;
        projectOwner = _creator;
        goal = _goal;
        minGoal = _minGoal;
        remaining_goal = _goal;
    }
    //project name
    string name;
    //project description
    string description;
    address public projectOwner;
    uint public goal;
    uint public minGoal;
    uint public remaining_goal;
    // total current vote
    uint public totalVote;
    //mapping address with their contribution
    mapping(address => uint) public contribute_amount;
    //mapping address with their voting amount
    mapping(address => uint) public voting_amount;
    //mapping address to check whether they have already voted or not
    mapping(address => bool) public votingRights;
    // current money in the project
    uint public totalContributeAmount;
    //array to store address of participant
    address[] public address_all_participant;
    uint all_participant_count;
    // project is still open for crowdfunding
    bool isOpen = true;
    // project is already finish or not
    bool isEnd = false;
    //number of true vote
    uint vote_continue = 0;
    // number of false vote
    uint vote_not_continue = 0;

    // fallback function to receive eth from the main contract
    fallback() external payable{
    }

    // function to receive money into a smart contract
    function contribute(uint amount, address _address) public payable{
        // check value in the msg
        require(amount > 0, "Value must be higher than 0");
        // check whether the msg.value exceeds the remaining goal
        require(amount <= remaining_goal, "Value is higher than the remaining goal value");
        // one person can only have one chance to contribute
        require(contribute_amount[_address] == 0, "You already contributed");
        // check if it's still open
        require(isOpen == true, "The crowdfunding period is already finished");
        // using sender address to add contributed value in the contribute_amount mapping
        contribute_amount[_address] = contribute_amount[_address].add(amount);
        // add up the total contribution amount
        totalContributeAmount = totalContributeAmount.add(amount);
        // add new participant address
        address_all_participant.push(_address);
        // increase the number of participant
        all_participant_count++;
        // substract the value with the remaining goal
        remaining_goal = remaining_goal.sub(amount);
        // voting rights -> true(can vote)
        votingRights[_address] = true;
        // if reamining goal < 10 wei (buffer value) we will close this project automatically
        if (remaining_goal <= 10){
            isOpen = false;
        }
    }
    
    // e-voting system
    function vote(string memory _name, address _address, uint _voting_amount, bool continue_or_not) public {
        require(contribute_amount[_address] > 0, "You are not participant in this project");
        require(votingRights[_address] == true , "You already voted" );
        // vote yes part
        if (continue_or_not == true){
            vote_continue = vote_continue + _voting_amount;
        }
        // vote no part
        else{
           vote_not_continue = vote_not_continue + _voting_amount;
        }
        // add total vote
        totalVote = totalVote.add(_voting_amount);
        // using sender address to add voting value in the voting_amount mapping
        voting_amount[_address] = _voting_amount;
        // change the voting false -> false(already vote)
        votingRights[_address] = false;
    }
    
    // function for project initiators to claim their money back
    function redeem(uint _minGoal, address _address) payable public {
        // only project owner can claim
        require(projectOwner == _address, "You are not the owner of the project");
        require ((isOpen == false), "Goal is still unmet");
        // check if the majority vote yes
        require(isPass() == true, "Waitting for voting result");
        require(isEnd == false, "The crowdfunding is already finished");
        // loop through partcipants voting rights to reset it to true, so that everyone can vote again in the next round
        for (uint i=0; i<all_participant_count;i++){
            votingRights[address_all_participant[i]] = true;
        }
        // transfer eth back to the project initiator from the smart contract itself
        address temp = _address;
        address payable msg_sender = payable(temp);
        msg_sender.transfer(minGoal);
        // reset vote to 0
        resetVote();
        // if reamining goal < 10 wei (buffer value) we will close this project automatically
        if (totalContributeAmount <= 10){
            isEnd = true;
        }
        // or else we will continue and reset the value to prepare for the next voting period
        else{
        //keep track of the contribute amount by substract the amount of withdrawal money
        totalContributeAmount = totalContributeAmount.sub(minGoal);
        //set new min goal(the next fund that will be released, but subject to investors' judgement)
        setMinGoal(_minGoal);
        vote_continue = 0;
        vote_not_continue = 0;
        totalVote = 0;
        }
    }

    // function to withdraw money to a specific address and amount
    function withdraw_cancel(uint _amount, address _address) payable public {
        address temp = _address;
        address payable msg_sender = payable(temp);
        msg_sender.transfer(_amount);

    }
    
    // function to mark the project as finish whem the vote no > 50%
    function cancelProject(address _address) payable public{
        //require(projectOwner == _address, "You are not the owner of the project");
        require(vote_not_continue > goal/2, "No voting need to surpass half of the total amount");
        isEnd = true;
    }

    //function to mark the project as finished
    function markAsEnd() payable public{
        //require(projectOwner == _address, "You are not the owner of the project");
        if(balanceofProject() < 10){
            isEnd = true;
        }
    }

    // function to set min goal
    function setMinGoal(uint _minGoal) internal{
        minGoal = _minGoal;
    }
    
    //function to returns arrays of address of participants
    function getAllAddress() public view returns (address[] memory){
        return address_all_participant;
    }
    
    //function to check whether vote continue > 50%
    function isPass() internal returns(bool){
        if(vote_continue > goal/2){
            return true;
        }
        else {return false;}
    }

    //function get voting amount of a specific address as an input
    function getVotingAmount(address _address) public view returns (uint){
        return voting_amount[_address];
    }
    
    // function to return isOpen variable
    function getisOpen() view public returns(bool) {
        return(isOpen);
    }

    // function to return isEnd variable
    function getisEnded() view public returns(bool) {
        return isEnd;
    }

    // function to return the project balance
    function balanceofProject() view public returns(uint) {
        return address(this).balance;
    }
    
    // function to set total vote = 0 for internal usage
    function resetVote() internal {
        totalVote = 0;
    }

    //function get a contributed amount of a specific address as an input
    function getContributeAmount(address _address) public returns(uint){
        return contribute_amount[_address];
    }

    // function to return number of participants in the project
    function getAllparticount() public view returns(uint){
        return all_participant_count;
    }
    
    //function to return the project goal
    function getGoal() public view returns(uint){
        return goal;
    }
}

// This smart contract is a standard ERC-20 from Openzeppelin, so the there wil be no comment in this part
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;


    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }


    function name() public view virtual override returns (string memory) {
        return _name;
    }


    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual override returns (uint8) {
        return 18;
    }


    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }


    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }


    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) public virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        // require(msg.sender == 0x38bfCA429C719653c7BE66d58dd3bc30971A3C9D);

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }


    function _burn(address account, uint256 amount) public virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }


    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// This is our main contract for Portal platform they will connect with projectFactory contract, thus, connecting with project contract
contract Portal{
    // mapping to store each project money managing the vault
    mapping(string => uint) ProjectVault;
    // need to change contract of the project factory everytime when you deploy the new contract
    projectFactory factoryInterface =  projectFactory(0x78eAA42707853fE8922997C7bBEe67198971Ea33);
    // create project by passing the value to projectFactory
    function createProject(string memory _name, string memory _description, uint _goal, uint _minGoal) public {
        factoryInterface.createProject(_name, _description, _goal, _minGoal, msg.sender);
    }

    //function to get token address by inputting the project name
    function getCoinAddress(string memory _name) view public returns(ERC20) {
        return factoryInterface.getCoinAddress(_name);
    }

    // function for investors to invest in project
    function contribute(string memory _name) payable public {
        //create interface for both project and token
        project projectInterface = project(factoryInterface.getProjectAddress(_name));
        ERC20 erc_20_interface = ERC20(factoryInterface.getCoinAddress(_name));
        //contribute moeny to the prokect
        projectInterface.contribute(msg.value, msg.sender);
        //mint ERC-20 token for the investor according to amount that they're investing
        erc_20_interface._mint(msg.sender, msg.value);
        //update value in the vault
        ProjectVault[_name] += msg.value;
    }

    //function for investors to vote
    function vote(string memory _name, bool continue_or_not) public {
        //create interface for the project
        project projectInterface = project(factoryInterface.getProjectAddress(_name));
        require (projectInterface.getisEnded() == false, "Project is already ended");
        require (projectInterface.getisOpen() == false, "Project is still in a crowdfunding period");
        projectInterface.vote(_name, msg.sender, checkTokenBalance(_name, msg.sender),continue_or_not);
        //create interface for the project token
        ERC20 erc_20_interface = ERC20(factoryInterface.getCoinAddress(_name));
        // burn token so that investor can't vote with their token again (in case they transfer their token and vote again)
        erc_20_interface._burn(msg.sender,checkTokenBalance(_name, msg.sender));
    }

    //function to for project initiators to redeem their value
    function redeem(string memory _name, uint _minGoal) payable public {
        project projectInterface = project(factoryInterface.getProjectAddress(_name));
        projectInterface.redeem(_minGoal, msg.sender);
        ERC20 erc_20_interface = ERC20(factoryInterface.getCoinAddress(_name));
        // get all address to loop in the next line
        address[] memory temp = projectInterface.getAllAddress();
        // mint their voted token back to the investors who have voted
        for (uint i=0; i<projectInterface.getAllparticount();i++){
            erc_20_interface._mint(temp[i],projectInterface.getVotingAmount(temp[i]));
        }
        projectInterface.markAsEnd();
    }

    //function for project initiators to launch the project
    function Launch(string memory _name) public payable {
        // mainly transfer the eth from the main contract to the individual project contract
        project projectInterface = project(factoryInterface.getProjectAddress(_name));
        require(return_isOpen(_name) == false, "This project crowdfunding period is still ongoing");
        require (projectInterface.getisEnded() == false, "Project is already ended");
        require (ProjectVault[_name] != 0, "The project is already launched");
        address payable project_receiver = payable(factoryInterface.getProjectAddress(_name));
        project_receiver.transfer(ProjectVault[_name]);
        // set the vault value to 0
        ProjectVault[_name] = 0;
    }

    //return project wheter the crowdfunding period still open
    function return_isOpen(string memory _name) public view returns(bool){
        project projectInterface = project(factoryInterface.getProjectAddress(_name));
        return projectInterface.getisOpen();
    }

    //function to check the remaining value in vault for a specific project
    function checkVault(string memory _name) public view returns(uint){
        return ProjectVault[_name];
    }

    //function to check the project token balance from the name of the project and investor address
    function checkTokenBalance(string memory _name, address _address) public view returns(uint){
        project projectInterface = project(factoryInterface.getProjectAddress(_name));
        ERC20 erc_20_interface = ERC20(factoryInterface.getCoinAddress(_name));
        return erc_20_interface.balanceOf(_address);
    }

    //function for cusomter to redeem(burn) their project token, so project initiators can check the record and deliver a predestined reward
    function customer_redeem(string memory _name) public payable {
        project projectInterface = project(factoryInterface.getProjectAddress(_name));
        require (projectInterface.getisEnded() == true, "Project is still going");
        ERC20 erc_20_interface = ERC20(factoryInterface.getCoinAddress(_name));
        erc_20_interface._burn(msg.sender,erc_20_interface.balanceOf(msg.sender));
    }

    //function for investors to cancel their project and get their money back
    function cancel_project(string memory _name) public {
        project projectInterface = project(factoryInterface.getProjectAddress(_name));
        require (projectInterface.getisEnded() == false, "Project is already ended");
        ERC20 erc_20_interface = ERC20(factoryInterface.getCoinAddress(_name));
        //get all the participant address of that project
        address[] memory temp = projectInterface.getAllAddress();
        //set isEnded = true
        projectInterface.cancelProject(msg.sender);
        uint projectBalance = projectInterface.balanceofProject();
        // using loop to return the value based on the ownership percentage
        for (uint i=0; i<projectInterface.getAllparticount();i++){
            //return the value one by one according to their ownership percentage
            projectInterface.withdraw_cancel((projectInterface.getContributeAmount(temp[i])*projectBalance)/projectInterface.getGoal(), temp[i]);
        }
    }

    //function to get all the address by inputing the name of the project
    function getAllAddressProject(string memory _name) public view returns (address[] memory) {
        project projectInterface = project(factoryInterface.getProjectAddress(_name));
        return projectInterface.getAllAddress();
    }

    //function to check the project balance
    function remainingProjectValue(string memory _name) public view returns (uint) {
        project projectInterface = project(factoryInterface.getProjectAddress(_name));
        return projectInterface.balanceofProject();
    }
}
