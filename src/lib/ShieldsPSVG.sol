//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IPersonalizedSVG} from "./IPersonalizedSVG.sol";
import {IShieldsAPI} from "shields-api/interfaces/IShieldsAPI.sol";

contract ShieldsPSVG is IPersonalizedSVG {
    IShieldsAPI internal immutable ShieldsAPI;

    //===== Constructor =====//

    constructor(IShieldsAPI shieldsAPI) {
        ShieldsAPI = shieldsAPI;
    }

    //===== Public Functions =====//

    function getSVG(
        string memory holder, // e.g. holder --> hardware
        string memory collection, // e.g. collection --> field, colors
        string memory tokenId // e.g. tokenId --> frame
    ) public view returns (string memory svg) {
        svg = ShieldsAPI.getShieldSVG(
            _stringToRandom16(collection), // field, uint16
            _stringToRandom24Array(collection), // colors, uint24[4]
            _stringToRandom16(holder), // hardware, uint16
            _stringToRandom16(tokenId) // frame, uin16
        );
    }

    //===== Private Functions =====//

    function _stringToRandom256(string memory input)
        private
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function _bytesToRandom256(bytes memory input)
        private
        pure
        returns (uint256)
    {
        return uint256(keccak256(input));
    }

    function _stringToRandom16(string memory input)
        private
        pure
        returns (uint16)
    {
        return
            uint16(
                (_stringToRandom256(input) * type(uint256).max) /
                    uint256(type(uint16).max)
            );
    }

    function _bytesSegmentToRandom24(
        bytes memory input,
        uint256 segmentLength,
        uint256 index
    ) private pure returns (uint24) {
        return
            uint24(
                (uint256(
                    keccak256(
                        abi.encodePacked(
                            input[segmentLength * index],
                            input[segmentLength * (index + 1)]
                        )
                    )
                ) * type(uint256).max) / uint256(type(uint24).max)
            );
    }

    function _stringToRandom24Array(string memory input)
        private
        pure
        returns (uint24[4] memory random24Array)
    {
        bytes memory b = bytes(input);
        uint256 segmentLength = b.length / 4;
        random24Array[0] = _bytesSegmentToRandom24(b, segmentLength, 0);
        random24Array[1] = _bytesSegmentToRandom24(b, segmentLength, 1);
        random24Array[2] = _bytesSegmentToRandom24(b, segmentLength, 2);
        random24Array[3] = _bytesSegmentToRandom24(b, segmentLength, 3);
    }
}
