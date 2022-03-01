//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IPersonalizedSVG {
    function getSVG(
        string memory,
        string memory,
        string memory
    ) external pure returns (string memory);
}
