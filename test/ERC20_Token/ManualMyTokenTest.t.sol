// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {DeployManualMyToken} from "script/ERC20_Script/DeployManualMyToken.s.sol";
import {ManualToken} from "src/ERC20_Token/ManualMyToken.sol";
import {Test, console} from "forge-std/Test.sol";

interface MintableToken {
    function mint(address, uint256) external;
}

interface tokenRecipient {
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes calldata _extraData
    ) external;
}

contract OurTokenTest is Test {
    uint256 BOB_STARTING_AMOUNT = 100 ether;
    uint256 public constant INITIAL_SUPPLY = 1000000e18; // 1 million tokens with 18 decimal places

    ManualToken public ourToken;
    DeployManualMyToken public deployer;
    address bob;
    address alice;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This generates a public event on the blockchain that will notify clients
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    function setUp() public {
        deployer = new DeployManualMyToken();
        ourToken = deployer.run();
        bob = makeAddr("bob");
        alice = makeAddr("alice");

        vm.prank(msg.sender);
        ourToken.transfer(bob, BOB_STARTING_AMOUNT);
    }

    function testInitialSupply() public view {
        assertEq(ourToken.totalSupply(), deployer.INITIAL_SUPPLY()*10**18);
    }

    function testUsersCantMint() public {
        vm.expectRevert();
        MintableToken(address(ourToken)).mint(address(this), 1);
    }

    function testAllowances() public {
        uint256 initialAllowance = 1000;

        // Bob approves Alice to spend tokens on his behalf
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);
        uint256 transferAmount = 500;

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);
        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), BOB_STARTING_AMOUNT - transferAmount);
    }

    // Test burning of tokens by an owner
    function testBurnTokens() public {
        uint256 burnAmount = 10 ether;
        vm.prank(bob);
        bool success = ourToken.burn(burnAmount);
        assertTrue(success);
        assertEq(ourToken.totalSupply(), INITIAL_SUPPLY - burnAmount);
        assertEq(ourToken.balanceOf(bob), BOB_STARTING_AMOUNT - burnAmount);
    }

    // Test burning tokens on behalf of another account
    function testBurnTokensFrom() public {
        uint256 burnAmount = 5 ether;

        vm.prank(bob);
        ourToken.approve(alice, burnAmount); // Approve Alice to burn on Bob's behalf

        vm.prank(alice);
        bool success = ourToken.burnFrom(bob, burnAmount);
        assertTrue(success);
        assertEq(ourToken.totalSupply(), INITIAL_SUPPLY - burnAmount);
        assertEq(ourToken.balanceOf(bob), BOB_STARTING_AMOUNT - burnAmount);
    }

    // Test approval and call
    function testApproveAndCall() public {
        // Create a mock contract to act as the spender
        MockRecipient recipient = new MockRecipient();

        vm.prank(bob);
        bool success = ourToken.approveAndCall(
            address(recipient),
            1000,
            "0x1234"
        );
        assertTrue(success);
        assertEq(recipient.sender(), bob);
        assertEq(recipient.token(), address(ourToken));
        assertEq(recipient.value(), 1000);
        assertEq(recipient.extraData(), "0x1234");
    }

    // Test transfers to and from the zero address
    function testTransferToZeroAddress() public {
        vm.prank(bob);
        vm.expectRevert();
        ourToken.transfer(address(0), 1);
    }

    function testTransferFromZeroAddress() public {
        vm.expectRevert();
        ourToken.transferFrom(address(0), bob, 1 );
    }

    // Test events emitted
    function testTransferEvent() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(bob, alice, 10 );

        vm.prank(bob);
        ourToken.transfer(alice, 10 );
    }

    function testApprovalEvent() public {
        vm.expectEmit(true, true, false, true);
        emit Approval(bob, alice, 500 );

        vm.prank(bob);
        ourToken.approve(alice, 500 );
    }

    function testBurnEvent() public {
        uint256 burnAmount = 10 ether;

        vm.expectEmit(true, true, false, true);
        emit Burn(bob, burnAmount);

        vm.prank(bob);
        ourToken.burn(burnAmount);
    }
}

// Mock contract for testing approveAndCall functionality
contract MockRecipient is tokenRecipient {
    address public sender;
    address public token;
    uint256 public value;
    bytes public extraData;

    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes calldata _extraData
    ) external override {
        sender = _from;
        value = _value;
        token = _token;
        extraData = _extraData;
    }
}
