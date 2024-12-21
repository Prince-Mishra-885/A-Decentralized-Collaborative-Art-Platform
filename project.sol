// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CollaborativeArt {
    struct Artwork {
        uint256 id;
        string title;
        string description;
        address creator;
        uint256 rewardPool;
        uint256 contributionCount;
        bool isComplete;
    }

    struct Contribution {
        address contributor;
        string content;
        uint256 timestamp;
    }

    uint256 public artworkCounter;
    mapping(uint256 => Artwork) public artworks;
    mapping(uint256 => Contribution[]) public contributions;
    mapping(address => uint256) public balances;

    event ArtworkCreated(uint256 id, string title, address creator);
    event ContributionAdded(uint256 artworkId, address contributor);
    event RewardsClaimed(address contributor, uint256 amount);

    modifier onlyCreator(uint256 artworkId) {
        require(msg.sender == artworks[artworkId].creator, "Only the creator can perform this action");
        _;
    }

    function createArtwork(string memory _title, string memory _description) public payable {
        require(msg.value > 0, "Reward pool must be greater than 0");

        artworkCounter++;
        artworks[artworkCounter] = Artwork({
            id: artworkCounter,
            title: _title,
            description: _description,
            creator: msg.sender,
            rewardPool: msg.value,
            contributionCount: 0,
            isComplete: false
        });

        emit ArtworkCreated(artworkCounter, _title, msg.sender);
    }

    function addContribution(uint256 _artworkId, string memory _content) public {
        Artwork storage artwork = artworks[_artworkId];
        require(!artwork.isComplete, "Artwork is already complete");

        contributions[_artworkId].push(Contribution({
            contributor: msg.sender,
            content: _content,
            timestamp: block.timestamp
        }));

        artwork.contributionCount++;

        emit ContributionAdded(_artworkId, msg.sender);
    }

    function markComplete(uint256 _artworkId) public onlyCreator(_artworkId) {
        Artwork storage artwork = artworks[_artworkId];
        require(!artwork.isComplete, "Artwork is already complete");
        require(artwork.contributionCount > 0, "No contributions to finalize");

        artwork.isComplete = true;

        uint256 rewardPerContribution = artwork.rewardPool / artwork.contributionCount;

        for (uint256 i = 0; i < contributions[_artworkId].length; i++) {
            address contributor = contributions[_artworkId][i].contributor;
            balances[contributor] += rewardPerContribution;
        }
    }

    function claimRewards() public {
        uint256 reward = balances[msg.sender];
        require(reward > 0, "No rewards to claim");

        balances[msg.sender] = 0;
        payable(msg.sender).transfer(reward);

        emit RewardsClaimed(msg.sender, reward);
    }

    function getContributions(uint256 _artworkId) public view returns (Contribution[] memory) {
        return contributions[_artworkId];
    }
}  
