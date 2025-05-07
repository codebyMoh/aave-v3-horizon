// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Errors} from 'src/contracts/protocol/libraries/helpers/Errors.sol';
import {RWAAToken} from 'src/contracts/protocol/tokenization/RWAAToken.sol';
import {TestnetProcedures} from 'tests/utils/TestnetProcedures.sol';

contract RwaATokenAllowanceTests is TestnetProcedures {
  RWAAToken public aBuidl;

  function setUp() public {
    initTestEnvironment();

    (address aBuidlAddress, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(
      tokenList.buidl
    );
    aBuidl = RWAAToken(aBuidlAddress);
  }

  function test_rwaAToken_permit_revertsWith_OperationNotSupported() public {
    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));

    vm.prank(alice);
    aBuidl.permit(alice, bob, 100e6, block.timestamp + 1, 0, bytes32(0), bytes32(0));
  }

  function test_rwaAToken_permit_fuzz_revertsWith_OperationNotSupported(
    address from,
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));

    vm.prank(from);
    aBuidl.permit(owner, spender, value, deadline, v, r, s);
  }

  function test_rwaAToken_approve_revertsWith_OperationNotSupported() public {
    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));

    vm.prank(alice);
    aBuidl.approve(bob, 100e6);
  }

  function test_rwaAToken_approve_fuzz_revertsWith_OperationNotSupported(
    address from,
    address spender,
    uint256 amount
  ) public {
    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));

    vm.prank(from);
    aBuidl.approve(spender, amount);
  }

  function test_rwaAToken_increaseAllowance_revertsWith_OperationNotSupported() public {
    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));

    vm.prank(alice);
    aBuidl.increaseAllowance(bob, 100e6);
  }

  function test_rwaAToken_increaseAllowance_fuzz_revertsWith_OperationNotSupported(
    address from,
    address spender,
    uint256 addedValue
  ) public {
    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));

    vm.prank(from);
    aBuidl.increaseAllowance(spender, addedValue);
  }

  function test_rwaAToken_decreaseAllowance_revertsWith_OperationNotSupported() public {
    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));

    vm.prank(alice);
    aBuidl.decreaseAllowance(bob, 100e6);
  }

  function test_rwaAToken_decreaseAllowance_fuzz_revertsWith_OperationNotSupported(
    address from,
    address spender,
    uint256 subtractedValue
  ) public {
    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));

    vm.prank(from);
    aBuidl.decreaseAllowance(spender, subtractedValue);
  }
}
