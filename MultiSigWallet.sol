// SPDX-License-Identifier: MIT
// © 2025 Your Name or Organization

pragma solidity ^0.8.0;


contract MultiSigWallet {
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public requiredApprovals;
    bool public initialized;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint approvalCount;
    }

    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public approvals;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    function initialize(address[] calldata _owners, uint _requiredApprovals) external {
        require(!initialized, "Already initialized");
        require(_owners.length > 0, "No owners");
        require(
            _requiredApprovals > 0 && _requiredApprovals <= _owners.length,
            "Invalid required approvals"
        );

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Zero address");
            require(!isOwner[owner], "Duplicate owner");
            isOwner[owner] = true;
            owners.push(owner);
        }

        requiredApprovals = _requiredApprovals;
        initialized = true;
    }

    function submitTransaction(address to, uint value, bytes calldata data) external onlyOwner {
        transactions.push(Transaction({
            to: to,
            value: value,
            data: data,
            executed: false,
            approvalCount: 0
        }));
    }

    function approveTransaction(uint txIndex) external onlyOwner {
        Transaction storage txn = transactions[txIndex];
        require(!txn.executed, "Already executed");
        require(!approvals[txIndex][msg.sender], "Already approved");

        approvals[txIndex][msg.sender] = true;
        txn.approvalCount++;
    }

    function revokeApproval(uint txIndex) external onlyOwner {
        Transaction storage txn = transactions[txIndex];
        require(!txn.executed, "Already executed");
        require(approvals[txIndex][msg.sender], "Not yet approved");

        approvals[txIndex][msg.sender] = false;
        txn.approvalCount--;
    }

    function executeTransaction(uint txIndex) external onlyOwner {
        Transaction storage txn = transactions[txIndex];
        require(!txn.executed, "Already executed");
        require(txn.approvalCount >= requiredApprovals, "Not enough approvals");

        txn.executed = true;
        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        require(success, "Execution failed");
    }

    receive() external payable {}
}
