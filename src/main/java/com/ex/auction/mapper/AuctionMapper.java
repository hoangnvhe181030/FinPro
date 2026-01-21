package com.ex.auction.mapper;

import com.ex.auction.domain.entity.Auction;
import com.ex.auction.domain.entity.Bid;
import com.ex.auction.dto.AuctionResponse;
import com.ex.auction.dto.BidResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface AuctionMapper {

    @Mapping(source = "auctionId", target = "id")
    @Mapping(source = "product.productName", target = "productName")
    @Mapping(source = "seller.username", target = "sellerName")
    AuctionResponse toAuctionResponse(Auction auction);

    @Mapping(source = "bidId", target = "id")
    @Mapping(source = "auction.auctionId", target = "auctionId")
    @Mapping(source = "user.username", target = "username")
    @Mapping(source = "bidAmount", target = "amount")
    @Mapping(source = "bidStatus", target = "status")
    @Mapping(source = "bidTime", target = "time")
    BidResponse toBidResponse(Bid bid);
}
