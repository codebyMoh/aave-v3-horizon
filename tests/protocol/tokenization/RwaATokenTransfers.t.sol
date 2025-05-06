// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC20} from 'src/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {Errors} from 'src/contracts/protocol/libraries/helpers/Errors.sol';
import {IAToken} from 'src/contracts/interfaces/IAToken.sol';

import {TestnetProcedures} from 'tests/utils/TestnetProcedures.sol';

contract RwaATokenTransferTests is TestnetProcedures {
    IAToken public aBuidl;

    address rwaForceTransferAdmin;

    function setUp() public {
        initTestEnvironment(false);

        rwaForceTransferAdmin = makeAddr('RWA_FORCE_TRANSFER_ADMIN_1');

        (address aBuidlAddress,,) = contracts.protocolDataProvider.getReserveTokensAddresses(tokenList.buidl);
        aBuidl = IAToken(aBuidlAddress);

        vm.startPrank(poolAdmin);
        buidl.mint(alice, 100e6);
        buidl.mint(carol, 1e6);
        buidl.mint(rwaForceTransferAdmin, 50e6);
        aclManager.addRwaForceTransferAdmin(rwaForceTransferAdmin);
        vm.stopPrank();

        vm.startPrank(alice);
        buidl.approve(report.poolProxy, UINT256_MAX);
        contracts.poolProxy.supply(tokenList.buidl, 100e6, alice, 0);
        vm.stopPrank();
        
        vm.startPrank(carol);
        buidl.approve(report.poolProxy, UINT256_MAX);
        contracts.poolProxy.supply(tokenList.buidl, 1e6, carol, 0);
        vm.stopPrank();

        vm.startPrank(rwaForceTransferAdmin);
        buidl.approve(report.poolProxy, UINT256_MAX);
        contracts.poolProxy.supply(tokenList.buidl, 50e6, rwaForceTransferAdmin, 0);
        vm.stopPrank();
    }

    function test_rwaAToken_transfer_alice_revertsWith_CallerNotRwaForceTransferAdmin() public {
        uint256 aliceBalance = aBuidl.balanceOf(alice);

        vm.expectRevert(bytes(Errors.CALLER_NOT_RWA_FORCE_TRANSFER_ADMIN));

        vm.prank(alice);
        aBuidl.transfer(carol, aliceBalance);
    }

    function test_rwaAToken_transfer_bob_revertsWith_CallerNotRwaForceTransferAdmin_ZeroAmount() public {
        vm.expectRevert(bytes(Errors.CALLER_NOT_RWA_FORCE_TRANSFER_ADMIN));

        vm.prank(bob);
        aBuidl.transfer(carol, 0);
    }

    function test_rwaAToken_transfer_rwaForceTransferAdmin_to_bob_all() public {
        uint256 rwaForceTransferAdminBalanceBefore = aBuidl.balanceOf(rwaForceTransferAdmin);
        uint256 bobBalanceBefore = aBuidl.balanceOf(bob);

        vm.expectEmit(address(aBuidl));
        emit IERC20.Transfer(rwaForceTransferAdmin, bob, rwaForceTransferAdminBalanceBefore);

        vm.prank(rwaForceTransferAdmin);
        aBuidl.transfer(bob, rwaForceTransferAdminBalanceBefore);

        assertEq(aBuidl.balanceOf(rwaForceTransferAdmin), 0);
        assertEq(aBuidl.balanceOf(bob), bobBalanceBefore + rwaForceTransferAdminBalanceBefore);
    }

    function test_rwaAToken_transfer_rwaForceTransferAdmin_to_bob_zero() public {
        uint256 rwaForceTransferAdminBalanceBefore = aBuidl.balanceOf(rwaForceTransferAdmin);
        uint256 bobBalanceBefore = aBuidl.balanceOf(bob);

        vm.expectEmit(address(aBuidl));
        emit IERC20.Transfer(rwaForceTransferAdmin, bob, 0);

        vm.prank(rwaForceTransferAdmin);
        aBuidl.transfer(bob, 0);

        assertEq(aBuidl.balanceOf(rwaForceTransferAdmin), rwaForceTransferAdminBalanceBefore);
        assertEq(aBuidl.balanceOf(bob), bobBalanceBefore);
    }

    function test_rwaAToken_transferFrom_alice_to_bob_by_rwaForceTransferAdmin_all() public {
        uint256 aliceBalanceBefore = aBuidl.balanceOf(alice);
        uint256 bobBalanceBefore = aBuidl.balanceOf(bob);

        vm.expectEmit(address(aBuidl));
        emit IERC20.Transfer(alice, bob, aliceBalanceBefore);

        vm.prank(rwaForceTransferAdmin);
        aBuidl.transferFrom(alice, bob, aliceBalanceBefore);

        assertEq(aBuidl.balanceOf(alice), 0);
        assertEq(aBuidl.balanceOf(bob), bobBalanceBefore + aliceBalanceBefore);
    }

    function test_rwaAToken_transferFrom_alice_to_bob_by_rwaForceTransferAdmin_zero() public {
        uint256 aliceBalanceBefore = aBuidl.balanceOf(alice);
        uint256 bobBalanceBefore = aBuidl.balanceOf(bob);

        vm.expectEmit(address(aBuidl));
        emit IERC20.Transfer(alice, bob, 0);

        vm.prank(rwaForceTransferAdmin);
        aBuidl.transferFrom(alice, bob, 0);

        assertEq(aBuidl.balanceOf(alice), aliceBalanceBefore);
        assertEq(aBuidl.balanceOf(bob), bobBalanceBefore);
    }

    function test_rwaAToken_transferFrom_alice_to_bob_by_carol_revertsWith_CallerNotRwaForceTransferAdmin() public {
        uint256 aliceBalance = aBuidl.balanceOf(alice);

        vm.prank(alice);
        aBuidl.approve(carol, aliceBalance);
        
        assertEq(aBuidl.allowance(alice, carol), aliceBalance);

        vm.expectRevert(bytes(Errors.CALLER_NOT_RWA_FORCE_TRANSFER_ADMIN));

        vm.prank(carol);
        aBuidl.transferFrom(alice, bob, aliceBalance);
    }
}