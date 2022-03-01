// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Base64} from "shell-contracts.git/libraries/Base64.sol";
import {IEngine, ShellBaseEngine} from "shell-contracts.git/engines/ShellBaseEngine.sol";
import {IShellFramework, StorageLocation, StringStorage, IntStorage, MintOptions, MintEntry} from "shell-contracts.git/IShellFramework.sol";
import {IERC165} from "shell-contracts.git/IShellFramework.sol";
import {SquadzDescriptor} from "./SquadzDescriptor.sol";

interface IERC721 {
    function balanceOf(address) external view returns (uint256);
}

contract SquadzEngine is SquadzDescriptor, ShellBaseEngine {
    //-------------------
    // State
    //-------------------

    /* Length of time a token is active */
    uint256 public constant baseExpiry = 180 days;

    /* Minimum time between mints for admins */
    uint256 public constant baseCooldown = 8 hours;

    /* Power bonus for having an active token */
    uint8 public constant baseBonus = 10;

    /* Max power from held tokens */
    uint8 public constant baseMax = 20;

    /* Key strings */
    string private constant _EXPIRY = "EXPIRY";
    string private constant _COOLDOWN = "COOLDOWN";
    string private constant _BONUS = "BONUS";
    string private constant _MAX = "MAX";

    //-------------------
    // Events
    //-------------------

    event SetCollectionConfig(
        address indexed collection,
        uint256 indexed fork,
        uint256 expiry,
        uint256 cooldown,
        uint256 bonus,
        uint256 max
    );

    //-------------------
    // External functions
    //-------------------

    function name() external pure returns (string memory) {
        return "Squadz Engine v0.0.1";
    }

    function getTokenURI(IShellFramework collection, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                _computeName(collection, tokenId),
                                '", "description":"',
                                _computeDescription(collection, tokenId),
                                '", "image": "',
                                _computeImageUri(collection, tokenId),
                                '", "external_url": "',
                                _computeExternalUrl(collection, tokenId),
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function powerOfAt(
        IShellFramework collection,
        uint256 fork,
        address member,
        uint256 timestamp
    ) external view returns (uint256 power) {
        (bool active, ) = isActiveAdmin(collection, fork, member, timestamp);
        (, , uint256 bonus, uint256 max) = getCollectionConfig(
            collection,
            fork
        );
        if (active) power += bonus;
        uint256 balance = IERC721(address(collection)).balanceOf(member);
        balance > max ? power += max : power += balance;
    }

    function batchMint(
        IShellFramework collection,
        uint256 fork,
        address[] calldata toAddresses,
        bool[] calldata adminBools
    ) external {
        require(toAddresses.length == adminBools.length, "array mismatch");
        for (uint256 i = 0; i < toAddresses.length; i++) {
            mint(collection, fork, toAddresses[i], adminBools[i]);
        }
    }

    /* No transfers! */
    function beforeTokenTransfer(
        address,
        address,
        address,
        uint256,
        uint256
    ) external pure override {
        revert("No transfers");
    }

    function setCollectionConfig(
        IShellFramework collection,
        uint256 fork,
        uint256 expiry,
        uint256 cooldown,
        uint256 bonus,
        uint256 max
    ) external {
        require(collection.getForkOwner(fork) == msg.sender, "owner only");
        require(expiry != 0, "expiry 0");
        require(cooldown != 0, "cooldown 0");
        require(bonus != 0, "activePower 0");
        require(max >= 1, "maxTokenPower < 1");

        (
            uint256 currentExpiry,
            uint256 currentCooldown,
            uint256 currentBonus,
            uint256 currentMax
        ) = getCollectionConfig(collection, fork);

        if (expiry != currentExpiry)
            collection.writeForkInt(
                StorageLocation.ENGINE,
                fork,
                _EXPIRY,
                expiry
            );

        if (cooldown != currentCooldown)
            collection.writeForkInt(
                StorageLocation.ENGINE,
                fork,
                _COOLDOWN,
                cooldown
            );

        if (bonus != currentBonus)
            collection.writeForkInt(
                StorageLocation.ENGINE,
                fork,
                _BONUS,
                bonus
            );

        if (max != currentMax)
            collection.writeForkInt(StorageLocation.ENGINE, fork, _MAX, max);

        emit SetCollectionConfig(
            address(collection),
            fork,
            expiry,
            cooldown,
            bonus,
            max
        );
    }

    //-------------------
    // Public functions
    //-------------------

    function mint(
        IShellFramework collection,
        uint256 fork,
        address to,
        bool admin
    ) public returns (uint256 tokenId) {
        StringStorage[] memory stringData = new StringStorage[](0);
        IntStorage[] memory intData = new IntStorage[](0);

        tokenId = collection.mint(
            MintEntry({
                to: to,
                amount: 1,
                options: MintOptions({
                    storeEngine: false,
                    storeMintedTo: false,
                    storeTimestamp: false,
                    storeBlockNumber: false,
                    stringData: stringData,
                    intData: intData
                })
            })
        );

        _writeMintData(collection, fork, to, tokenId, admin);
    }

    function getCollectionConfig(IShellFramework collection, uint256 fork)
        public
        view
        returns (
            uint256 expiry,
            uint256 cooldown,
            uint256 bonus,
            uint256 max
        )
    {
        expiry = collection.readForkInt(StorageLocation.ENGINE, fork, _EXPIRY);
        if (expiry == 0) expiry = baseExpiry;

        cooldown = collection.readForkInt(
            StorageLocation.ENGINE,
            fork,
            _COOLDOWN
        );
        if (cooldown == 0) cooldown = baseCooldown;

        bonus = collection.readForkInt(StorageLocation.ENGINE, fork, _BONUS);
        if (bonus == 0) bonus = uint256(baseBonus);

        max = collection.readForkInt(StorageLocation.ENGINE, fork, _MAX);
        if (max == 0) max = uint256(baseMax);
    }

    function latestTokenOf(
        IShellFramework collection,
        uint256 fork,
        address member
    )
        public
        view
        returns (
            uint256 tokenId,
            uint256 timestamp,
            bool admin
        )
    {
        uint256 res = collection.readForkInt(
            StorageLocation.ENGINE,
            fork,
            _latestTokenKey(member)
        );
        uint256 adminInt = res & 1;
        adminInt == 1 ? admin = true : admin = false;
        timestamp = uint256(uint128(res) >> 1);
        tokenId = res >> 128;
    }

    function isActiveAdmin(
        IShellFramework collection,
        uint256 fork,
        address member,
        uint256 timestamp
    ) public view returns (bool, bool) {
        (uint256 expiry, , , ) = getCollectionConfig(collection, fork);
        (, uint256 mintedAt, bool admin) = latestTokenOf(
            collection,
            fork,
            member
        );
        if (mintedAt + expiry <= timestamp) return (true, admin);
        return (false, admin);
    }

    //-------------------
    // Private functions
    //-------------------

    function _latestMintOf(
        IShellFramework collection,
        uint256 fork,
        address admin
    ) private view returns (uint256) {
        return
            collection.readForkInt(
                StorageLocation.ENGINE,
                fork,
                _latestMintKey(admin)
            );
    }

    function _writeMintData(
        IShellFramework collection,
        uint256 fork,
        address to,
        uint256 tokenId,
        bool admin
    ) private {
        require(tokenId <= type(uint128).max, "max tokens");
        if (admin) {
            require(collection.getForkOwner(fork) == msg.sender, "owner only");
        } else if (collection.getForkOwner(fork) != msg.sender) {
            // check sender is admin
            (bool senderActive, bool senderAdmin) = isActiveAdmin(
                collection,
                fork,
                msg.sender,
                block.timestamp
            );
            require(senderActive && senderAdmin, "owner, admin only");
            // check cooldown is up
            (, uint256 cooldown, , ) = getCollectionConfig(collection, fork);
            require(
                _latestMintOf(collection, fork, msg.sender) + cooldown >
                    block.timestamp,
                "cooldown"
            );
        }

        uint256 adminInt = 1;
        if (!admin) adminInt = 0;
        collection.writeForkInt(
            StorageLocation.ENGINE,
            fork,
            _latestTokenKey(to),
            (tokenId << 128) | (block.timestamp << 1) | adminInt
        );
        collection.writeForkInt(
            StorageLocation.ENGINE,
            fork,
            _latestMintKey(msg.sender),
            block.timestamp
        );
    }

    function _latestTokenKey(address member)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked("LATEST_TOKEN", member));
    }

    function _latestMintKey(address admin)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked("LATEST_MINT", admin));
    }
}
