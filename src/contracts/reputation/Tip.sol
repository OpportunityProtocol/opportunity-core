pragma solidity ^0.8.4;
	
	import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
	
	contract MyToken is ERC20 {
        mapping(address => uint256) public addressToTipCount;
	    constructor() ERC20("Tip", "TIP"){
	        _mint(msg.sender, 1000000000000000000000000);
	    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        addressToTipCount[recipient] += amount;
        addressToTipCount[_msgSender()] -= amount;
        return true;
    }
	}	