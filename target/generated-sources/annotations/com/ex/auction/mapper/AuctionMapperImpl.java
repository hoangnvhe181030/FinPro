package com.ex.auction.mapper;

import com.ex.auction.domain.entity.Auction;
import com.ex.auction.domain.entity.Bid;
import com.ex.auction.domain.entity.Product;
import com.ex.auction.domain.entity.User;
import com.ex.auction.dto.AuctionResponse;
import com.ex.auction.dto.BidResponse;
import javax.annotation.processing.Generated;
import org.springframework.stereotype.Component;

@Generated(
    value = "org.mapstruct.ap.MappingProcessor",
    date = "2026-03-11T14:40:26+0700",
    comments = "version: 1.5.5.Final, compiler: javac, environment: Java 17.0.12 (Oracle Corporation)"
)
@Component
public class AuctionMapperImpl implements AuctionMapper {

    @Override
    public AuctionResponse toAuctionResponse(Auction auction) {
        if ( auction == null ) {
            return null;
        }

        AuctionResponse.AuctionResponseBuilder auctionResponse = AuctionResponse.builder();

        auctionResponse.id( auction.getAuctionId() );
        auctionResponse.productName( auctionProductProductName( auction ) );
        auctionResponse.sellerName( auctionSellerUsername( auction ) );
        auctionResponse.currentPrice( auction.getCurrentPrice() );
        auctionResponse.startingPrice( auction.getStartingPrice() );
        auctionResponse.bidIncrement( auction.getBidIncrement() );
        auctionResponse.startTime( auction.getStartTime() );
        auctionResponse.endTime( auction.getEndTime() );
        auctionResponse.originalEndTime( auction.getOriginalEndTime() );
        auctionResponse.status( auction.getStatus() );
        auctionResponse.totalBids( auction.getTotalBids() );

        return auctionResponse.build();
    }

    @Override
    public BidResponse toBidResponse(Bid bid) {
        if ( bid == null ) {
            return null;
        }

        BidResponse.BidResponseBuilder bidResponse = BidResponse.builder();

        bidResponse.id( bid.getBidId() );
        bidResponse.auctionId( bidAuctionAuctionId( bid ) );
        bidResponse.username( bidUserUsername( bid ) );
        bidResponse.amount( bid.getBidAmount() );
        bidResponse.status( bid.getBidStatus() );
        bidResponse.time( bid.getBidTime() );

        return bidResponse.build();
    }

    private String auctionProductProductName(Auction auction) {
        if ( auction == null ) {
            return null;
        }
        Product product = auction.getProduct();
        if ( product == null ) {
            return null;
        }
        String productName = product.getProductName();
        if ( productName == null ) {
            return null;
        }
        return productName;
    }

    private String auctionSellerUsername(Auction auction) {
        if ( auction == null ) {
            return null;
        }
        User seller = auction.getSeller();
        if ( seller == null ) {
            return null;
        }
        String username = seller.getUsername();
        if ( username == null ) {
            return null;
        }
        return username;
    }

    private Long bidAuctionAuctionId(Bid bid) {
        if ( bid == null ) {
            return null;
        }
        Auction auction = bid.getAuction();
        if ( auction == null ) {
            return null;
        }
        Long auctionId = auction.getAuctionId();
        if ( auctionId == null ) {
            return null;
        }
        return auctionId;
    }

    private String bidUserUsername(Bid bid) {
        if ( bid == null ) {
            return null;
        }
        User user = bid.getUser();
        if ( user == null ) {
            return null;
        }
        String username = user.getUsername();
        if ( username == null ) {
            return null;
        }
        return username;
    }
}
