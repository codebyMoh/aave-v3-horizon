// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from 'src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {Errors} from 'src/contracts/protocol/libraries/helpers/Errors.sol';
import {ACLManager} from 'src/contracts/protocol/configuration/ACLManager.sol';
import {RWAAToken} from 'src/contracts/protocol/tokenization/RWAAToken.sol';
import {IRWAATokenManager} from 'src/contracts/interfaces/IRWAATokenManager.sol';

contract RWAATokenManager is IRWAATokenManager {
  ACLManager public immutable override ACL_MANAGER;

  bytes32 internal constant ATOKEN_TRANSFER_ROLE = keccak256('ATOKEN_TRANSFER_ROLE');

  constructor(ACLManager aclManager) {
    ACL_MANAGER = aclManager;
  }

  function getATokenTransferRole(address aToken) public pure override returns (bytes32) {
    return keccak256(abi.encode(ATOKEN_TRANSFER_ROLE, aToken));
  }

  function transferRWAAToken(
    address rwaAToken,
    address sender,
    address recipient,
    uint256 amount
  ) external override returns (bool) {
    require(
      ACL_MANAGER.hasRole(getATokenTransferRole(rwaAToken), msg.sender),
      Errors.CALLER_NOT_ATOKEN_TRANSFER_ADMIN
    );

    bool success = IERC20(rwaAToken).transferFrom(sender, recipient, amount);
    require(
      IERC20(rwaAToken).balanceOf(address(this)) == 0,
      Errors.NON_ZERO_MANAGER_ATOKEN_BALANCE
    );

    return success;
  }
}
