// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


contract PGAGEN is ERC721URIStorage { 
      uint256  platformFee = 10000;

    

    struct Nft {
        uint id;
        string name;
        string minted_url;
        uint price;
        bool onSale;
        bool onAuction;
        bool status;
        uint royalty;
        uint like;
        address feeRecipient;

    }

    Nft[] public NftCatalogue;

    function getNFTCount() public view returns(uint) {
        return NftCatalogue.length;
    }

    function getNFTPrice(uint _nftId) public view returns(uint) {
        return NftCatalogue[_nftId].price;
    }

    mapping(uint => address) public NftOwnership;
    mapping(address => uint) public tokenBalance;

    constructor() ERC721("PGAGEN", "PGA") {}

 
    event MintNftEvent(uint indexed nftId);

    event ConsensusNftEvent(uint indexed nftId);
    
    

   
    function mintNFT (
        string memory _name, 
        string memory _url, 
        uint _price, 
        bool _onSale, 
        uint _royalty, 
        bool _onAuction,
        uint _auctionType,
        uint256 _endAt,
        uint256 _startAt,
        uint256 _bidIncrement
        
       
    )
    public returns(uint) {
        uint like = 0;
        uint id = NftCatalogue.length;
       
        NftCatalogue.push(Nft(id, _name, _url, _price, _onSale, _onAuction, true, _royalty, like, msg.sender));
        _safeMint(msg.sender, id);
        _setTokenURI(id, _url);
        tokenBalance[msg.sender] += 1;
        NftOwnership[id] = msg.sender;
        if (_onAuction) {
            if (_auctionType == 0) {
                uint auctionId = createAuction(id, _bidIncrement, _endAt, _startAt);
                NftAuction[id] = auctionId;
            } 
           
            
        }

        emit MintNftEvent(id);
        return id;
    }

    // will be used for marketplace
    function getOnSaleTokens() public view returns(uint[] memory) {
        uint catalog_length = NftCatalogue.length;
        uint[] memory onSaleTokenIds = new uint[](catalog_length + 1);
        uint j = 0;
        for (uint i = 0; i < catalog_length; i ++) {
            if (NftCatalogue[i].onSale == true) {
                j = j + 1;
                onSaleTokenIds[j] = NftCatalogue[i].id;
            }
            // first positon will give the size of sale token
            onSaleTokenIds[0] = j;
        }

        return onSaleTokenIds;
    }

    function doLike(uint _id) public {
         NftCatalogue[_id].like  += 1;

    }

    function disLike(uint _id) public {
         NftCatalogue[_id].like  -= 1;
    }
    
   
    

    // will be used for my gallery
    function getUserNfts() public view returns(uint[] memory) {
        address owner = msg.sender;
        uint catalog_length = tokenBalance[owner];
        uint[] memory userNfts = new uint[](catalog_length);

        uint j = 0;
        for (uint i = 0; i < NftCatalogue.length; i ++) {
            if (NftOwnership[i] == owner) {
                userNfts[j] = i;
                j = j + 1;
            }
        }
        return userNfts;
    }

    

    function calculateRoyalty(uint256 _royalty, uint256 _price)
        public
        pure
        returns (uint256)
    {
        return (_price * _royalty) / 10000;
    }

    
        
      function sellNft(uint _nftId, uint _price )public  {
          NftCatalogue[_nftId].onSale = true;
          NftCatalogue[_nftId].price = _price;
      
      }

      function deactivateNft(uint _nftId )public  {
          NftCatalogue[_nftId].status = false;
      }

    function activateNft(uint _nftId, uint _price )public  {
          NftCatalogue[_nftId].status = true;
          NftCatalogue[_nftId].price = _price;
 }


       function consensusNft(uint _nftId) public payable { 
        // check if the function caller is not an zero account address
        require(msg.sender != address(0), "incorrect address");
        // check if the token id of the token being bought exists or not
        require(_exists(_nftId), "this token doesn't exist");
        // get the token's owner
        address tokenOwner = ownerOf(_nftId);
        // token's owner should not be an zero address account
        require(tokenOwner != address(0));
        // the one who wants to buy the token should not be the token's owner
        require(tokenOwner != msg.sender, "you cannot buy your own token");
        Nft memory nft = NftCatalogue[_nftId];
        require(nft.onSale, "Selected NFT not on sale");
        require(msg.value >= nft.price, "Incorrect amount of funds transfered");
       
        
       
        _sendFunds(NftOwnership[_nftId],  msg.value);
        transferFrom(NftOwnership[_nftId], msg.sender, _nftId);
        emit ConsensusNftEvent(_nftId);
    }

 

      function buyNft(uint _nftId) public payable { 
        // check if the function caller is not an zero account address
        require(msg.sender != address(0), "incorrect address");
        // check if the token id of the token being bought exists or not
        require(_exists(_nftId), "this token doesn't exist");
        // get the token's owner
        address tokenOwner = ownerOf(_nftId);
        // token's owner should not be an zero address account
        require(tokenOwner != address(0));
        // the one who wants to buy the token should not be the token's owner
        require(tokenOwner != msg.sender, "you cannot buy your own token");
        Nft memory nft = NftCatalogue[_nftId];
        require(nft.onSale, "Selected NFT not on sale");
        require(msg.value >= nft.price, "Incorrect amount of funds transfered");
        uint256 totalPrice = msg.value;
       
        uint platformFeeTotal = calculatePlatformFee(nft.price);
        
        _sendFunds(nft.feeRecipient, platformFeeTotal);
        _sendFunds(NftOwnership[_nftId],  totalPrice - platformFeeTotal);
        transferFrom(NftOwnership[_nftId], msg.sender, _nftId);
        emit ConsensusNftEvent(_nftId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public override {
        NftOwnership[_tokenId] = _to;
        tokenBalance[_from]--;
        tokenBalance[_to]++;
        NftCatalogue[_tokenId].onSale = false;
        // NftCatalogue[_tokenId].onAuction = false;
        _transfer(_from, _to, _tokenId);
    }

    function _sendFunds(address beneficiary, uint value) internal {
        address payable addr = payable(beneficiary);
        addr.transfer(value);
    }

     function calculatePlatformFee(uint256 _price)
        public
        view
        returns (uint256)
    {
        return (_price * 10) / 100;
    }




    enum AuctionStatus {
        Active,
        Cancelled,
        Completed
    }
    enum AuctionType {
        English,
        Dutch, 
        Blind
    }

    struct Auction {
        uint nft; // NFT ID
        address seller; // Current owner of NFT
        uint256 duration; // Block count for when the auction ends
        uint256 startBlock; // Block number when auction started
        uint256 startedAt; // Approximate time for when the auction was started
        AuctionType auctionType; // Type of Auction
        uint auctionTypeId; // Id of the given auction type
        bool cancelled; // Flag for cancelled auctions
    }

    struct EnglishAuction {
        mapping(address => uint256)fundsByBidder; // Mapping of addresses to funds
        uint256 highestBid; // Current highest bid
        address highestBidder; // Address of current highest bidder
        uint256 bidIncrement; // Minimum bid increment (in Wei)
    }



    uint totalAuctions;
    Auction[] public auctions;

    uint totalEnglishAuctions;
    EnglishAuction[] public englishAuctions;



    // mapping of NFT ID to Auction ID
    mapping(uint => uint) public NftAuction;


    event AuctionCreated(uint id, uint nftId);
    event AuctionSuccessful(uint256 id, uint nftId);
    event AuctionCancelled(uint256 id, uint nftId);
    event BidCreated(uint256 id, uint nftId, address bidder, uint256 bid);
    event AuctionNFTWithdrawal(uint256 id, uint nftId, address withdrawer);
    event AuctionFundWithdrawal(uint256 id, uint nftId, address withdrawer, uint256 amount);


    function getOnAuctionTokens() public view returns(uint[] memory) {
        uint catalog_length = NftCatalogue.length;
        uint[] memory onAuctionTokenIds = new uint[](catalog_length + 1);
        uint j = 0;
        for (uint i = 0; i < catalog_length; i ++) {
            if (NftCatalogue[i].onAuction == true) {
                j = j + 1;
                onAuctionTokenIds[j] = NftCatalogue[i].id;
            }
            // first positon will give the size of sale token
            onAuctionTokenIds[0] = j;
        }

        return onAuctionTokenIds;
    }

    function getAuctionsCount() public view returns(uint256) {
        return auctions.length;
    }

    // @dev Return type of auction for given auction ID
    function getAuctionType(uint256 _auctionId)
    external view returns(AuctionType) {
        Auction storage auction = auctions[_auctionId];
        return auction.auctionType;
    }



    function getAuction(uint256 _auctionId)
    external view returns(
        uint256 id, 
        uint nft, 
        address seller, 
        uint256 bidIncrement, 
        uint256 duration, 
        uint256 startedAt, 
        uint256 startBlock, 
        AuctionStatus status, 
        uint256 highestBid, 
        address highestBidder
    ) {
        Auction storage _auction = auctions[_auctionId];
        AuctionStatus _status = _getAuctionStatus(_auctionId);
        EnglishAuction storage _englishAuction = englishAuctions[_auction.auctionTypeId];

        return(_auctionId, _auction.nft, _auction.seller, _englishAuction.bidIncrement, _auction.duration, _auction.startedAt, _auction.startBlock, _status, _englishAuction.highestBid, _englishAuction.highestBidder);
    }

    // @dev Return bid for given auction ID and bidder
    function getBid(uint256 _auctionId, address bidder)
    external view returns(uint256) {
        Auction storage auction = auctions[_auctionId];
        EnglishAuction storage _englishAuction = englishAuctions[auction.auctionTypeId];
        return _englishAuction.fundsByBidder[bidder];
    }

    // @dev Return highest bid for given auction ID
    function getHighestBid(uint256 _auctionId)
    external view returns(uint256) {
        Auction storage auction = auctions[_auctionId];
        EnglishAuction storage _englishAuction = englishAuctions[auction.auctionTypeId];
        return _englishAuction.highestBid;
    }

    // @dev Creates and begins a new auction.
    // @_duration is in seconds and is converted to block count.
    function createAuction(uint _nft, uint256 _bidIncrement, uint256 _endAt, uint256 _startAt )
    private returns(uint256) { 
        // Require msg.sender to own nft
        require(NftOwnership[_nft] == msg.sender);

        // Require duration to be at least a minute and calculate block count
        require(_endAt >= 60);

        totalAuctions ++;

        Auction storage _auction = auctions.push();
        _auction.nft = _nft;
        _auction.seller = msg.sender;
        _auction.duration = _endAt;
        _auction.startedAt = block.timestamp;
        _auction.startBlock = block.number;
        _auction.cancelled = false;

        _auction.auctionType = AuctionType.English;
        _auction.auctionTypeId = totalEnglishAuctions;
        totalEnglishAuctions ++;
        EnglishAuction storage _englishAuction = englishAuctions.push();
        _englishAuction.bidIncrement = _bidIncrement;
        _englishAuction.highestBid = 0;
        _englishAuction.highestBidder = address(0);

        emit AuctionCreated(totalAuctions - 1, _nft);

        return totalAuctions - 1;
    }


    function bid(uint256 _auctionId)
    external payable statusIs(AuctionStatus.Active, _auctionId)
    returns(bool success) {
        require(msg.value > 0);

        Auction storage auction = auctions[_auctionId];
        EnglishAuction storage _englishAuction = englishAuctions[auction.auctionTypeId];
        uint nftPrice = getNFTPrice(auction.nft);

        uint256 newBid = _englishAuction.fundsByBidder[msg.sender] + msg.value;
        require(newBid >= nftPrice);
        require(newBid >= _englishAuction.highestBid + _englishAuction.bidIncrement);

        _englishAuction.highestBid = newBid;
        _englishAuction.highestBidder = msg.sender;
        _englishAuction.fundsByBidder[_englishAuction.highestBidder] = newBid;

        emit BidCreated(_auctionId, auction.nft, msg.sender, newBid);
        return true;
    }


    function withdrawBalance(uint256 _auctionId) external returns(bool success) {
        AuctionStatus _status = _getAuctionStatus(_auctionId);

        Auction storage auction = auctions[_auctionId];
        EnglishAuction storage _englishAuction = englishAuctions[auction.auctionTypeId];
        address fundsFrom;
        uint withdrawalAmount;

        if (msg.sender == auction.seller) {
            require(_status == AuctionStatus.Completed, "Please wait for the auction to complete");
            fundsFrom = _englishAuction.highestBidder;
            withdrawalAmount = _englishAuction.highestBid;
        }
        // Highest bidder can only withdraw the NFT when the auction is completed.
        // When the auction is cancelled, the highestBidder is set to address(0). 
        else if (msg.sender == _englishAuction.highestBidder) {
            require(_status == AuctionStatus.Completed, "You are the highest bidder and cannot withdraw your amount");
            transferFrom(auction.seller, _englishAuction.highestBidder, auction.nft);
            emit AuctionNFTWithdrawal(_auctionId, auction.nft, msg.sender);
            return true;
        }
        // Anyone else gets what they bid 
        else {
            fundsFrom = msg.sender;
            withdrawalAmount = _englishAuction.fundsByBidder[fundsFrom];
        }

        require(withdrawalAmount > 0);
        _englishAuction.fundsByBidder[fundsFrom] -= withdrawalAmount;
        _sendFunds(msg.sender, withdrawalAmount);

        emit AuctionFundWithdrawal(_auctionId, auction.nft, msg.sender, withdrawalAmount);

        return true;
    }


    function _getAuctionStatus(uint256 _auctionId)
    internal view returns(AuctionStatus) {
        Auction storage auction = auctions[_auctionId];

        if (auction.cancelled) {
            return AuctionStatus.Cancelled;
        } else if (auction.startedAt + auction.duration < block.timestamp) {
            return AuctionStatus.Completed;
        } else {
            return AuctionStatus.Active;
        }
    }


    modifier statusIs(AuctionStatus expectedStatus, uint256 _auctionId) {
        require(expectedStatus == _getAuctionStatus(_auctionId));
        _;
    }

    modifier onlySeller(uint256 _auctionId) {
        Auction storage auction = auctions[_auctionId];
        require(msg.sender == auction.seller);
        _;
    }

    function cancelAuction(uint256 _auctionId) external {
        _cancelAuction(_auctionId);
    }


    // @dev Cancels an auction unconditionally.
    function _cancelAuction(uint256 _auctionId)
    internal statusIs(AuctionStatus.Active, _auctionId)
    onlySeller(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        EnglishAuction storage _englishAuction = englishAuctions[auction.auctionTypeId];
        auction.cancelled = true;
        _englishAuction.highestBidder = address(0);

        emit AuctionCancelled(_auctionId, auction.nft);
    }
    
    

}

