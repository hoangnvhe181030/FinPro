package com.ex.auction.domain.entity;

import com.ex.auction.domain.enums.BidEventType;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "bid_events")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BidEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "event_id")
    private Long eventId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "bid_id", nullable = false)
    private Bid bid;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "auction_id", nullable = false)
    private Auction auction;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(name = "event_type", nullable = false, length = 50)
    private BidEventType eventType;

    @Lob
    @Column(name = "event_data")
    private String eventData;

    @Column(name = "event_time", nullable = false)
    private LocalDateTime eventTime;

    @Column(name = "processed", columnDefinition = "CHAR(1)")
    @Builder.Default
    private String processed = "N";

    @PrePersist
    protected void onCreate() {
        if (eventTime == null) {
            eventTime = LocalDateTime.now();
        }
    }
}
