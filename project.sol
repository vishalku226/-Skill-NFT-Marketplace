// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SkillNFTMarketplace is ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    struct Skill {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        string skillName;
        string skillLevel;
        bool isVerified;
        bool isListed;
    }

    mapping(uint256 => Skill) private idToSkill;
    mapping(address => mapping(string => bool)) private userSkills;

    // Events
    event SkillCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        string skillName,
        string skillLevel,
        bool isVerified
    );

    event SkillListed(uint256 indexed tokenId, uint256 price);
    event SkillSold(uint256 indexed tokenId, address seller, address buyer, uint256 price);
    event SkillVerified(uint256 indexed tokenId, bool verified);

    // Constructor
    constructor() Ownable(msg.sender) {}

    // Create a new skill NFT
    function createSkill(
        string memory skillName,
        string memory skillLevel,
        uint256 price
    ) public returns (uint256) {
        require(bytes(skillName).length > 0, "Skill name cannot be empty");
        require(bytes(skillLevel).length > 0, "Skill level cannot be empty");
        require(!userSkills[msg.sender][skillName], "You already have this skill");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        idToSkill[newTokenId] = Skill(
            newTokenId,
            payable(msg.sender),
            payable(msg.sender),
            price,
            skillName,
            skillLevel,
            false,
            false
        );

        userSkills[msg.sender][skillName] = true;

        emit SkillCreated(
            newTokenId,
            msg.sender,
            msg.sender,
            price,
            skillName,
            skillLevel,
            false
        );

        return newTokenId;
    }

    // List skill NFT for sale
    function listSkill(uint256 tokenId, uint256 price) public {
        require(idToSkill[tokenId].owner == msg.sender, "Only owner can list skill");
        require(price > 0, "Price must be greater than 0");

        idToSkill[tokenId].price = price;
        idToSkill[tokenId].isListed = true;
        
        emit SkillListed(tokenId, price);
    }

    // Buy a skill NFT
    function buySkill(uint256 tokenId) public payable nonReentrant {
        Skill storage skill = idToSkill[tokenId];
        require(skill.isListed, "Skill is not listed for sale");
        require(msg.value == skill.price, "Please submit the correct price");
        require(skill.owner != msg.sender, "You already own this skill");

        address payable seller = skill.seller;
        skill.owner = payable(msg.sender);
        skill.isListed = false;
        _itemsSold.increment();

        // Transfer payment to seller
        (bool sent, ) = seller.call{value: msg.value}("");
        require(sent, "Failed to send payment");

        emit SkillSold(tokenId, seller, msg.sender, msg.value);
    }

    // Verify a skill (only owner can verify)
    function verifySkill(uint256 tokenId) public onlyOwner {
        require(idToSkill[tokenId].tokenId != 0, "Skill does not exist");
        idToSkill[tokenId].isVerified = true;
        
        emit SkillVerified(tokenId, true);
    }

    // Get all listed skills
    function getListedSkills() public view returns (Skill[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 1; i <= totalItemCount; i++) {
            if (idToSkill[i].isListed) {
                itemCount++;
            }
        }

        Skill[] memory items = new Skill[](itemCount);
        for (uint i = 1; i <= totalItemCount; i++) {
            if (idToSkill[i].isListed) {
                items[currentIndex] = idToSkill[i];
                currentIndex++;
            }
        }
        return items;
    }

    // Get skill details by token ID
    function getSkill(uint256 tokenId) public view returns (Skill memory) {
        return idToSkill[tokenId];
    }
}
