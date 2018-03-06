pragma solidity ^0.4.18;

import "./Crowdsale.sol";
import "./CrowdsaleToken.sol";
import "./SafeMathLib.sol";

/**
 * At the end of the successful crowdsale allocate % bonus of tokens to the team.
 *
 * Unlock tokens.
 *
 * BonusAllocationFinal must be set as the minting agent for the MintableToken.
 *
 */
contract BonusFinalizeAgent is FinalizeAgent, SafeMathLib {

  CrowdsaleToken public token;
  Crowdsale public crowdsale;

  uint256 public allocatedTokens;
  uint256 tokenCap;
  address walletAddress;


  function BonusFinalizeAgent(CrowdsaleToken _token, Crowdsale _crowdsale, uint256 _tokenCap, address _walletAddress) public {
    token = _token;
    crowdsale = _crowdsale;

    //crowdsale address must not be 0
    require(address(crowdsale) != 0);

    tokenCap = _tokenCap;
    walletAddress = _walletAddress;
  }

  /* Can we run finalize properly */
  function isSane() public view returns (bool) {
    return (token.mintAgents(address(this)) == true) && (token.releaseAgent() == address(this));
  }

  /** Called once by crowdsale finalize() if the sale was success. */
  function finalizeCrowdsale() public {

    // if finalized is not being called from the crowdsale 
    // contract then throw
    require(msg.sender == address(crowdsale));

    // get the total sold tokens count.
    uint256 tokenSupply = token.totalSupply();

    allocatedTokens = safeSub(tokenCap,tokenSupply);
    
    if ( allocatedTokens > 0) {
      token.mint(walletAddress, allocatedTokens);
    }

    token.releaseTokenTransfer();
  }

}
