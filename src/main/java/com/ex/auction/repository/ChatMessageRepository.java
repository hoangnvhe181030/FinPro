package com.ex.auction.repository;

import com.ex.auction.domain.entity.ChatMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {

    /**
     * Get conversation between two users, ordered by time
     */
    @Query("SELECT m FROM ChatMessage m WHERE " +
            "(m.sender.userId = :userId1 AND m.receiver.userId = :userId2) OR " +
            "(m.sender.userId = :userId2 AND m.receiver.userId = :userId1) " +
            "ORDER BY m.createdAt ASC")
    List<ChatMessage> findConversation(@Param("userId1") Long userId1, @Param("userId2") Long userId2);

    /**
     * Get last message of each conversation for a user (for chat list)
     */
    @Query(value = "SELECT * FROM (" +
            "SELECT cm.*, ROW_NUMBER() OVER (" +
            "PARTITION BY LEAST(cm.sender_id, cm.receiver_id), GREATEST(cm.sender_id, cm.receiver_id) " +
            "ORDER BY cm.created_at DESC) rn " +
            "FROM chat_messages cm " +
            "WHERE cm.sender_id = :userId OR cm.receiver_id = :userId" +
            ") WHERE rn = 1 ORDER BY created_at DESC",
            nativeQuery = true)
    List<ChatMessage> findLatestMessagePerConversation(@Param("userId") Long userId);

    /**
     * Count unread messages for a user
     */
    @Query("SELECT COUNT(m) FROM ChatMessage m WHERE m.receiver.userId = :userId AND m.isRead = 'N'")
    long countUnreadMessages(@Param("userId") Long userId);

    /**
     * Count unread messages from a specific sender
     */
    @Query("SELECT COUNT(m) FROM ChatMessage m WHERE m.sender.userId = :senderId AND m.receiver.userId = :receiverId AND m.isRead = 'N'")
    long countUnreadFromUser(@Param("senderId") Long senderId, @Param("receiverId") Long receiverId);

    /**
     * Mark messages as read
     */
    @Modifying
    @Query("UPDATE ChatMessage m SET m.isRead = 'Y' WHERE m.sender.userId = :senderId AND m.receiver.userId = :receiverId AND m.isRead = 'N'")
    void markAsRead(@Param("senderId") Long senderId, @Param("receiverId") Long receiverId);
}
