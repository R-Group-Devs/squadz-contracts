// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IShellFramework, MintEntry} from "shell-contracts.git/IShellFramework.sol";
import {PersonalizedSVG} from "./lib/PersonalizedSVG.sol";

interface IERC721 {
    function name() external view returns (string memory);

    function ownerOf(uint256) external view returns (address);
}

// Fits ENS' reverse records (main name)
interface INameRecord {
    function getNames(address[] calldata)
        external
        view
        returns (string[] memory r);
}

contract SquadzDescriptor is PersonalizedSVG {
    INameRecord public constant nameRecord = INameRecord(address(0));

    function _computeName(IShellFramework collection, uint256 tokenId)
        internal
        view
        returns (string memory name)
    {
        address owner = IERC721(address(collection)).ownerOf(tokenId);
        require(owner != address(0), "no token");
        address[] memory addresses = new address[](1);
        addresses[0] = owner;
        name = nameRecord.getNames(addresses)[0];
        if (bytes(name).length == 0)
            name = Strings.toHexString(uint256(uint160(owner)));
    }

    function _computeDescription(IShellFramework collection, uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "Squadz NFT: ",
                    IERC721(address(collection)).name(),
                    " \\n\\nIssued to ",
                    Strings.toHexString(
                        uint256(
                            uint160(
                                IERC721(address(collection)).ownerOf(tokenId)
                            )
                        )
                    ),
                    ".\\n\\n Token ID #",
                    Strings.toString(tokenId),
                    ".\\n\\n Powered by https://heyshell.xyz"
                )
            );
    }

    function _computeImageUri(IShellFramework collection, uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            getSVG(
                _computeName(collection, tokenId),
                IERC721(address(collection)).name(),
                Strings.toString(tokenId)
            );
    }

    function _computeExternalUrl(IShellFramework collection, uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "https://squadz.xyz/",
                    Strings.toHexString(uint256(uint160(address(collection))))
                )
            );
    }
}
