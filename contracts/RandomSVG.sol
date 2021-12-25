// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "base64-sol/base64.sol";

contract RandomSVG is ERC721URIStorage, VRFConsumerBase {
    bytes32 public keyHash;
    uint256 public fee;
    uint256 public tokenCounter;
    mapping(bytes32 => address) public requestIdToSender;
    mapping(bytes32 => uint256) public requestIdToTokenId;
    mapping(uint256 => uint256) public tokenIdToRandomNumber;

    // Svg parameters
    uint256 public maxNumberOfPaths;
    uint256 public maxNumberOfPathCommands;
    uint256 public size;
    string[] public pathCommands;
    string[] colors;

    event requestedRandomSVG(
        bytes32 indexed requestId,
        uint256 indexed tokenId
    );

    event CreatedUnfinishedRandomSVG(
        uint256 indexed tokenId,
        uint256 randomNumber
    );

    event CreatedRandomSVG(uint256 indexed tokenId, string tokenURI);

    constructor(
        address _VRFCoordinator,
        address _LinkToken,
        bytes32 _keyHash,
        uint256 _fee
    )
        VRFConsumerBase(_VRFCoordinator, _LinkToken)
        ERC721("RandomSVG", "rsNFT")
    {
        fee = _fee;
        keyHash = _keyHash;

        size = 500;
        maxNumberOfPaths = 10;
        pathCommands = ["M", "L"];
        maxNumberOfPathCommands = 5;
        colors = ["red", "green", "blue"];
    }

    function create() public returns (bytes32 requestId) {
        requestId = requestRandomness(keyHash, fee);
        requestIdToSender[requestId] = msg.sender;
        uint256 tokenId = tokenCounter;
        requestIdToTokenId[requestId] = tokenId;
        tokenCounter = tokenCounter + 1;

        emit requestedRandomSVG(requestId, tokenId);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
        internal
        override
    {
        // internal sice vrf coordinator will call this function
        address nftOwner = requestIdToSender[requestId];
        uint256 tokenId = requestIdToTokenId[requestId];

        _safeMint(nftOwner, tokenId);

        tokenIdToRandomNumber[tokenId] = randomNumber;
        emit CreatedUnfinishedRandomSVG(tokenId, randomNumber);
    }

    function svgToImageURI(string memory svg)
        public
        pure
        returns (string memory)
    {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(svg)))
        );
        string memory imageURI = string(
            abi.encodePacked(baseURL, svgBase64Encoded)
        );

        return imageURI;
    }

    function formatTokenURI(string memory imageURI)
        public
        pure
        returns (string memory)
    {
        string memory baseURL = "data:application/json;base64,";
        return
            string(
                abi.encodePacked(
                    baseURL,
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "SVG NFT", '
                                '"description": "An NFT based on SVG!", ',
                                '"attributes": "", ',
                                '"image": "',
                                imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function finishMint(uint256 tokenId) public {
        require(
            bytes(tokenURI(tokenId)).length <= 0,
            "tokenURI is already all set"
        );
        require(tokenCounter > tokenId, "Token has not been minted yet!");
        require(
            tokenIdToRandomNumber[tokenId] > 0,
            "Need to wait for Chainlink VRF"
        );

        uint256 randomNumber = tokenIdToRandomNumber[tokenId];
        string memory svg = generateRandomSVG(randomNumber);
        string memory imageURI = svgToImageURI(svg);
        string memory tokenURI = formatTokenURI(imageURI);
        _setTokenURI(tokenId, tokenURI);

        emit CreatedRandomSVG(tokenId, tokenURI);
    }

    function generateRandomSVG(uint256 randomNumber)
        public
        view
        returns (string memory finalSvg)
    {
        uint256 numberOfPaths = (randomNumber % maxNumberOfPaths) + 1;
        string memory sizeInStr = uint2str(size);

        finalSvg = string(
            abi.encodePacked(
                "<svg xmlns='http://www.w3.org/2000/svg' height='",
                sizeInStr,
                "' width='",
                sizeInStr,
                "'>"
            )
        );

        for (uint256 i = 0; i < numberOfPaths; i++) {
            uint256 newRNG = uint256(keccak256(abi.encode(randomNumber, i)));
            string memory pathSvg = generatePath(newRNG);
            finalSvg = string(abi.encodePacked(finalSvg, pathSvg));
        }

        finalSvg = string(abi.encodePacked(finalSvg, "</svg>"));
    }

    function generatePath(uint256 randomNumber)
        public
        view
        returns (string memory pathSvg)
    {
        uint256 numberOfPathCommands = (randomNumber %
            maxNumberOfPathCommands) + 1;
        pathSvg = "<path d='";

        for (uint256 i = 0; i < numberOfPathCommands; i++) {
            uint256 newRNG = uint256(
                keccak256(abi.encode(randomNumber, size + 1))
            );
            string memory pathCommand = generatePathCommand(newRNG);
            pathSvg = string(abi.encodePacked(pathSvg, pathCommand));
        }

        string memory color = colors[randomNumber % colors.length];
        pathSvg = string(
            abi.encodePacked(
                pathSvg,
                "' fill='transparent' stroke='",
                color,
                "'>"
            )
        );
    }

    function generatePathCommand(uint256 randomNumber)
        public
        view
        returns (string memory pathCommand)
    {
        pathCommand = pathCommands[randomNumber % pathCommands.length];
        uint256 parameterOne = uint256(
            keccak256(abi.encode(randomNumber, size * 2))
        );
        uint256 parameterTwo = uint256(
            keccak256(abi.encode(randomNumber, size * 3))
        );

        pathCommand = string(
            abi.encodePacked(
                pathCommand,
                " ",
                uint2str(parameterOne),
                " ",
                uint2str(parameterTwo)
            )
        );
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

// get a random numnber
// using rand no gen some ran svg code
// base64 encode the svg code
// get the token uri and mint the nft
//---
// check to see if its been minted and a random no is returned
// generate some random svg code
// tr that into an image uri
// turn image uri into tokenURI
