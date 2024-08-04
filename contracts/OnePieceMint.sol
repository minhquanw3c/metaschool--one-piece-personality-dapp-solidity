// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/dev/vrf/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/dev/vrf/libraries/VRFV2PlusClient.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract OnePieceMint is VRFConsumerBaseV2Plus, ERC721URIStorage {
    string[] internal catTokenURIs = [
        "https://coral-cautious-mastodon-764.mypinata.cloud/ipfs/QmXoKJYKXGm7HggSxJAYUSHuiZgUCknZUX9NHy9mHqm85t",
        "https://coral-cautious-mastodon-764.mypinata.cloud/ipfs/QmZfL2KjueSgqLBSaAUHPqn1CShNTkMEVGKQ7tbcE1pp9b",
        "https://coral-cautious-mastodon-764.mypinata.cloud/ipfs/QmY3oq2G1Dqi6zZt9FpPF77BFt9umcERvZsNePALyUVx75",
        "https://coral-cautious-mastodon-764.mypinata.cloud/ipfs/Qmb6bMZM9XriWCEw7Tx6D43jd6GbsjEymScRcUTKaUzUcV",
        "https://coral-cautious-mastodon-764.mypinata.cloud/ipfs/QmRFk5mtJTcHUbgCtgxytWx3zVu5b7v34fFa1F8pmdSbEC"
    ];

    uint256 private s_tokenCounter;
    IVRFCoordinatorV2Plus private immutable i_vrfCoordinator;
    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint32 private immutable i_callbackGasLimit;

    mapping(uint256 => address) private vrfRequestIdToSender;
    mapping(address => uint256) private userFavoriteCat;
    mapping(address => bool) public userHasAdoptedCat;
    mapping(address => uint256) public s_userToAdoptedCat;

    event NftMinted(uint256 catId, address minter);
    event NftRequested(uint256 requestId, address requester);
    event CatTraitDetermined(uint256 catId);

    constructor(
        address vrfCoordinatorV2Address,
        uint256 subscriptionId,
        bytes32 subscriptionKeyHash,
        uint32 callbackGasLimit
    )
        VRFConsumerBaseV2Plus(vrfCoordinatorV2Address)
        ERC721("OnePiece NFT", "OPN")
    {
        // i_vrfCoordinator = IVRFCoordinatorV2Plus(vrfCoordinatorV2Address);
        i_vrfCoordinator = s_vrfCoordinator;
        i_subscriptionId = subscriptionId;
        i_keyHash = subscriptionKeyHash;
        i_callbackGasLimit = callbackGasLimit;
    }

    function mintNFT(address recipient, uint256 catId) internal {
        require(!userHasAdoptedCat[recipient], "You've already adopted a cat!");

        uint256 tokenId = s_tokenCounter;

        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, catTokenURIs[catId]);

        s_userToAdoptedCat[recipient] = catId;
        s_tokenCounter += 1;

        userHasAdoptedCat[recipient] = true;

        emit NftMinted(catId, recipient);
    }

    function determineCatType(
        uint256[5] memory answers
    ) private returns (uint256) {
        uint256 catId = 0;

        for (uint256 i = 0; i < 5; i++) {
            catId += answers[i];
        }

        catId = (catId % 5) + 1;

        emit CatTraitDetermined(catId);

        return catId;
    }

    function requestNFT(uint256[5] memory answers) public {
        userFavoriteCat[msg.sender] = determineCatType(answers);

        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: 3,
                callbackGasLimit: i_callbackGasLimit,
                numWords: 1,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        vrfRequestIdToSender[requestId] = msg.sender;

        emit NftRequested(requestId, msg.sender);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        address nftOwner = vrfRequestIdToSender[requestId];
        uint256 traitBasedCatId = userFavoriteCat[nftOwner];
        uint256 randomWord = randomWords[0];
        uint256 randomCatId = (randomWord % 5);
        uint256 finalCatId = (traitBasedCatId + randomCatId) % 5;

        mintNFT(nftOwner, finalCatId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        require(
            from == address(0) || to == address(0),
            "Err! This is not allowed"
        );
    }
}
