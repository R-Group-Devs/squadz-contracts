// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {DSTest} from "ds-test/test.sol";

import {PersonalizedSVG} from "../lib/PersonalizedSVG.sol";
import {SquadzEngine} from "../SquadzEngine.sol";
import {ShellFactory} from "shell-contracts.git/ShellFactory.sol";
import {ShellERC721} from "shell-contracts.git/ShellERC721.sol";
import {Hevm} from "./Hevm.sol";
import {console} from "./console.sol";

contract SquadzTest is DSTest {
    //-------------------
    // State
    //-------------------

    Hevm vm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    PersonalizedSVG personalizedSVG;
    SquadzEngine squadzEngine;
    ShellFactory shellFactory;
    ShellERC721 shellImplementation;
    string implementationName = "erc721";
    ShellERC721 squadzCollection;
    string collectionName = "squad";
    string collectionSymb = "SQD";
    address owner = address(0xBEEF);
    address bob = address(0xFEEB);
    uint256 defaultFork = 0;

    /* Length of time a token is active */
    uint256 public constant baseExpiry = 365 days;
    /* Minimum time between mints for admins */
    uint256 public constant baseCooldown = 8 hours;
    /* Power bonus for having an active token */
    uint8 public constant baseBonus = 10;
    /* Max power from held tokens */
    uint8 public constant baseMax = 20;
    /* personalized svg */
    address public baseSVG;

    //-------------------
    // Events
    //-------------------

    event SetCollectionConfig(
        address indexed collection,
        uint256 indexed fork,
        uint256 expiry,
        uint256 cooldown,
        uint256 bonus,
        uint256 max,
        address svg
    );

    //-------------------
    // Set up
    //-------------------

    function setUp() public {
        personalizedSVG = new PersonalizedSVG();
        baseSVG = address(personalizedSVG);
        squadzEngine = new SquadzEngine(address(0), baseSVG);
        shellFactory = new ShellFactory();
        shellImplementation = new ShellERC721();
        shellFactory.registerImplementation(
            implementationName,
            shellImplementation
        );
        squadzCollection = ShellERC721(
            address(
                shellFactory.createCollection(
                    collectionName,
                    collectionSymb,
                    implementationName,
                    squadzEngine,
                    owner
                )
            )
        );
        // time being 0 messes things up
        vm.warp(10);
    }

    //-------------------
    // Tests
    //-------------------

    // name //

    function test_name() public {
        assertEq("Squadz Engine v0.0.1", squadzEngine.name(), "engine name");
    }

    // setCollectionConfig //

    function test_setCollectionConfig(
        uint128 expiry_,
        uint128 cooldown_,
        uint128 bonus_,
        uint128 max_
    ) public {
        (
            uint256 expiry,
            uint256 cooldown,
            uint256 bonus,
            uint256 max,
            address svg
        ) = squadzEngine.getCollectionConfig(squadzCollection, defaultFork);
        assertEq(expiry, baseExpiry, "expiry");
        assertEq(cooldown, baseCooldown, "cooldown");
        assertEq(bonus, baseBonus, "bonus");
        assertEq(max, baseMax, "max");
        assertEq(svg, baseSVG, "svg");
        uint256 expectedNewExpiry = uint256(expiry_) + 1;
        uint256 expectedNewCooldown = uint256(cooldown_) + 1;
        uint256 expectedNewBonus = uint256(bonus_) + 1;
        uint256 expectedNewMax = uint256(max_) + 1;
        address expectedNewSVG = address(new PersonalizedSVG());
        vm.expectEmit(true, true, false, true);
        vm.prank(owner);
        emit SetCollectionConfig(
            address(squadzCollection),
            defaultFork,
            expectedNewExpiry,
            expectedNewCooldown,
            expectedNewBonus,
            expectedNewMax,
            expectedNewSVG
        );
        squadzEngine.setCollectionConfig(
            squadzCollection,
            defaultFork,
            expectedNewExpiry,
            expectedNewCooldown,
            expectedNewBonus,
            expectedNewMax,
            expectedNewSVG
        );
        (
            uint256 newExpiry,
            uint256 newCooldown,
            uint256 newBonus,
            uint256 newMax,
            address newSVG
        ) = squadzEngine.getCollectionConfig(squadzCollection, defaultFork);
        assertEq(newExpiry, expectedNewExpiry, "expiry");
        assertEq(newCooldown, expectedNewCooldown, "cooldown");
        assertEq(newBonus, expectedNewBonus, "bonus");
        assertEq(newMax, expectedNewMax, "max");
        assertEq(newSVG, expectedNewSVG, "svg");
    }

    function testFail_setCollectionConfig_notOwner() public {
        vm.prank(bob);
        squadzEngine.setCollectionConfig(
            squadzCollection,
            defaultFork,
            baseExpiry + 1,
            baseCooldown + 1,
            baseBonus + 1,
            baseMax + 1,
            baseSVG
        );
    }

    function testFail_setCollectionConfig_zeroExpiry() public {
        vm.prank(owner);
        squadzEngine.setCollectionConfig(
            squadzCollection,
            defaultFork,
            0,
            baseCooldown + 1,
            baseBonus + 1,
            baseMax + 1,
            baseSVG
        );
    }

    function testFail_setCollectionConfig_zeroCooldown() public {
        vm.prank(owner);
        squadzEngine.setCollectionConfig(
            squadzCollection,
            defaultFork,
            baseExpiry + 1,
            0,
            baseBonus + 1,
            baseMax + 1,
            baseSVG
        );
    }

    function testFail_setCollectionConfig_zeroBonus() public {
        vm.prank(owner);
        squadzEngine.setCollectionConfig(
            squadzCollection,
            defaultFork,
            baseExpiry + 1,
            baseCooldown + 1,
            0,
            baseMax + 1,
            baseSVG
        );
    }

    function testFail_setCollectionConfig_zeroMax() public {
        vm.prank(owner);
        squadzEngine.setCollectionConfig(
            squadzCollection,
            defaultFork,
            baseExpiry + 1,
            baseCooldown + 1,
            baseBonus + 1,
            0,
            baseSVG
        );
    }

    function testFail_setCollectionConfig_invalidSVG(address invalidSVG)
        public
    {
        if (invalidSVG == baseSVG) revert("same svg");
        vm.prank(owner);
        squadzEngine.setCollectionConfig(
            squadzCollection,
            defaultFork,
            baseExpiry + 1,
            baseCooldown + 1,
            baseBonus + 1,
            baseMax + 1,
            invalidSVG
        );
    }

    // mint //

    function test_mint_ownerMintAdmin(address mintee) public {
        if (mintee == address(0)) return;
        (, , , bool activeBefore, bool adminBefore, , ) = squadzEngine
            .getMemberInfo(squadzCollection, defaultFork, mintee);
        assertTrue(!activeBefore, "mintee active");
        assertTrue(!adminBefore, "mintee admin");
        vm.prank(owner);
        squadzEngine.mint(squadzCollection, defaultFork, mintee, true);
        (, , , bool activeAfter, bool adminAfter, , ) = squadzEngine
            .getMemberInfo(squadzCollection, defaultFork, mintee);
        assertTrue(activeAfter, "mintee active");
        assertTrue(adminAfter, "mintee admin");
    }

    function test_mint_ownerMintNonAdmin(address mintee) public {
        if (mintee == address(0)) return;
        (, , , bool activeBefore, bool adminBefore, , ) = squadzEngine
            .getMemberInfo(squadzCollection, defaultFork, mintee);
        assertTrue(!activeBefore, "mintee active");
        assertTrue(!adminBefore, "mintee admin");
        vm.prank(owner);
        squadzEngine.mint(squadzCollection, defaultFork, mintee, false);
        (, , , bool activeAfter, bool adminAfter, , ) = squadzEngine
            .getMemberInfo(squadzCollection, defaultFork, mintee);
        assertTrue(activeAfter, "mintee active");
        assertTrue(!adminAfter, "mintee admin");
    }

    function test_mint_adminMintNonAdmin(address admin, address mintee) public {
        if (mintee == address(0)) return;
        if (admin == address(0)) return;
        if (mintee == admin) return;
        test_mint_ownerMintAdmin(admin);
        (, , , bool activeBefore, bool adminBefore, , ) = squadzEngine
            .getMemberInfo(squadzCollection, defaultFork, mintee);
        assertTrue(!activeBefore, "mintee active 1");
        assertTrue(!adminBefore, "mintee admin 1");
        vm.prank(admin);
        squadzEngine.mint(squadzCollection, defaultFork, mintee, false);
        (, , , bool activeAfter, bool adminAfter, , ) = squadzEngine
            .getMemberInfo(squadzCollection, defaultFork, mintee);
        assertTrue(activeAfter, "mintee active 2");
        assertTrue(!adminAfter, "mintee admin 2");
        (, , uint256 timestamp1, , , , ) = squadzEngine.getMemberInfo(
            squadzCollection,
            defaultFork,
            mintee
        );
        assertEq(timestamp1, block.timestamp, "timestamp 1");
        console.log("timestamp before warp", block.timestamp);
        vm.warp(block.timestamp + baseCooldown + 1);
        console.log("timestamp after warp", block.timestamp);

        vm.prank(admin);
        squadzEngine.mint(squadzCollection, defaultFork, mintee, false);
        (, , uint256 timestamp2, , , , ) = squadzEngine.getMemberInfo(
            squadzCollection,
            defaultFork,
            mintee
        );
        assertEq(timestamp2, block.timestamp, "timestamp 2");
    }

    function testFail_mint_adminMintAdmin(address admin, address mintee)
        public
    {
        if (mintee == address(0)) return;
        if (admin == address(0)) return;
        test_mint_ownerMintAdmin(admin);
        (, , , bool activeBefore, bool adminBefore, , ) = squadzEngine
            .getMemberInfo(squadzCollection, defaultFork, mintee);
        assertTrue(!activeBefore, "mintee active");
        assertTrue(!adminBefore, "mintee admin");
        vm.prank(admin);
        squadzEngine.mint(squadzCollection, defaultFork, mintee, true);
    }

    function testFail_mint_inactiveAdmin(address admin, address mintee) public {
        if (mintee == address(0)) return;
        if (admin == address(0)) return;
        test_mint_ownerMintAdmin(admin);
        (, , , bool activeBefore, bool adminBefore, , ) = squadzEngine
            .getMemberInfo(squadzCollection, defaultFork, mintee);
        assertTrue(!activeBefore, "mintee active");
        assertTrue(!adminBefore, "mintee admin");
        vm.warp(block.timestamp + baseExpiry + 1);
        vm.prank(admin);
        squadzEngine.mint(squadzCollection, defaultFork, mintee, false);
    }

    function testFail_mint_nonAdminMint(address admin, address mintee) public {
        if (mintee == address(0)) return;
        if (admin == address(0)) return;
        (, , , bool activeBefore, bool adminBefore, , ) = squadzEngine
            .getMemberInfo(squadzCollection, defaultFork, mintee);
        assertTrue(!activeBefore, "mintee active");
        assertTrue(!adminBefore, "mintee admin");
        vm.prank(admin);
        squadzEngine.mint(squadzCollection, defaultFork, mintee, false);
    }

    function testFail_mint_adminMintCooldownNotUp(
        address admin,
        address mintee,
        uint64 cooldownNumerator
    ) public {
        if (mintee == address(0)) return;
        if (admin == address(0)) return;
        test_mint_ownerMintAdmin(admin);
        (, , , bool activeBefore, bool adminBefore, , ) = squadzEngine
            .getMemberInfo(squadzCollection, defaultFork, mintee);
        assertTrue(!activeBefore, "mintee active");
        assertTrue(!adminBefore, "mintee admin");
        uint256 newTime = block.timestamp +
            ((baseCooldown * cooldownNumerator) / type(uint64).max);
        vm.warp(newTime);
        squadzEngine.mint(squadzCollection, defaultFork, mintee, false);
    }

    // batchMint //

    function test_batchMint_owner() public {
        uint256 minteeCount = 10;
        address[] memory mintees = new address[](minteeCount);
        bool[] memory adminBools = new bool[](minteeCount);
        uint256 i;
        for (i; i < minteeCount; i++) {
            mintees[i] = address(uint160(i + 1));
            if (i % 2 == 0) adminBools[i] = true;
            address mintee = mintees[i];
            (, , , bool activeBefore, bool adminBefore, , ) = squadzEngine
                .getMemberInfo(squadzCollection, defaultFork, mintee);
            assertTrue(!activeBefore, "mintee active");
            assertTrue(!adminBefore, "mintee admin");
        }
        vm.prank(owner);
        squadzEngine.batchMint(
            squadzCollection,
            defaultFork,
            mintees,
            adminBools
        );
        for (i = 0; i < minteeCount; i++) {
            address mintee = mintees[i];
            (, , , bool activeAfter, bool adminAfter, , ) = squadzEngine
                .getMemberInfo(squadzCollection, defaultFork, mintee);
            assertTrue(activeAfter, "mintee active");
            assertTrue(adminAfter == adminBools[i], "mintee admin");
        }
    }

    function test_batchMint_admin(address admin) public {
        if (admin == address(0)) return;
        test_mint_ownerMintAdmin(admin);
        uint256 minteeCount = 10;
        address[] memory mintees = new address[](minteeCount);
        bool[] memory adminBools = new bool[](minteeCount);
        vm.prank(owner);
        squadzEngine.setCollectionConfig(
            squadzCollection,
            defaultFork,
            baseExpiry,
            type(uint256).max,
            baseBonus,
            baseMax,
            baseSVG
        );
        (, uint256 cooldown, , , ) = squadzEngine.getCollectionConfig(
            squadzCollection,
            defaultFork
        );
        console.log("found cooldown", cooldown);
        uint256 i;
        for (i; i < minteeCount; i++) {
            mintees[i] = address(uint160(i + 1));
            address mintee = mintees[i];
            if (admin == mintee) return;
            (, , , bool activeBefore, bool adminBefore, , ) = squadzEngine
                .getMemberInfo(squadzCollection, defaultFork, mintee);
            assertTrue(!activeBefore, "mintee active");
            assertTrue(!adminBefore, "mintee admin");
        }
        vm.prank(admin);
        squadzEngine.batchMint(
            squadzCollection,
            defaultFork,
            mintees,
            adminBools
        );
        for (i = 0; i < minteeCount; i++) {
            address mintee = mintees[i];
            (, , , bool activeAfter, bool adminAfter, , ) = squadzEngine
                .getMemberInfo(squadzCollection, defaultFork, mintee);
            assertTrue(activeAfter, "mintee active");
            assertTrue(!adminAfter, "mintee admin");
        }
    }

    function testFail_batchMint_arrayMismatch() public {
        uint256 minteeCount = 10;
        address[] memory mintees = new address[](minteeCount);
        bool[] memory adminBools = new bool[](minteeCount - 1);
        uint256 i;
        for (i; i < minteeCount; i++) {
            mintees[i] = address(uint160(i + 1));
            address mintee = mintees[i];
            (, , , bool activeBefore, bool adminBefore, , ) = squadzEngine
                .getMemberInfo(squadzCollection, defaultFork, mintee);
            assertTrue(!activeBefore, "mintee active");
            assertTrue(!adminBefore, "mintee admin");
        }
        vm.prank(owner);
        squadzEngine.batchMint(
            squadzCollection,
            defaultFork,
            mintees,
            adminBools
        );
    }

    // latestToken //

    function test_latestToken(address mintee, uint32 timeSkip) public {
        if (mintee == address(0)) return;

        (
            uint256 tokenId1,
            ,
            uint256 timestamp1,
            bool admin1,
            ,
            ,

        ) = squadzEngine.getMemberInfo(squadzCollection, defaultFork, mintee);
        assertEq(tokenId1, 0, "tokenId before");
        assertEq(timestamp1, 0, "timestamp before");
        assertTrue(!admin1, "admin before");
        test_mint_ownerMintAdmin(mintee);
        (
            uint256 tokenId2,
            ,
            uint256 timestamp2,
            ,
            bool admin2,
            ,

        ) = squadzEngine.getMemberInfo(squadzCollection, defaultFork, mintee);
        assertEq(
            tokenId2,
            squadzCollection.nextTokenId() - 1,
            "tokenId after 1"
        );
        assertEq(timestamp2, block.timestamp, "timestamp after 1");
        assertTrue(admin2, "admin after 1");
        vm.warp(block.timestamp + timeSkip);
        vm.prank(owner);
        squadzEngine.mint(squadzCollection, defaultFork, mintee, false);

        (
            uint256 tokenId3,
            ,
            uint256 timestamp3,
            ,
            bool admin3,
            ,

        ) = squadzEngine.getMemberInfo(squadzCollection, defaultFork, mintee);
        assertEq(
            tokenId3,
            squadzCollection.nextTokenId() - 1,
            "tokenId after 2"
        );
        assertEq(timestamp3, block.timestamp, "timestamp after 2");
        assertTrue(!admin3, "admin after 2");
    }

    // active & admin

    function test_activeAdmin(address mintee, uint8 expiryNumerator) public {
        if (mintee == address(0)) return;

        // if address has never been minted a token, returns false, false
        (, , , bool isActive1, bool isAdmin1, , ) = squadzEngine.getMemberInfo(
            squadzCollection,
            defaultFork,
            mintee
        );
        assertTrue(!isActive1, "is active 1");
        assertTrue(!isAdmin1, "is admin 1");
        uint256 timeSkip = ((baseExpiry * expiryNumerator) / type(uint8).max);

        // if address was most recently minted a non-admin token within expiry at timestamp, return true, false
        vm.prank(owner);
        squadzEngine.mint(squadzCollection, defaultFork, mintee, false);
        vm.warp(block.timestamp + timeSkip);
        (, , , bool isActive2, bool isAdmin2, , ) = squadzEngine.getMemberInfo(
            squadzCollection,
            defaultFork,
            mintee
        );
        console.log(isActive2, "is active");
        console.log(isAdmin2, "is admin 2");
        assertTrue(isActive2, "is active 2");
        assertTrue(!isAdmin2, "is admin 2");

        // if address was most recently minted an admin token within expiry at timestamp, returns true, true
        vm.prank(owner);
        squadzEngine.mint(squadzCollection, defaultFork, mintee, true);
        vm.warp(block.timestamp + timeSkip);
        (, , , bool isActive3, bool isAdmin3, , ) = squadzEngine.getMemberInfo(
            squadzCollection,
            defaultFork,
            mintee
        );
        assertTrue(isActive3, "is active 3");
        assertTrue(isAdmin3, "is admin 3");

        // avoid stack-too-deep error
        address mintee2 = mintee;

        // if address was most recently minted an admin token outside of expiry at timestamp, return false, true
        vm.prank(owner);
        squadzEngine.mint(squadzCollection, defaultFork, mintee2, true);
        vm.warp(block.timestamp + baseExpiry + 1);
        (, , , bool isActive4, bool isAdmin4, , ) = squadzEngine.getMemberInfo(
            squadzCollection,
            defaultFork,
            mintee2
        );
        assertTrue(!isActive4, "is active 4");
        assertTrue(isAdmin4, "is admin 4");

        // if address was most recently minted a non-admin token outside of expiry at timestamp, return false, false
        vm.prank(owner);
        squadzEngine.mint(squadzCollection, defaultFork, mintee2, false);
        vm.warp(block.timestamp + baseExpiry + 1);
        (, , , bool isActive5, bool isAdmin5, , ) = squadzEngine.getMemberInfo(
            squadzCollection,
            defaultFork,
            mintee2
        );
        assertTrue(!isActive5, "is active 5");
        assertTrue(!isAdmin5, "is admin 5");
    }

    // power //

    function test_power(
        address mintee,
        uint8 tokenCount,
        uint32 timeSkip
    ) public {
        if (mintee == address(0)) return;

        uint8 i;
        for (i; i < tokenCount; i++) {
            vm.prank(owner);
            squadzEngine.mint(squadzCollection, defaultFork, mintee, false);
        }

        uint256 bonus = baseBonus;
        if (timeSkip > baseExpiry || tokenCount == 0) bonus = 0;

        uint256 balanceScore = uint256(tokenCount);
        if (balanceScore > baseMax) balanceScore = baseMax;

        vm.warp(block.timestamp + timeSkip);
        (, , , , , uint256 power, ) = squadzEngine.getMemberInfo(
            squadzCollection,
            defaultFork,
            mintee
        );
        assertEq(power, bonus + balanceScore, "power");
    }

    // removeAdmin //

    function test_removeAdmin(address mintee) public {
        if (mintee == address(0)) return;
        test_mint_ownerMintAdmin(mintee);
        (
            uint256 tokenId1,
            ,
            uint256 timestamp1,
            ,
            bool admin1,
            ,

        ) = squadzEngine.getMemberInfo(squadzCollection, defaultFork, mintee);
        assertTrue(admin1, "admin 1");
        vm.prank(owner);
        squadzEngine.removeAdmin(squadzCollection, defaultFork, mintee);
        (
            uint256 tokenId2,
            ,
            uint256 timestamp2,
            ,
            bool admin2,
            ,

        ) = squadzEngine.getMemberInfo(squadzCollection, defaultFork, mintee);
        assertEq(tokenId1, tokenId2, "token Ids");
        assertEq(timestamp1, timestamp2, "timestamps");
        assertTrue(!admin2, "admin 2");
    }

    function testFail_removAdmin_nonOwner(address mintee) public {
        if (mintee == address(0)) return;
        test_mint_ownerMintAdmin(mintee);
        squadzEngine.removeAdmin(squadzCollection, defaultFork, mintee);
    }

    // getTokenURI //

    function test_getTokenURI(address mintee) public {
        if (mintee == address(0)) return;
        test_mint_ownerMintAdmin(mintee);
        (uint256 tokenId, , , , , , ) = squadzEngine.getMemberInfo(
            squadzCollection,
            defaultFork,
            mintee
        );
        squadzCollection.tokenURI(tokenId);
        // not sure what to do here tbh
    }
}
