// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ACLManager} from 'src/contracts/protocol/configuration/ACLManager.sol';

interface IRWAATokenManager {
  function ACL_MANAGER() external view returns (ACLManager);

  function getATokenTransferRole(address aToken) external pure returns (bytes32);

  function transferRWAAToken(
    address rwaAToken,
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}
