pragma solidity ^0.4.18;

import "./Crowdsale.sol";
import "./MintableToken.sol";

/**
 * ICO crowdsale contract that is capped by amout of ETH.
 *
 * - Tokens are dynamically created during the crowdsale
 *
 *
 */
contract MintedEthCappedCrowdsale is Crowdsale {

  /* Maximum amount of wei this crowdsale can raise. */
  uint public weiCap;

  function MintedEthCappedCrowdsale(address _token, PricingStrategy _pricingStrategy, 
    address _multisigWallet, uint256 _start, uint256 _end, uint256 _minimumFundingGoal, uint256 _weiCap, address _tokenVestingAddress) 
    Crowdsale(_token, _pricingStrategy, _multisigWallet, _start, _end, _minimumFundingGoal,_tokenVestingAddress) public
    { 
      weiCap = _weiCap;
    }

  /**
   * Called from invest() to confirm if the curret investment does not break our cap rule.
   */
  function isBreakingCap(uint256 weiAmount, uint256 tokenAmount, uint256 weiRaisedTotal, uint256 tokensSoldTotal) public constant returns (bool limitBroken) {
    return weiRaisedTotal > weiCap;
  }

  function isCrowdsaleFull() public constant returns (bool) {
    return weiRaised >= weiCap;
  }

  /**
   * Dynamically create tokens and assign them to the investor.
   */
  function assignTokens(address receiver, uint256 tokenAmount) private {
    MintableToken mintableToken = MintableToken(token);
    mintableToken.mint(receiver, tokenAmount);
  }
}
