// SPDX-License-Identifier: GPL-3.0
// This code is a prototype, so it is just for MVP product not for Real World Usage.
pragma solidity ^0.8;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol";

//----------------------------------------------------------------------------------
// ████████╗░█████╗░░█████╗░██╗░░██╗██╗░░░██╗░█████╗░███╗░░██╗
// ╚══██╔══╝██╔══██╗██╔══██╗██║░░██║╚██╗░██╔╝██╔══██╗████╗░██║
// ░░░██║░░░███████║██║░░╚═╝███████║░╚████╔╝░██║░░██║██╔██╗██║
// ░░░██║░░░██╔══██║██║░░██╗██╔══██║░░╚██╔╝░░██║░░██║██║╚████║
// ░░░██║░░░██║░░██║╚█████╔╝██║░░██║░░░██║░░░╚█████╔╝██║░╚███║
// ░░░╚═╝░░░╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░░╚════╝░╚═╝░░╚══╝
//----------------------------------------------------------------------------------

contract projectFactory{
    // create project directory file
    project[] public projrectDirectory;
    ERC20[] public ERC20Directory;
    mapping(string => ERC20) tokenApprove;
    mapping(string => project) projectApprove;

    
    // create new project smart contract
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
    
    function getCoinDirectory() public view returns (ERC20[] memory){
        return ERC20Directory;
    }
    
    function getCoinAddress(string memory _name) public view returns (ERC20){
        return tokenApprove[_name];
    }
        
    function getProjectAddress(string memory _name) public view returns (project){
        return projectApprove[_name];
    }
    
    function getProjectAddressID(string memory _name) public view returns (address){
        return address(projectApprove[_name]);
    }
}

contract project {
    using SafeMath for uint;
    // create a contract while assigning minimum capital require and owner of the project
    constructor(string memory _name, string memory _description,uint _goal, uint _minGoal, address _creator) public {
        name = _name;
        description = _description;
        projectOwner = _creator;
        goal = _goal;
        minGoal = _minGoal;
        remaining_goal = _goal;
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
    mapping(address => uint) public voting_amount;
    mapping(address => bool) public votingRights;
    uint public totalContributeAmount;
    address[] public address_all_participant;
    uint all_participant_count;
    bool isOpen = true;
    bool isEnd = false;
    event addedCommitment(address _addr, uint256 _commitment);
    event addedVote(address _addr, uint256 _vote);
    uint vote_continue = 0;
    uint vote_not_continue = 0;

    fallback() external payable{
        // require(msg.value <= goal, "Value is higher than maximum value");
        // contribute_amount[msg.sender] = contribute_amount[msg.sender].add(msg.value);
        // totalContributeAmount = totalContributeAmount.add(msg.value);
        // remaining_goal = remaining_goal.sub(msg.value);
    }

    // function to receive money
    function contribute(uint amount, address _address) public payable{
        require(amount > 0, "Value must be higher than 0");
        require(amount <= remaining_goal, "Value is higher than the remaining goal value");
        require(contribute_amount[_address] == 0, "You already contributed");
        require(isOpen == true, "The crowdfunding period is already finished");
        contribute_amount[_address] = contribute_amount[_address].add(amount);
        totalContributeAmount = totalContributeAmount.add(amount);
        address_all_participant.push(_address);
        all_participant_count++;
        remaining_goal = remaining_goal.sub(amount);
        votingRights[_address] = true;
        if (remaining_goal <= 10){
            isOpen = false;
        }
        emit addedCommitment(msg.sender, amount);
    }
    
    // voting system
    function vote(string memory _name, address _address, uint _voting_amount, bool continue_or_not) public {
        require(contribute_amount[_address] > 0, "You are not participant in this project");
        require(votingRights[_address] == true , "You already voted" );
        if (continue_or_not == true){
            vote_continue = vote_continue + _voting_amount;
        }
        else{
           vote_not_continue = vote_not_continue + _voting_amount;
        }
        totalVote = totalVote.add(_voting_amount);
        voting_amount[_address] = _voting_amount;
        votingRights[_address] = false;
        emit addedVote(_address,_voting_amount);
    }
    
    function redeem(uint _minGoal, address _address) payable public {
        require(projectOwner == _address, "You are not the owner of the project");
        require ((isOpen == false), "Goal is still unmet");
        require(isPass() == true, "Waitting for voting result");
        require(isEnd == false, "The crowdfunding is already finished");
        // require(_minGoal <= totalContributeAmount, "Mininum Goal Exceed total amount");
        // project projectInterface = project(factoryInterface.getProjectAddress(name));
        // ERC20 erc_20_interface = ERC20(factoryInterface.getCoinAddress(name));
        for (uint i=0; i<all_participant_count;i++){
            votingRights[address_all_participant[i]] = true;
        }
        address temp = _address;
        address payable msg_sender = payable(temp);
        msg_sender.transfer(minGoal);
        resetVote();
        if (totalContributeAmount <= 10){
            isEnd = true;
        }
        else{
        totalContributeAmount = totalContributeAmount.sub(minGoal);
        setMinGoal(_minGoal);
        vote_continue = 0;
        vote_not_continue = 0;
        totalVote = 0;
        }
    }

    function withdraw_cancel(uint _amount, address _address) payable public {
        address temp = _address;
        address payable msg_sender = payable(temp);
        msg_sender.transfer(_amount);

    }

    function cancelProject(address _address) payable public{
        //require(projectOwner == _address, "You are not the owner of the project");
        require(vote_not_continue > goal/2, "No voting need to surpass half of the total amount");
        isEnd = true;
    }

    
    function setMinGoal(uint _minGoal) internal{
        minGoal = _minGoal;
    }
    
    function getAllAddress() public view returns (address[] memory){
        return address_all_participant;
    }
    
    
    function isPass() internal returns(bool){
        if(vote_continue > goal/2){
            return true;
        }
        else {return false;}
    }

    function getVotingAmount(address _address) public view returns (uint){
        return voting_amount[_address];
    }
    
    
    function getisOpen() view public returns(bool) {
        return(isOpen);
    }

    function getisEnded() view public returns(bool) {
        return isEnd;
    }

    function balanceofProject() view public returns(uint) {
        return address(this).balance;
    }
    
    function resetVote() internal {
        totalVote = 0;
    }

    function getContributeAmount(address _address) public returns(uint){
        return contribute_amount[_address];
    }

    function getAllparticount() public view returns(uint){
        return all_participant_count;
    }
    
    function getGoal() public view returns(uint){
        return goal;
    }
}

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


contract Portal{
    // need to change contract of the project factory
    mapping(string => uint) ProjectVault;
    projectFactory factoryInterface =  projectFactory(0x2DFdBBa4D4270c2dCbD1D304c2290887AF74A576);

    function createProject(string memory _name, string memory _description, uint _goal, uint _minGoal) public {
        factoryInterface.createProject(_name, _description, _goal, _minGoal, msg.sender);
    }

    function getCoinAddress(string memory _name) view public returns(ERC20) {
        return factoryInterface.getCoinAddress(_name);
    }

    function contribute(string memory _name) payable public {
        project projectInterface = project(factoryInterface.getProjectAddress(_name));
        ERC20 erc_20_interface = ERC20(factoryInterface.getCoinAddress(_name));
        projectInterface.contribute(msg.value, msg.sender);
        erc_20_interface._mint(msg.sender, msg.value);
        ProjectVault[_name] += msg.value;
    }

    function vote(string memory _name, bool continue_or_not) public {
        project projectInterface = project(factoryInterface.getProjectAddress(_name));
        projectInterface.vote(_name, msg.sender, checkTokenBalance(_name, msg.sender),continue_or_not);
        ERC20 erc_20_interface = ERC20(factoryInterface.getCoinAddress(_name));
        erc_20_interface._burn(msg.sender,checkTokenBalance(_name, msg.sender));
    }

    function redeem(string memory _name, uint _minGoal) payable public {
        project projectInterface = project(factoryInterface.getProjectAddress(_name));
        //require (projectInterface.getisEnded() == false, "Project is already ended");
        projectInterface.redeem(_minGoal, msg.sender);
        ERC20 erc_20_interface = ERC20(factoryInterface.getCoinAddress(_name));
        address[] memory temp = projectInterface.getAllAddress();
        for (uint i=0; i<projectInterface.getAllparticount();i++){
            erc_20_interface._mint(temp[i],projectInterface.getVotingAmount(temp[i]));
        }
    }

    function Launch(string memory _name) public payable {
        project projectInterface = project(factoryInterface.getProjectAddress(_name));
        require(return_isOpen(_name) == false, "This project is still ongoing");
        require (projectInterface.getisEnded() == false, "Project is already ended");
        require (ProjectVault[_name] != 0, "The project is already launched");
        address payable project_receiver = payable(factoryInterface.getProjectAddress(_name));
        project_receiver.transfer(ProjectVault[_name]);
        ProjectVault[_name] = 0;
    }

    function return_isOpen(string memory _name) public view returns(bool){
        project projectInterface = project(factoryInterface.getProjectAddress(_name));
        return projectInterface.getisOpen();
    }

    function return_name(string memory _name) public view returns(address) {
        return factoryInterface.getProjectAddressID(_name);
    }

    function checkVault(string memory _name) public view returns(uint){
        return ProjectVault[_name];
    }

    function checkTokenBalance(string memory _name, address _address) public view returns(uint){
        project projectInterface = project(factoryInterface.getProjectAddress(_name));
        ERC20 erc_20_interface = ERC20(factoryInterface.getCoinAddress(_name));
        return erc_20_interface.balanceOf(_address);
    }

    function customer_redeem(string memory _name) public payable {
        project projectInterface = project(factoryInterface.getProjectAddress(_name));
        require (projectInterface.getisEnded() == true, "Project is still ongoing");
        ERC20 erc_20_interface = ERC20(factoryInterface.getCoinAddress(_name));
        erc_20_interface._burn(msg.sender,projectInterface.getContributeAmount(msg.sender));
    }

    function cancel_project(string memory _name) public {
        project projectInterface = project(factoryInterface.getProjectAddress(_name));
        require (projectInterface.getisEnded() == false, "Project is already ended");
        ERC20 erc_20_interface = ERC20(factoryInterface.getCoinAddress(_name));
        address[] memory temp = projectInterface.getAllAddress();
        projectInterface.cancelProject(msg.sender);
        //uint totalsupply = erc_20_interface.totalSupply();
        uint projectBalance = projectInterface.balanceofProject();
        for (uint i=0; i<projectInterface.getAllparticount();i++){
            projectInterface.withdraw_cancel((projectInterface.getContributeAmount(temp[i])*projectBalance)/projectInterface.getGoal(), temp[i]);
        }
    }

    function getAllAddressProject(string memory _name) public view returns (address[] memory) {
        project projectInterface = project(factoryInterface.getProjectAddress(_name));
        return projectInterface.getAllAddress();
    }

    function remainingProjectValue(string memory _name) public view returns (uint) {
        project projectInterface = project(factoryInterface.getProjectAddress(_name));
        return projectInterface.balanceofProject();
    }
}
