pragma solidity ^0.4.11;

import './SafeMath.sol';
import './Ownable.sol';
import './RefundVault.sol';
import './base.sol';


/**
 * @title MainassetPreICO
 * @dev MainassetPreICO is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract MainassetPreICO {
  using SafeMath for uint256;

  // The token being sold
  StandardMintableBurnableToken public token;
  
  address public owner;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets per wei
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function MainassetPreICO(address _token, address _wallet) {

    // address of MasToken
    token = StandardMintableBurnableToken(0x66b44b312028a647df2a4e1a94ece295660ad052);
    
    wallet = 0xd34B16dE8B6122b62bae710F6Dc431f16FC4ccBB;
    
    owner = msg.sender;


    // PRE-ICO starts exactly at 2017-11-11 11:11:11 UTC (1510398671)
    startTime = 1510398671;
    // PRE-ICO does until 2017-12-12 12:12:12 UTC (1513080732) 
    endTime = 1513080732;


    // 1 ETH = 1000 MAS
    rate = 1000;

    vault = new RefundVault(wallet);

    /// pre-ico goal
    cap = 1500 ether;

    /// minimum goal

    goal = 750 ether;

  }
  
  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());
    

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }



    uint256 public cap;

  // overriding Crowdsale#validPurchase to add extra cap logic
  // @return true if investors can buy at the moment
  function validPurchase() internal constant returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;

    return withinPeriod && nonZeroPurchase && withinCap;
  }

  // overriding Crowdsale#hasEnded to add cap logic
  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    bool tooLate = now > endTime;
    return tooLate || capReached;
  }


  /// finalazation part

  bool public isFinalized = false;

  event Finalized();

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract's finalization function.
   */
  function finalize() public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }


    // vault finalization task, called when owner calls finalize()
  function finalization() internal {
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }
    token.transferOwnership(owner);
  }

  

  // refundable part

   // minimum amount of funds to be raised in weis
  uint256 public goal;

  // refund vault used to hold funds while crowdsale is running
  RefundVault public vault;

  // We're overriding the fund forwarding from Crowdsale.
  // In addition to sending the funds, we want to call
  // the RefundVault deposit function
  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

  // if crowdsale is unsuccessful, investors can claim refunds here
  // In case of refund - investor need to burn all his tokens
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());
    // Investors can claim funds before 19 Dec. 2017 midnight (00:00:00) (1513641600)
    require(now < 1513641600);
    // Investor need to burn all his MAS tokens for fund to be returned
    require(token.balanceOf(msg.sender) == 0);

    vault.refund(msg.sender);
  }


  // Founders can take non-claimed funds after 19 Dec. 2017 midnight (00:00:00) (1513641600)
  function takeAllNotClaimedForRefundMoney() public {
    // Founders can take all non-claimed funds after 19 Dec. 2017 (1513641600)
    require(now >= 1513641600);
    vault.ownerTakesAllNotClaimedFunds();
  }

  function goalReached() public constant returns (bool) {
    return weiRaised >= goal;
  }


}
