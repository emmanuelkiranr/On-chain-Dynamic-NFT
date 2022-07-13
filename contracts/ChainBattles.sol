// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // To associate metadata to our nft
import "@openzeppelin/contracts/utils/Counters.sol"; // To give nfts unique id
import "@openzeppelin/contracts/utils/Strings.sol"; // utility lib to convert int to string
import "@openzeppelin/contracts/utils/Base64.sol"; // help us work with svgs

// we are inheriting from the ERC721 std
contract ChainBattles is ERC721URIStorage {
    using Strings for uint256; // allows uint to convert their value to strings
    using Counters for Counters.Counter; // to create tokenIds
    Counters.Counter private _tokenIds;

    mapping(uint256 => uint256) public tokenIdtolevels; // keeping track of levels of each different nfts

    constructor() ERC721("Chain Battles", "CBTLS") {} // we are calling the ERC721 constructor which takes 2 variable

    //generating an svg- svgs cannot be directly created in solidity, so we use a lib abi.encodePacked(arg); to
    // essentially concate strings together
    function generateCharacterNFT(uint256 tokenId)
        public
        returns (string memory)
    {
        // This is where we are constructing our svg
        // encodePacked takes several args of strings(svg to string by enclsoing inside quotes and concatinated together) turn them into bytes which we can supply into the base64 utility
        bytes memory svg = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">',
            "<style>.base { fill: white; font-family: serif; font-size: 14px; }</style>",
            '<rect width="100%" height="100%" fill="black" />',
            '<text x="50%" y="40%" class="base" dominant-baseline="middle" text-anchor="middle">',
            "Warrior",
            "</text>",
            '<text x="50%" y="50%" class="base" dominant-baseline="middle" text-anchor="middle">',
            "Levels: ",
            getLevels(tokenId), // should be a string
            "</text>",
            "</svg>"
            /* This is an svg code with styling. Just focus on text tags - our character=> warrior, we keep track of its levels using the 
            getLevels fn which takes the tokenId and returns the levels from the mapping tokenIdtolevels. 
            Since this fn changes the levels based on onchain activites this is an dynamic nft*/
        );
        return
            // we'll be typecasting abi.encodePacked(arg); which always returns bytes (strug to bytes)
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(svg)
                    /* instead of converting svg to string by ourself we use the Base64 contract by openzeppelin which
                     use Base64.encode to take that svg code and turn into a Base64 string - This is then returned as string*/
                ) // this will be creating the svg for us dynamically
            );
    }

    // Create getLevels fn
    function getLevels(uint256 tokenId) public view returns (string memory) {
        uint256 levels = tokenIdtolevels[tokenId];
        return levels.toString();
        // cause of Strings for uint declaration -converts level to string and returns it cause abi.encodePacked must always resolve to string
    }

    // create the tokenURI - associate metadata to nft
    function getTokenURI(uint256 tokenId) public returns (string memory) {
        // similar to constructing svg here we are construct an json object
        // each line is a series of strings concatinated together
        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "Chain Battles #',
            tokenId.toString(),
            '",',
            '"description": "Battles on chain",',
            '"image": "',
            generateCharacterNFT(tokenId), // generate the nft svg image
            '"',
            "}"
        );
        return
            // we can console.log() the return value for debugging
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }

    // create a mint fn

    function ming() public {
        _tokenIds.increment(); // since _tokenIds.current(); is 0
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId); // takes the to address and the tokenId - mint an nft to msg.sender with id newItemId
        tokenIdtolevels[newItemId = 0]; // for every newly minted nft the level starts from 0
        _setTokenURI(newItemId, getTokenURI(newItemId)); // takes tokenId and _tokenURI
        //  - for tokenId newItemId we call the getTokenURI which returns the metadata(the dataURI) of the nft with image

        /* So a token was minted using _safeMint() to msg.sender with id newItemId, then we give this token the metadata using 
        _setTokenURI() which gets the metadata for newItemId from getTokenURI()- which gets the current level from mapping tokenIdtolevel.
        initially this level is 0. whenever we change the level via training we just update the mapping of this tokenId and call the 
        _setTokenURI() which again gets metadata from getTokenURI()- which again gets the current level from mapping(this time the mapping returns
        the updated value); */
    }

    // Train fn to change the nft level - 1. check if token exist, 2. Onlyowner can train
    function train(uint256 tokenId) public {
        require(_exists(tokenId), "Please use an existing token");
        require(
            ownerOf(tokenId) == msg.sender,
            "Use must own this token to train it"
        );
        uint256 currentLevel = tokenIdtolevels[tokenId]; // get the current level and update it
        tokenIdtolevels[tokenId] = currentLevel++;
        // Now update the nft - ie update the metadata ie update the tokenURI
        _setTokenURI(tokenId, getTokenURI(tokenId));
        /* similar to setTokenURI using newItemId we can call that fn again with existing tokneId and update the metadata associated with this id*/
    }
}
