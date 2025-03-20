// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract mutlisignatureWallet {

    address[] public owners ;
    mapping(address => bool) public isOwner;
    uint public numberOfConfirmationsRequired;

    event Deposit ( address indexed sender , uint amount , uint balance);

    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );

    event ConfirmTransaction (address indexed owner , uint indexed txIndex);

    event RevokeTransaction (address indexed owner , uint indexed txIndex);

    event ExecuteTransaction (address indexed owner , uint indexed txIndex);

    struct Transaction {
        address to;
        uint value;
        bytes data ;
        bool executed ;
        uint numConfirmations;
    }

    mapping (uint => mapping(address => bool))  public isConfirmed;

    Transaction[] public transactions;

    modifier onlyOwner{
        require(isOwner[msg.sender],"you are not the owner");
        _;
    } 

    modifier transactionExists(uint txIndex){
        require(transactions.length > txIndex , "no such transaction is listed" );
        _;
    }

    modifier transactionNotExecuted(uint txIndex){
        require(!transactions[txIndex].executed, "Transaction already executed");
        _;
    }

    modifier transactionNotConfirmed(uint txIndex){
        require(!isConfirmed[txIndex][msg.sender],"transaction already confirmed");
        _;
    }

    constructor (address[] memory _owners , uint _numberOfConfirmationsRequired) {
        require(_owners.length > 0 ,"at least one owner is required ");
        require(_numberOfConfirmationsRequired > 0 && _numberOfConfirmationsRequired <=_owners.length,
        "invalid number of required confirmations in constructor");

        for (uint i; i<_owners.length; i++){
            address owner = _owners[i];
            require(owner != address(0),"invalid address");
            require(!isOwner[owner],"owner already exists");
            isOwner[owner] = true;
            owners.push(owner);
        }
        numberOfConfirmationsRequired=_numberOfConfirmationsRequired;
    }

    function confirmTransaction(uint txIndex) public
    onlyOwner
    transactionExists(txIndex)
    transactionNotExecuted(txIndex)
    transactionNotConfirmed(txIndex) {
        Transaction storage transaction = transactions[txIndex];
        transaction.numConfirmations+=1;
        isConfirmed[txIndex][msg.sender] = true;

        emit ConfirmTransaction(address(this), txIndex);
    }

    function submitTransaction( 
        address _to ,
        uint _value ,
        bytes memory _data 
    ) public onlyOwner{
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to:_to,
                value:_value,
                data:_data,
                executed:false,
                numConfirmations:0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function depositETH() public payable {

        (bool success, ) = address(this).call{value:msg.value}("");
        require(success,"failed to send ethers");
        emit Deposit(address(this), msg.value , address(this).balance);
    }

    receive() external payable { }

       function executeTransaction(uint256 _txIndex)
        public
        onlyOwner
        transactionExists(_txIndex)
        transactionNotExecuted(_txIndex)
    {
        
        Transaction storage transaction = transactions[_txIndex];
        require(
            transaction.numConfirmations >= numberOfConfirmationsRequired,
            " Cant exeute tx not enough confirmations"
        );
        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");
        
        emit ExecuteTransaction(msg.sender, _txIndex);
    }
    function revokeConfirmation(uint _txIndex)
    public
    onlyOwner
    transactionExists(_txIndex)
    transactionNotConfirmed(_txIndex)
    {
        Transaction storage transaction =transactions[_txIndex];
        require (isConfirmed[_txIndex][msg.sender],"tx is not confirmed");
        transaction.numConfirmations-=1;
        isConfirmed[_txIndex][msg.sender]=false;

        emit RevokeTransaction(msg.sender,_txIndex);

    }

    function getOwners() public view returns(address[] memory){
        return owners;
    }

    function getTransactionCount() public view returns(uint){
        return transactions.length;
    }

    function getTransaction(uint txIndex) public view returns(
        address to ,
        uint value,
        bytes  memory data ,
        bool executed,
        uint numConfirmations    
    ) {
        Transaction storage transaction = transactions[txIndex];
        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );

    }


    // ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2"]


 
}