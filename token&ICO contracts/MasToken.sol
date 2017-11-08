pragma solidity ^0.4.11;

import './base.sol';


/**
 * @title MAS token
 * Based on code by OpenZeppelen which is based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MasToken is StandardMintableBurnableToken {

  string public name = "Mainsset Token";
  string public symbol = "MAS";
  uint public decimals = 18;

}


