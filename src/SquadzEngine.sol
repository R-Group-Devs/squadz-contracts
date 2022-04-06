// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Base64} from "shell-contracts.git/libraries/Base64.sol";
import {ShellBaseEngine} from "shell-contracts.git/engines/ShellBaseEngine.sol";
import {IShellFramework, StorageLocation, StringStorage, IntStorage, MintOptions, MintEntry} from "shell-contracts.git/IShellFramework.sol";
import {SquadzDescriptor} from "./SquadzDescriptor.sol";
import {IPersonalizedSVG} from "./lib/IPersonalizedSVG.sol";

contract SquadzEngine is ShellBaseEngine, SquadzDescriptor {
    //-------------------
    // State
    //-------------------

    /* Length of time a token is active */
    uint256 public constant baseExpiry = 365 days;

    /* Minimum time between mints for admins */
    uint256 public constant baseCooldown = 8 hours;

    /* Power bonus for having an active token */
    uint8 public constant baseBonus = 10;

    /* Max power from held tokens */
    uint8 public constant baseMax = 20;

    /* Personalized SVG engine */
    address public immutable baseSVG;

    /* Key strings */
    string private constant _EXPIRY = "EXPIRY";
    string private constant _COOLDOWN = "COOLDOWN";
    string private constant _BONUS = "BONUS";
    string private constant _MAX = "MAX";
    string private constant _SVG = "SVG";

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
        address svgAddress
    );

    //-------------------
    // Constructor
    //-------------------

    constructor(address nameRecordAddress, address baseSVG_)
        SquadzDescriptor(nameRecordAddress)
    {
        IPersonalizedSVG(baseSVG_).getSVG("", "", ""); // should throw if no method
        baseSVG = baseSVG_;
    }

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
        uint256 forkId = collection.getTokenForkId(tokenId);
        (, , , , address svgAddress) = getCollectionConfig(collection, forkId);
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
                                _computeImageUri(
                                    collection,
                                    tokenId,
                                    IPersonalizedSVG(svgAddress)
                                ),
                                '", "external_url": "',
                                _computeExternalUrl(collection, tokenId),
                                '"}'
                            )
                        )
                    )
                )
            );
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
        address from,
        address,
        uint256,
        uint256
    ) external pure override {
        require(from == address(0), "Only mints");
    }

    // To set cooldown, bonus, or max to 0, set them to type(uint256).max

    function setCollectionConfig(
        IShellFramework collection,
        uint256 fork,
        uint256 expiry,
        uint256 cooldown,
        uint256 bonus,
        uint256 max,
        address svgAddress
    ) external {
        require(collection.getForkOwner(fork) == msg.sender, "owner only");
        require(expiry != 0, "expiry 0");
        require(cooldown != 0, "cooldown 0");
        require(bonus != 0, "bonus 0");
        require(max != 0, "max 0");
        IPersonalizedSVG(svgAddress).getSVG("", "", ""); // should throw if no method

        (
            uint256 currentExpiry,
            uint256 currentCooldown,
            uint256 currentBonus,
            uint256 currentMax,
            address currentSvgAddress
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

        if (svgAddress != currentSvgAddress)
            collection.writeForkInt(
                StorageLocation.ENGINE,
                fork,
                _SVG,
                uint256(uint160(svgAddress))
            );

        emit SetCollectionConfig(
            address(collection),
            fork,
            expiry,
            cooldown,
            bonus,
            max,
            svgAddress
        );
    }

    function removeAdmin(
        IShellFramework collection,
        uint256 fork,
        address member
    ) external {
        require(collection.getForkOwner(fork) == msg.sender, "owner only");
        (uint256 tokenId, , uint256 timestamp, bool admin) = _getLatestToken(
            collection,
            fork,
            member
        );
        if (admin)
            // rewrite the latest token with admin == false
            _writeLatestToken(collection, fork, member, tokenId, timestamp, 0);
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
        if (admin) {
            require(collection.getForkOwner(fork) == msg.sender, "owner only");
        } else if (collection.getForkOwner(fork) != msg.sender) {
            // check sender is admin
            (
                ,
                ,
                ,
                bool senderActive,
                bool senderAdmin,
                ,
                uint256 latestMintTime
            ) = getMemberInfo(collection, fork, msg.sender);
            require(senderActive && senderAdmin, "owner, admin only");

            // check cooldown is up
            (, uint256 cooldown, , , ) = getCollectionConfig(collection, fork);
            if (latestMintTime != 0)
                require(
                    latestMintTime + cooldown <= block.timestamp,
                    "cooldown"
                );
        }
        (, uint256 balance, , ) = _getLatestToken(collection, fork, to);
        require(balance < type(uint64).max, "max balance");

        StringStorage[] memory stringData = new StringStorage[](0);
        IntStorage[] memory intData = new IntStorage[](0);

        // we would really like to set this token's fork here, too, but we can't
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

        require(tokenId <= type(uint128).max, "max tokens");

        _writeMintData(collection, fork, to, tokenId, balance, admin);
    }

    function getCollectionConfig(IShellFramework collection, uint256 fork)
        public
        view
        returns (
            uint256 expiry,
            uint256 cooldown,
            uint256 bonus,
            uint256 max,
            address svgAddress
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
        else if (cooldown == type(uint256).max) cooldown = 0;

        bonus = collection.readForkInt(StorageLocation.ENGINE, fork, _BONUS);
        if (bonus == 0) bonus = uint256(baseBonus);
        else if (bonus == type(uint256).max) bonus = 0;

        max = collection.readForkInt(StorageLocation.ENGINE, fork, _MAX);
        if (max == 0) max = uint256(baseMax);
        else if (max == type(uint256).max) max = 0;

        svgAddress = address(
            uint160(collection.readForkInt(StorageLocation.ENGINE, fork, _SVG))
        );
        if (svgAddress == address(0)) svgAddress = baseSVG;
    }

    function getMemberInfo(
        IShellFramework collection,
        uint256 fork,
        address member
    )
        public
        view
        returns (
            uint256 latestTokenId,
            uint256 forkBalance,
            uint256 latestTokenTime,
            bool active,
            bool admin,
            uint256 power,
            uint256 latestMintTime
        )
    {
        (latestTokenId, forkBalance, latestTokenTime, admin) = _getLatestToken(
            collection,
            fork,
            member
        );
        (uint256 expiry, , uint256 bonus, uint256 max, ) = getCollectionConfig(
            collection,
            fork
        );
        if (latestTokenTime != 0 && latestTokenTime + expiry >= block.timestamp)
            active = true;
        if (active) power += bonus;
        forkBalance > max ? power += max : power += forkBalance;
        latestMintTime = _getLatestMint(collection, fork, member);
    }

    //-------------------
    // Private functions
    //-------------------

    function _getLatestToken(
        IShellFramework collection,
        uint256 fork,
        address member
    )
        private
        view
        returns (
            uint256 tokenId,
            uint256 forkBalance,
            uint256 timestamp,
            bool admin
        )
    {
        uint256 res = collection.readForkInt(
            StorageLocation.ENGINE,
            fork,
            _latestTokenKey(member)
        );
        uint256 adminInt = res & 0x1;
        adminInt == 1 ? admin = true : admin = false;
        timestamp = uint256(uint64(res) >> 1);
        forkBalance = uint256(uint128(res) >> 64);
        tokenId = res >> 128;
    }

    function _getLatestMint(
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
        uint256 balance,
        bool admin
    ) private {
        uint256 adminInt = 1;
        if (!admin) adminInt = 0;
        _writeLatestToken(collection, fork, to, tokenId, balance + 1, adminInt);
        collection.writeForkInt(
            StorageLocation.ENGINE,
            fork,
            _latestMintKey(msg.sender),
            block.timestamp
        );
    }

    function _writeLatestToken(
        IShellFramework collection,
        uint256 fork,
        address to,
        uint256 tokenId,
        uint256 balance,
        uint256 adminInt
    ) private {
        collection.writeForkInt(
            StorageLocation.ENGINE,
            fork,
            _latestTokenKey(to),
            (tokenId << 128) |
                (balance << 64) |
                (block.timestamp << 1) | // assumes timestamp can never be greater than max uint63
                (adminInt & 0x1)
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
