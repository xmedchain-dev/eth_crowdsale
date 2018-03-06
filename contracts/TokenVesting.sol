pragma solidity ^0.4.18;

import "./Allocatable.sol";
import './ERC20.sol';
import './SafeMathLib.sol';


/**
 * Contract to enforce Token Vesting
 */
contract TokenVesting is Allocatable, SafeMathLib {

    address public TokenAddress;

    /** keep track of total tokens yet to be released, 
     * this should be less than or equal to tokens held by this contract. 
     */
    uint256 public totalUnreleasedTokens;


    struct VestingSchedule {
        uint256 startAt;
        uint256 principleLockAmount;
        uint256 principleLockPeriod;
        uint256 bonusLockAmount;
        uint256 bonusLockPeriod;
        uint256 amountReleased;
        bool isPrincipleReleased;
        bool isBonusReleased;
    }

    mapping (address => VestingSchedule) public vestingMap;

    event VestedTokensReleased(address _adr, uint256 _amount);


    function TokenVesting(address _TokenAddress) public {
        TokenAddress = _TokenAddress;
    }



    /** Function to set/update vesting schedule. PS - Amount cannot be changed once set */
    function setVesting(address _adr, uint256 _principleLockAmount, uint256 _principleLockPeriod, uint256 _bonusLockAmount, uint256 _bonuslockPeriod) public onlyAllocateAgent {

        VestingSchedule storage vestingSchedule = vestingMap[_adr];

        // data validation
        require(safeAdd(_principleLockAmount, _bonusLockAmount) > 0);

        //startAt is set current time as start time.

        vestingSchedule.startAt = block.timestamp;
        vestingSchedule.bonusLockPeriod = safeAdd(block.timestamp,_bonuslockPeriod);
        vestingSchedule.principleLockPeriod = safeAdd(block.timestamp,_principleLockPeriod);

        // check if enough tokens are held by this contract
        ERC20 token = ERC20(TokenAddress);
        uint256 _totalAmount = safeAdd(_principleLockAmount, _bonusLockAmount);
        require(token.balanceOf(this) >= safeAdd(totalUnreleasedTokens, _totalAmount));
        vestingSchedule.principleLockAmount = _principleLockAmount;
        vestingSchedule.bonusLockAmount = _bonusLockAmount;
        vestingSchedule.isPrincipleReleased = false;
        vestingSchedule.isBonusReleased = false;
        totalUnreleasedTokens = safeAdd(totalUnreleasedTokens, _totalAmount);
        vestingSchedule.amountReleased = 0;
    }

    function isVestingSet(address adr) public constant returns (bool isSet) {
        return vestingMap[adr].principleLockAmount != 0 || vestingMap[adr].bonusLockAmount != 0;
    }


    /** Release tokens as per vesting schedule, called by contributor  */
    function releaseMyVestedTokens() public {
        releaseVestedTokens(msg.sender);
    }

    /** Release tokens as per vesting schedule, called by anyone  */
    function releaseVestedTokens(address _adr) public {
        VestingSchedule storage vestingSchedule = vestingMap[_adr];
        
        uint256 _totalTokens = safeAdd(vestingSchedule.principleLockAmount, vestingSchedule.bonusLockAmount);
        // check if all tokens are not vested
        require(safeSub(_totalTokens, vestingSchedule.amountReleased) > 0);
        
        // calculate total vested tokens till now        
        uint256 amountToRelease = 0;

        if (block.timestamp >= vestingSchedule.principleLockPeriod && !vestingSchedule.isPrincipleReleased) {
            amountToRelease = safeAdd(amountToRelease,vestingSchedule.principleLockAmount);
            vestingSchedule.amountReleased = safeAdd(vestingSchedule.amountReleased, amountToRelease);
            vestingSchedule.isPrincipleReleased = true;
        }
        if (block.timestamp >= vestingSchedule.bonusLockPeriod && !vestingSchedule.isBonusReleased) {
            amountToRelease = safeAdd(amountToRelease,vestingSchedule.bonusLockAmount);
            vestingSchedule.amountReleased = safeAdd(vestingSchedule.amountReleased, amountToRelease);
            vestingSchedule.isBonusReleased = true;
        }

        // transfer vested tokens
        require(amountToRelease > 0);
        ERC20 token = ERC20(TokenAddress);
        token.transfer(_adr, amountToRelease);
        // decrement overall unreleased token count
        totalUnreleasedTokens = safeSub(totalUnreleasedTokens, amountToRelease);
        VestedTokensReleased(_adr, amountToRelease);
    }

}


