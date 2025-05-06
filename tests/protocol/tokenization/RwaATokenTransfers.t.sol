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

        (address aBuidlAddress,,) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.buidl);
        aBuidl = RWAAToken(aBuidlAddress);

        vm.startPrank(poolAdmin);
        buidl.mint(alice, 100e6);
        buidl.mint(carol, 1e6);
        buidl.mint(aTokenTransferAdmin, 50e6);
        AccessControl(aclManagerAddress).grantRole(aBuidl.RWA_FORCE_TRANSFER_ROLE(), aTokenTransferAdmin);
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

    function test_rwaAToken_transfer_alice_revertsWith_CallerNotATokenTransferAdmin() public {
        uint256 aliceBalance = aBuidl.balanceOf(alice);

        vm.expectRevert(bytes(Errors.CALLER_NOT_ATOKEN_TRANSFER_ADMIN));

        vm.prank(alice);
        aBuidl.transfer(carol, aliceBalance);
    }

    function test_rwaAToken_transfer_bob_revertsWith_CallerNotATokenTransferAdmin_ZeroAmount() public {
        vm.expectRevert(bytes(Errors.CALLER_NOT_ATOKEN_TRANSFER_ADMIN));

        vm.prank(bob);
        aBuidl.transfer(carol, 0);
    }

    function test_rwaAToken_transfer_aTokenTransferAdmin_to_bob_all() public {
        uint256 aTokenTransferAdminBalanceBefore = aBuidl.balanceOf(aTokenTransferAdmin);
        uint256 bobBalanceBefore = aBuidl.balanceOf(bob);

        vm.expectEmit(address(aBuidl));
        emit IERC20.Transfer(aTokenTransferAdmin, bob, aTokenTransferAdminBalanceBefore);

        vm.prank(aTokenTransferAdmin);
        aBuidl.transfer(bob, aTokenTransferAdminBalanceBefore);

        assertEq(aBuidl.balanceOf(aTokenTransferAdmin), 0);
        assertEq(aBuidl.balanceOf(bob), bobBalanceBefore + aTokenTransferAdminBalanceBefore);
    }

    function test_rwaAToken_transfer_aTokenTransferAdmin_to_bob_one() public {
        uint256 aTokenTransferAdminBalanceBefore = aBuidl.balanceOf(aTokenTransferAdmin);
        uint256 bobBalanceBefore = aBuidl.balanceOf(bob);

        uint256 transferAmount = 1e6;

        vm.expectEmit(address(aBuidl));
        emit IERC20.Transfer(aTokenTransferAdmin, bob, transferAmount);

        vm.prank(aTokenTransferAdmin);
        aBuidl.transfer(bob, transferAmount);

        assertEq(aBuidl.balanceOf(aTokenTransferAdmin), aTokenTransferAdminBalanceBefore - transferAmount);
        assertEq(aBuidl.balanceOf(bob), bobBalanceBefore + transferAmount);
    }

    function test_rwaAToken_transfer_aTokenTransferAdmin_to_bob_zero() public {
        uint256 aTokenTransferAdminBalanceBefore = aBuidl.balanceOf(aTokenTransferAdmin);
        uint256 bobBalanceBefore = aBuidl.balanceOf(bob);

        vm.expectEmit(address(aBuidl));
        emit IERC20.Transfer(aTokenTransferAdmin, bob, 0);

        vm.prank(aTokenTransferAdmin);
        aBuidl.transfer(bob, 0);

        assertEq(aBuidl.balanceOf(aTokenTransferAdmin), aTokenTransferAdminBalanceBefore);
        assertEq(aBuidl.balanceOf(bob), bobBalanceBefore);
    }

    function test_rwaAToken_transferFrom_alice_to_bob_by_aTokenTransferAdmin_all() public {
        uint256 aliceBalanceBefore = aBuidl.balanceOf(alice);
        uint256 bobBalanceBefore = aBuidl.balanceOf(bob);

        vm.expectEmit(address(aBuidl));
        emit IERC20.Transfer(alice, bob, aliceBalanceBefore);

        vm.prank(aTokenTransferAdmin);
        aBuidl.transferFrom(alice, bob, aliceBalanceBefore);

        assertEq(aBuidl.balanceOf(alice), 0);
        assertEq(aBuidl.balanceOf(bob), bobBalanceBefore + aliceBalanceBefore);
    }

    function test_rwaAToken_transferFrom_alice_to_bob_by_aTokenTransferAdmin_zero() public {
        uint256 aliceBalanceBefore = aBuidl.balanceOf(alice);
        uint256 bobBalanceBefore = aBuidl.balanceOf(bob);

        vm.expectEmit(address(aBuidl));
        emit IERC20.Transfer(alice, bob, 0);

        vm.prank(aTokenTransferAdmin);
        aBuidl.transferFrom(alice, bob, 0);

        assertEq(aBuidl.balanceOf(alice), aliceBalanceBefore);
        assertEq(aBuidl.balanceOf(bob), bobBalanceBefore);
    }

    function test_rwaAToken_transferFrom_alice_to_bob_by_carol_revertsWith_CallerNotATokenTransferAdmin() public {
        uint256 aliceBalance = aBuidl.balanceOf(alice);

        vm.expectRevert(bytes(Errors.CALLER_NOT_ATOKEN_TRANSFER_ADMIN));

        vm.prank(carol);
        aBuidl.transferFrom(alice, bob, aliceBalance);
    }
}