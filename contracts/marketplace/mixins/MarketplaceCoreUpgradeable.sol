// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../../ERC20/interfaces/IERC20ExtendedUpgradeable.sol";
import "./MarketplaceFundDistributorUpgradeable.sol";
import "./MarketplaceAuctionConfigUpgradeable.sol";
import "./MarketplaceBidTokensUpgradeable.sol";
import "./MarketplaceCounterUpgradable.sol";
import "../libraries/ArraysUpgradeable.sol";

abstract contract MarketplaceCoreUpgradeable is
Initializable, AccessControlEnumerableUpgradeable, ReentrancyGuardUpgradeable, MarketplaceCounterUpgradable,
MarketplaceBidTokensUpgradeable, MarketplaceFundDistributorUpgradeable, MarketplaceAuctionConfigUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using SafeERC20Upgradeable for IERC20ExtendedUpgradeable;
    using ArraysUpgradeable for uint256[];
    using AddressUpgradeable for address;

    enum SaleType {
        AUCTION,
        FIXED,
        OFFER
    }

    enum TokenType {
        ERC721,
        ERC1155
    }

    struct Sale {
        SaleType saleType;
        address seller;
        address contractAddress;
        TokenType tokenType;
        uint256[] tokenIds;
        uint256[] values;
        address bidToken;
        uint256 startTime;
        uint256 duration;
        uint256 extensionDuration;
        uint256 endTime;
        address bidder;
        uint256 bidAmount;
    }

    mapping(uint256 => Sale) internal _sales;
    EnumerableSetUpgradeable.UintSet private _saleIds;

    event SaleCreated(
        uint256 indexed saleId,
        SaleType saleType,
        address indexed seller,
        address indexed contractAddress,
        uint256[] tokenIds,
        uint256[] values,
        address bidToken,
        uint256 startTime,
        uint256 duration,
        uint256 extensionDuration,
        uint256 endTime,
        uint256 minPrice
    );

    event SaleCanceled(
        uint256 indexed saleId,
        string reason
    );

    event BidPlaced(
        uint256 indexed saleId,
        address bidder,
        uint256 bidAbount,
        uint256 endTime
    );

    event AuctionFinalized(
        uint256 indexed saleId,
        address indexed seller,
        address indexed bidder,
        uint256 royalty,
        uint256 fee,
        uint256 revenue
    );

    event FixedPriceFinalized(
        uint256 indexed saleId,
        address indexed seller,
        address indexed buyer,
        uint256 royalty,
        uint256 fee,
        uint256 revenue
    );

    event OfferFinalized(
        uint256 indexed saleId,
        address indexed seller,
        address indexed buyer,
        uint256 royalty,
        uint256 fee,
        uint256 revenue
    );

    function __MarketplaceCore_init(
        uint256 maxRoyaltyBps,
        uint256 marketFeeBps,
        uint256 marketFeeBurnedBps,
        uint256 marketFeeReflectedBps,
        address treasury,
        address bank,
        uint256 nexBidPercentBps
    ) internal onlyInitializing {
        __AccessControlEnumerable_init();
        __ReentrancyGuard_init();
        __MarketplaceBidTokens_init();
        __MarketplaceFundDistributor_init(
            maxRoyaltyBps,
            marketFeeBps,
            marketFeeBurnedBps,
            marketFeeReflectedBps,
            treasury,
            bank
        );
        __MarketplaceAuctionConfig_init(nexBidPercentBps);

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());
        _grantRole(UPDATER_ROLE, _msgSender());
    }

    function _transferAssets(
        TokenType tokenType,
        address contractAddress,
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory values
    ) private {
        if (tokenType == TokenType.ERC1155) {
            IERC1155Upgradeable(contractAddress).safeBatchTransferFrom(from, to, tokenIds, values, "");
        } else if (tokenType == TokenType.ERC721) {
            IERC721Upgradeable asset = IERC721Upgradeable(contractAddress);
            for (uint256 i = 0; i < tokenIds.length; ++i) {
                asset.transferFrom(from, to, tokenIds[i]);
            }
        }
    }

    function _makeSaleInfo(
        SaleType saleType,
        address contractAddress,
        TokenType tokenType,
        uint256[] memory tokenIds,
        uint256[] memory values,
        address bidToken,
        uint256 startTime,
        uint256 duration,
        uint256 minPrice
    ) internal view returns (Sale memory) {
        require(tokenIds.length > 0, "MarketplaceCoreUpgradeable: Invalid tokenIds length");
        require(tokenIds.length == values.length, "MarketplaceCoreUpgradeable: TokenIds length dont match");
        require(isValidBidToken(contractAddress, bidToken), "MarketplaceCoreUpgradeable: Invalid bid token");
        require(values.gte(1), "MarketplaceCoreUpgradeable: Invalid value");
        require(startTime >= block.timestamp, "MarketplaceCoreUpgradeable: Invalid startTime");
        require(duration > 0, "MarketplaceCoreUpgradeable: Invalid duration");
        require(minPrice >= 0, "MarketplaceCoreUpgradeable: Invalid minPrice");

        return Sale(
            saleType,
            _msgSender(),
            contractAddress,
            tokenType,
            tokenIds,
            values,
            bidToken,
            startTime,
            duration,
            extensionSeconds,
            startTime + duration,
            address(0),
            minPrice
        );
    }

    function _createSale(Sale memory sale, uint256 royaltyPercent) internal {
        if (royaltyPercent > 0) {
            setRoyaltyFor(_msgSender(), sale.contractAddress, sale.tokenIds[0], royaltyPercent);
        }

        uint256 saleId = _getSaleId();
        _sales[saleId] = sale;

        _transferAssets(sale.tokenType, sale.contractAddress, _msgSender(), address(this), sale.tokenIds, sale.values);

        emit SaleCreated(
            saleId,
            sale.saleType,
            sale.seller,
            sale.contractAddress,
            sale.tokenIds,
            sale.values,
            sale.bidToken,
            sale.startTime,
            sale.duration,
            extensionSeconds,
            sale.startTime + sale.duration,
            sale.bidAmount
        );
    }

    function cancelSale(uint256 saleId, string memory reason) external nonReentrant {
        require(bytes(reason).length > 0, "MarketplaceCoreUpgradeable: Include a reason for this cancellation");

        Sale memory sale = _sales[saleId];

        require(sale.seller == _msgSender(), "MarketplaceCoreUpgradeable: Not your sale");

        delete _sales[saleId];

        _transferAssets(sale.tokenType, sale.contractAddress, address(this), sale.seller, sale.tokenIds, sale.values);
        if (sale.bidder != address(0)) {
            IERC20ExtendedUpgradeable(sale.bidToken).safeTransfer(sale.bidder, sale.bidAmount);
        }

        emit SaleCanceled(saleId, reason);
    }

    function cancelSaleByAdmin(uint256 saleId, string memory reason) external nonReentrant onlyRole(UPDATER_ROLE) {
        require(bytes(reason).length > 0, "MarketplaceCoreUpgradeable: Include a reason for this cancellation");

        Sale memory sale = _sales[saleId];

        require(sale.endTime > 0, "MarketplaceCoreUpgradeable: Sale not found");

        delete _sales[saleId];

        _transferAssets(sale.tokenType, sale.contractAddress, address(this), sale.seller, sale.tokenIds, sale.values);
        if (sale.bidder != address(0)) {
            IERC20ExtendedUpgradeable(sale.bidToken).safeTransfer(sale.bidder, sale.bidAmount);
        }

        emit SaleCanceled(saleId, reason);
    }

    function getAuctionMinBidAmount(uint256 saleId) external view returns (uint256) {
        Sale storage sale = _sales[saleId];
        if (sale.bidder == address(0)) {
            return sale.bidAmount;
        }
        return _getNextBidAmount(sale.bidAmount);
    }

    function bidAuction(uint256 saleId, uint256 bidAmount) external nonReentrant {
        Sale storage sale = _sales[saleId];

        require(sale.saleType == SaleType.AUCTION, "MarketplaceCoreUpgradeable: Not Auction");
        require(sale.endTime > block.timestamp, "MarketplaceCoreUpgradeable: Sale is over");
        require(sale.startTime <= block.timestamp, "MarketplaceCoreUpgradeable: Sale not started");
        require(sale.bidder != _msgSender(), "MarketplaceCoreUpgradeable: You already are current bidder");
        require(sale.seller != _msgSender(), "MarketplaceCoreUpgradeable: Self bid");

        if (sale.bidder == address(0)) {
            require(sale.bidAmount <= bidAmount, "MarketplaceCoreUpgradeable: Bid amount too low");
        } else {
            uint256 minAmount = _getNextBidAmount(sale.bidAmount);
            require(bidAmount >= minAmount, "MarketplaceCoreUpgradeable: Bid amount too low");
        }

        uint256 prevBidAmount = sale.bidAmount;
        address prevBidder = sale.bidder;
        sale.bidAmount = bidAmount;
        sale.bidder = _msgSender();

        if (sale.endTime - block.timestamp < sale.extensionDuration) {
            sale.endTime = block.timestamp + sale.extensionDuration;
        }

        IERC20ExtendedUpgradeable bidToken = IERC20ExtendedUpgradeable(sale.bidToken);
        bidToken.safeTransferFrom(_msgSender(), address(this), bidAmount);
        if (prevBidder != address(0)){
            bidToken.safeTransfer(prevBidder, prevBidAmount);
        }

        emit BidPlaced(saleId, _msgSender(), bidAmount, sale.endTime);
    }

    function finalizeAuction(uint256 saleId) external nonReentrant {
        Sale memory sale = _sales[saleId];

        require(sale.endTime > 0, "MarketplaceCoreUpgradeable: Auction not found");
        require(sale.endTime < block.timestamp, "MarketplaceCoreUpgradeable: Auction still in progress");

        delete _sales[saleId];

        _transferAssets(sale.tokenType, sale.contractAddress, address(this), sale.bidder, sale.tokenIds, sale.values);

        (uint256 royalty, uint256 marketFee, uint256 sellerRev) = _distributeFunds(
            sale.contractAddress, sale.tokenIds[0], sale.bidToken, sale.seller, sale.bidAmount
        );

        emit AuctionFinalized(saleId, sale.seller, sale.bidder, royalty, marketFee, sellerRev);
    }

    function buyFixedPrice(uint256 saleId, uint256 buyAmount) external nonReentrant {
        Sale memory sale = _sales[saleId];

        require(sale.saleType == SaleType.FIXED, "MarketplaceCoreUpgradeable: Not Fixed-price");
        require(sale.endTime >= block.timestamp, "MarketplaceCoreUpgradeable: Sale is over");
        require(sale.startTime <= block.timestamp, "MarketplaceCoreUpgradeable: Sale not started");
        require(sale.bidAmount == buyAmount, "MarketplaceCoreUpgradeable: Wrong buy amount");
        require(sale.seller != _msgSender(), "MarketplaceCoreUpgradeable: Self buy");

        delete _sales[saleId];

        address from = _msgSender();

        IERC20ExtendedUpgradeable(sale.bidToken).safeTransferFrom(_msgSender(), address(this), sale.bidAmount);
        _transferAssets(sale.tokenType, sale.contractAddress, address(this), from, sale.tokenIds, sale.values);

        (uint256 royalty, uint256 marketFee, uint256 sellerRev) = _distributeFunds(
            sale.contractAddress, sale.tokenIds[0], sale.bidToken, sale.seller, sale.bidAmount
        );

        emit FixedPriceFinalized(saleId, sale.seller, from, royalty, marketFee, sellerRev);
    }

    function _checkSelfOffer(address contractAddress, uint256[] memory tokenIds) private view returns (bool) {
        if  (_msgSender() == IERC721Upgradeable(contractAddress).ownerOf(tokenIds[0])) {
            return false;
        }
        return true;
    }

    function _makeOfferInfo(
        address contractAddress, TokenType tokenType, uint256[] memory tokenIds, uint256[] memory values, address bidToken,
        uint256 duration, uint256 price
    ) internal view returns (Sale memory) {
        require(tokenIds.length > 0, "MarketplaceCoreUpgradeable: Invalid tokenIds length");
        require(tokenIds.length == values.length, "MarketplaceCoreUpgradeable: TokenIds length dont match");
        require(isValidBidToken(contractAddress, bidToken), "MarketplaceCoreUpgradeable: Invalid bid token");
        require(values.gte(1), "MarketplaceCoreUpgradeable: Invalid value");
        require(duration > 0, "MarketplaceCoreUpgradeable: Invalid duration");
        require(price >= 0, "MarketplaceCoreUpgradeable: Invalid price");
        require(_checkSelfOffer(contractAddress, tokenIds), "MarketplaceCoreUpgradeable: Self offer");

        uint256 startTime = block.timestamp;
        return Sale(
            SaleType.OFFER,
            address(0),
            contractAddress,
            tokenType,
            tokenIds,
            values,
            bidToken,
            startTime,
            duration,
            extensionSeconds,
            startTime + duration,
            _msgSender(),
            price
        );
    }

    function _createOffer(
        Sale memory sale
    ) internal {
        uint256 saleId = _getSaleId();
        _sales[saleId] = sale;

        IERC20ExtendedUpgradeable IbidToken = IERC20ExtendedUpgradeable(sale.bidToken);
        IbidToken.safeTransferFrom(_msgSender(), address(this), sale.bidAmount);

        emit SaleCreated(
            saleId,
            SaleType.OFFER,
            sale.bidder,
            sale.contractAddress,
            sale.tokenIds,
            sale.values,
            sale.bidToken,
            sale.startTime,
            sale.duration,
            extensionSeconds,
            sale.startTime + sale.duration,
            sale.bidAmount
        );
    }

    function cancelOffer(uint256 saleId) external nonReentrant {
        Sale memory sale = _sales[saleId];

        require(sale.saleType == SaleType.OFFER, "MarketplaceCoreUpgradeable: Not offer");
        require(sale.bidder == _msgSender(), "MarketplaceCoreUpgradeable: Not your offer");

        delete _sales[saleId];

        IERC20ExtendedUpgradeable(sale.bidToken).safeTransfer(sale.bidder, sale.bidAmount);

        emit SaleCanceled(saleId, "");
    }

    function acceptOffer(uint256 saleId) external nonReentrant {
        Sale memory sale = _sales[saleId];

        require(sale.saleType == SaleType.OFFER, "MarketplaceCoreUpgradeable: Not offer");
        require(sale.endTime <= block.timestamp, "MarketplaceCoreUpgradeable: Offer is over");

        delete _sales[saleId];

        _transferAssets(sale.tokenType, sale.contractAddress, _msgSender(), sale.bidder, sale.tokenIds, sale.values);

        (uint256 royalty, uint256 marketFee, uint256 sellerRev) = _distributeFunds(
            sale.contractAddress, sale.tokenIds[0], sale.bidToken, _msgSender(), sale.bidAmount
        );

        emit OfferFinalized(saleId, sale.seller, sale.bidder, royalty, marketFee, sellerRev);
    }

    function activeSaleIds() public view returns (uint256[] memory) {
        return _saleIds.values();
    }

    function activeSales() public view returns (Sale[] memory) {
        uint256[] memory saleIds = _saleIds.values();
        Sale[] memory sales = new Sale[](saleIds.length);
        for (uint256 i = 0; i < saleIds.length; i++) {
            sales[i] = _sales[saleIds[i]];
        }
        return sales;
    }

    uint256[49] private __gap;
}