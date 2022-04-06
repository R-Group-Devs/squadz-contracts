//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "shell-contracts.git/libraries/Base64.sol";
import {IPersonalizedSVG} from "./IPersonalizedSVG.sol";

contract PersonalizedSVG is IPersonalizedSVG {
    using Strings for uint256;

    //===== State =====//

    struct RgbColor {
        uint256 r;
        uint256 g;
        uint256 b;
    }

    //===== public Functions =====//

    function getSVG(
        string memory memberName,
        string memory tokenName,
        string memory tokenId
    ) public pure returns (string memory) {
        string memory output = _buildOutput(memberName, tokenName, tokenId);
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(bytes(output))
                )
            );
    }

    //===== Private Functions =====//

    function _random(string memory input) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function _pluckColor(string memory seed1, string memory seed2)
        private
        pure
        returns (RgbColor memory)
    {
        RgbColor memory rgb = RgbColor(
            _random(string(abi.encodePacked(seed1, seed2))) % 255,
            _random(seed1) % 255,
            _random(seed2) % 255
        );
        return rgb;
    }

    function _rotateColor(RgbColor memory rgb)
        private
        pure
        returns (RgbColor memory)
    {
        RgbColor memory rotated = RgbColor(
            (rgb.r + 128) % 255,
            (rgb.g + 128) % 255,
            (rgb.b + 128) % 255
        );
        return rotated;
    }

    function _colorToString(RgbColor memory rgb)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "rgba",
                    "(",
                    rgb.r.toString(),
                    ",",
                    rgb.g.toString(),
                    ",",
                    rgb.b.toString(),
                    ", 1)"
                )
            );
    }

    function _buildOutput(
        string memory memberName,
        string memory tokenName,
        string memory tokenId
    ) private pure returns (string memory) {
        RgbColor memory rgb1 = _pluckColor(tokenName, "");
        RgbColor memory rgb2 = _rotateColor(rgb1);
        RgbColor memory rgb3 = _pluckColor(memberName, "");
        RgbColor memory rgb4 = _rotateColor(rgb3);
        RgbColor memory rgb5 = _pluckColor(tokenId, "");
        RgbColor memory rgb6 = _rotateColor(rgb5);
        string memory output = string(
            abi.encodePacked(
                '<svg width="314" height="400" viewBox="0 0 314 400" fill="none" xmlns="http://www.w3.org/2000/svg"><rect width="314" height="400" rx="157" fill="url(#paint0_radial_101_2)"/><rect x="20" y="25" width="274.75" height="350" rx="137.375" fill="url(#paint1_radial_101_2)"/><rect x="39" y="50" width="235.5" height="300" rx="117.75" fill="url(#paint2_radial_101_2)"/><rect x="59" y="75" width="196.25" height="250" rx="98.125" fill="url(#paint3_radial_101_2)"/><rect x="78" y="100" width="157" height="200" rx="78.5" fill="url(#paint4_radial_101_2)"/><rect x="98" y="125" width="117.75" height="150" rx="58.875" fill="url(#paint5_radial_101_2)"/><defs><radialGradient id="paint0_radial_101_2" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(157 200) rotate(90) scale(207 161.536)"><stop stop-color="',
                _colorToString(rgb1),
                '"/></radialGradient><radialGradient id="paint1_radial_101_2" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(157.375 200) rotate(90) scale(181.125 141.344)"><stop stop-color="',
                _colorToString(rgb2),
                '"/></radialGradient><radialGradient id="paint2_radial_101_2" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(156.75 200) rotate(90) scale(155.25 121.152)"><stop stop-color="',
                _colorToString(rgb3),
                '"/></radialGradient><radialGradient id="paint3_radial_101_2" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(157.125 200) rotate(90) scale(129.375 100.96)"><stop stop-color="',
                _colorToString(rgb4)
            )
        );
        return
            string(
                abi.encodePacked(
                    output,
                    '"/></radialGradient><radialGradient id="paint4_radial_101_2" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(156.5 200) rotate(90) scale(103.5 80.7681)"><stop stop-color="',
                    _colorToString(rgb5),
                    '"/></radialGradient><radialGradient id="paint5_radial_101_2" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(156.875 200) rotate(90) scale(77.625 60.5761)"><stop stop-color="',
                    _colorToString(rgb6),
                    '"/></radialGradient></defs></svg>'
                )
            );
    }
}
