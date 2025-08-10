// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title SamsyCapitalToken
 * @dev Enhanced ERC20 token with security features and proper access control
 */
contract SamsyCapitalToken is ERC20, Ownable(msg.sender), Pausable, ReentrancyGuard {
    
    // Constants
    uint256 public constant TOTAL_SUPPLY = 99_000_000_000 * 10**18; // 99 billion tokens total (99 crore)
    
    // State variables
    mapping(address => bool) public isWhitelisted;
    bool public transferLocked = true;
    
    // Events
    event WhitelistUpdated(address indexed account, bool status);
    event TransfersUnlocked();
    event TokensBurned(address indexed account, uint256 amount);
    
    // Errors
    error TransfersLocked();
    error ZeroAddress();
    error ZeroAmount();
    error NotWhitelisted();
    
    modifier onlyWhenTransfersAllowed(address from, address to) {
        if (transferLocked && !isWhitelisted[from] && !isWhitelisted[to]) {
            revert TransfersLocked();
        }
        _;
    }
    
    modifier validAddress(address addr) {
        if (addr == address(0)) {
            revert ZeroAddress();
        }
        _;
    }
    
    modifier validAmount(uint256 amount) {
        if (amount == 0) {
            revert ZeroAmount();
        }
        _;
    }
    
    constructor() ERC20("Samsy Capital", "SM9") {
        _mint(msg.sender, TOTAL_SUPPLY);
        
        // Whitelist the owner initially
        isWhitelisted[msg.sender] = true;
        emit WhitelistUpdated(msg.sender, true);
    }
    
    /**
     * @dev Override transfer to include transfer lock mechanism
     */
    function transfer(address to, uint256 amount) 
        public 
        override 
        whenNotPaused 
        nonReentrant 
        onlyWhenTransfersAllowed(msg.sender, to)
        validAddress(to)
        validAmount(amount)
        returns (bool) 
    {
        return super.transfer(to, amount);
    }
    
    /**
     * @dev Override transferFrom to include transfer lock mechanism
     */
    function transferFrom(address from, address to, uint256 amount) 
        public 
        override 
        whenNotPaused 
        nonReentrant 
        onlyWhenTransfersAllowed(from, to)
        validAddress(to)
        validAmount(amount)
        returns (bool) 
    {
        return super.transferFrom(from, to, amount);
    }
    
    /**
     * @dev Unlock transfers permanently - can only be called once
     */
    function unlockTransfers() external onlyOwner {
        require(transferLocked, "Transfers already unlocked");
        transferLocked = false;
        emit TransfersUnlocked();
    }
    
    /**
     * @dev Update whitelist status for an address
     */
    function whitelistAddress(address addr, bool status) 
        external 
        onlyOwner 
        validAddress(addr)
    {
        isWhitelisted[addr] = status;
        emit WhitelistUpdated(addr, status);
    }
    
    /**
     * @dev Batch whitelist multiple addresses
     */
    function batchWhitelist(address[] calldata addresses, bool status) 
        external 
        onlyOwner 
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] != address(0)) {
                isWhitelisted[addresses[i]] = status;
                emit WhitelistUpdated(addresses[i], status);
            }
        }
    }
    
    /**
     * @dev Burn tokens from caller's balance
     */
    function burn(uint256 amount) 
        external 
        validAmount(amount)
    {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }
    
    /**
     * @dev Burn tokens from specified address (requires allowance)
     */
    function burnFrom(address account, uint256 amount) 
        external 
        validAddress(account)
        validAmount(amount)
    {
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
        emit TokensBurned(account, amount);
    }
    
    /**
     * @dev Emergency pause function
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause function
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Check if an address can transfer tokens
     */
    function canTransfer(address from, address to) external view returns (bool) {
        return !transferLocked || isWhitelisted[from] || isWhitelisted[to];
    }
    
    /**
     * @dev Get contract information
     */
    function getContractInfo() external view returns (
        uint256 totalTokenSupply,
        uint256 currentSupply,
        bool transfersLocked,
        bool contractPaused
    ) {
        return (
            TOTAL_SUPPLY,
            totalSupply(),
            transferLocked,
            paused()
        );
    }
    
}
