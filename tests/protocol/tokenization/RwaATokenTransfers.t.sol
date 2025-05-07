// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {AccessControl} from 'src/contracts/dependencies/openzeppelin/contracts/AccessControl.sol';
import {IERC20} from 'src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {Errors} from 'src/contracts/protocol/libraries/helpers/Errors.sol';
import {RWAAToken} from 'src/contracts/protocol/tokenization/RWAAToken.sol';
import {TestnetProcedures} from 'tests/utils/TestnetProcedures.sol';

contract RwaATokenTransferTests is TestnetProcedures {
  RWAAToken public aBuidl;

  address aTokenTransferAdmin;

  function setUp() public {
    initTestEnvironment(false);

    aTokenTransferAdmin = makeAddr('ATOKEN_TRANSFER_ADMIN_1');

    (address aBuidlAddress, , ) = contracts.protocolDataProvider.getReserveTokensAddresses(
      tokenList.buidl
    );
    aBuidl = RWAAToken(aBuidlAddress);

    vm.startPrank(poolAdmin);
    buidl.mint(alice, 100e6);
    buidl.mint(carol, 1e6);
    buidl.mint(aTokenTransferAdmin, 50e6);
    AccessControl(aclManagerAddress).grantRole(aBuidl.ATOKEN_TRANSFER_ROLE(), aTokenTransferAdmin);
    vm.stopPrank();

    vm.startPrank(alice);
    buidl.approve(report.poolProxy, UINT256_MAX);
    contracts.poolProxy.supply(tokenList.buidl, 100e6, alice, 0);
    vm.stopPrank();

    vm.startPrank(carol);
    buidl.approve(report.poolProxy, UINT256_MAX);
    contracts.poolProxy.supply(tokenList.buidl, 1e6, carol, 0);
    vm.stopPrank();

    vm.startPrank(aTokenTransferAdmin);
    buidl.approve(report.poolProxy, UINT256_MAX);
    contracts.poolProxy.supply(tokenList.buidl, 50e6, aTokenTransferAdmin, 0);
    vm.stopPrank();
  }

  function test_rwaAToken_transfer_fuzz_revertsWith_OperationNotSupported(address from) public {
    vm.expectRevert(bytes(Errors.OPERATION_NOT_SUPPORTED));

    vm.prank(from);
    aBuidl.transfer(alice, 0);
  }

  function test_rwaAToken_transfer_revertsWith_OperationNotSupported() public {
    test_rwaAToken_transfer_fuzz_revertsWith_OperationNotSupported(carol);
  }

  function test_rwaAToken_transferFrom_fuzz_by_aTokenTransferAdmin(uint256 amount) public {
    uint256 aliceBalanceBefore = aBuidl.balanceOf(alice);
    amount = bound(amount, 0, aliceBalanceBefore);

    uint256 bobBalanceBefore = aBuidl.balanceOf(bob);

    vm.expectEmit(address(aBuidl));
    emit IERC20.Transfer(alice, bob, amount);

    vm.prank(aTokenTransferAdmin);
    aBuidl.transferFrom(alice, bob, amount);

    assertEq(aBuidl.balanceOf(alice), aliceBalanceBefore - amount);
    assertEq(aBuidl.balanceOf(bob), bobBalanceBefore + amount);
  }

  function test_rwaAToken_transferFrom_by_aTokenTransferAdmin_all() public {
    test_rwaAToken_transferFrom_fuzz_by_aTokenTransferAdmin(aBuidl.balanceOf(alice));
  }

  function test_rwaAToken_transferFrom_by_aTokenTransferAdmin_partial() public {
    test_rwaAToken_transferFrom_fuzz_by_aTokenTransferAdmin(1);
  }

  function test_rwaAToken_transferFrom_by_aTokenTransferAdmin_zero() public {
    test_rwaAToken_transferFrom_fuzz_by_aTokenTransferAdmin(0);
  }

  function test_rwaAToken_transferFrom_fuzz_revertsWith_CallerNotATokenTransferAdmin(
    address from
  ) public {
    vm.assume(from != aTokenTransferAdmin);

    vm.expectRevert(bytes(Errors.CALLER_NOT_ATOKEN_TRANSFER_ADMIN));

    vm.prank(from);
    aBuidl.transferFrom(alice, bob, 0);
  }

  function test_rwaAToken_transferFrom_revertsWith_CallerNotATokenTransferAdmin() public {
    test_rwaAToken_transferFrom_fuzz_revertsWith_CallerNotATokenTransferAdmin(carol);
  }

  function test_rwaAToken_transferOnLiquidation_fuzz_revertsWith_RecipientNotTreasury(
    address to
  ) public {
    vm.assume(to != report.treasury);

    vm.expectRevert(bytes(Errors.RECIPIENT_NOT_TREASURY));

    vm.prank(report.poolProxy);
    aBuidl.transferOnLiquidation(alice, to, 0);
  }

  function test_rwaAToken_transferOnLiquidation_revertsWith_RecipientNotTreasury() public {
    test_rwaAToken_transferOnLiquidation_fuzz_revertsWith_RecipientNotTreasury(carol);
  }

  function test_rwaAToken_transferOnLiquidation_fuzz_revertsWith_CallerNotPool(
    address from
  ) public {
    vm.assume(from != report.poolProxy);

    vm.expectRevert(bytes(Errors.CALLER_MUST_BE_POOL));

    vm.prank(from);
    aBuidl.transferOnLiquidation(alice, report.treasury, 0);
  }

  function test_rwaAToken_transferOnLiquidation_revertsWith_CallerNotPool() public {
    test_rwaAToken_transferOnLiquidation_fuzz_revertsWith_CallerNotPool(carol);
  }

  function test_rwaAToken_transferOnLiquidation_fuzz(uint256 amount) public {
    uint256 aliceBalanceBefore = aBuidl.balanceOf(alice);
    amount = bound(amount, 0, aliceBalanceBefore);

    uint256 treasuryBalanceBefore = aBuidl.balanceOf(report.treasury);

    vm.expectEmit(address(aBuidl));
    emit IERC20.Transfer(alice, report.treasury, amount);

    vm.prank(report.poolProxy);
    aBuidl.transferOnLiquidation(alice, report.treasury, amount);

    assertEq(aBuidl.balanceOf(alice), aliceBalanceBefore - amount);
    assertEq(aBuidl.balanceOf(report.treasury), treasuryBalanceBefore + amount);
  }

  function test_rwaAToken_transferOnLiqudation_all() public {
    test_rwaAToken_transferOnLiquidation_fuzz(aBuidl.balanceOf(alice));
  }

  function test_rwaAToken_transferOnLiquidation_partial() public {
    test_rwaAToken_transferOnLiquidation_fuzz(1);
  }

  function test_rwaAToken_transferOnLiquidation_zero() public {
    test_rwaAToken_transferOnLiquidation_fuzz(0);
  }
}
