package com.ex.auction.repository;

import com.ex.auction.domain.entity.Outbox;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OutboxRepository extends JpaRepository<Outbox, Long> {
    
    List<Outbox> findByPublishedFalseOrderByCreatedAtAsc();
    
    List<Outbox> findByAggregateTypeAndAggregateId(String aggregateType, Long aggregateId);
}
