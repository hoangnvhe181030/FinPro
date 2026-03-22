package com.ex.auction.service;

import com.ex.auction.domain.entity.ChatMessage;
import com.ex.auction.domain.entity.User;
import com.ex.auction.repository.ChatMessageRepository;
import com.ex.auction.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@Transactional
@RequiredArgsConstructor
@Slf4j
public class ChatService {

    private final ChatMessageRepository chatMessageRepository;
    private final UserRepository userRepository;
    private final SimpMessagingTemplate messagingTemplate;

    /**
     * Send a message and broadcast via WebSocket
     */
    public Map<String, Object> sendMessage(Long senderId, Long receiverId, String content) {
        log.info("Chat: {} -> {}: {}", senderId, receiverId, content);

        User sender = userRepository.findById(senderId)
                .orElseThrow(() -> new RuntimeException("Sender not found: " + senderId));
        User receiver = userRepository.findById(receiverId)
                .orElseThrow(() -> new RuntimeException("Receiver not found: " + receiverId));

        ChatMessage message = ChatMessage.builder()
                .sender(sender)
                .receiver(receiver)
                .content(content)
                .build();

        message = chatMessageRepository.save(message);

        Map<String, Object> messageData = toMessageMap(message);

        // Broadcast to receiver via WebSocket
        messagingTemplate.convertAndSend(
                "/queue/chat/" + receiverId,
                messageData
        );

        // Also send back to sender for confirmation
        messagingTemplate.convertAndSend(
                "/queue/chat/" + senderId,
                messageData
        );

        log.info("Chat message sent: messageId={}", message.getMessageId());
        return messageData;
    }

    /**
     * Get conversation between two users
     */
    @Transactional(readOnly = true)
    public List<Map<String, Object>> getConversation(Long userId1, Long userId2) {
        List<ChatMessage> messages = chatMessageRepository.findConversation(userId1, userId2);
        return messages.stream().map(this::toMessageMap).collect(Collectors.toList());
    }

    /**
     * Get chat list (latest message per conversation) for a user
     */
    @Transactional(readOnly = true)
    public List<Map<String, Object>> getChatList(Long userId) {
        List<ChatMessage> latestMessages = chatMessageRepository.findLatestMessagePerConversation(userId);

        return latestMessages.stream().map(msg -> {
            Map<String, Object> map = toMessageMap(msg);

            // Determine the "other" user in the conversation
            Long otherUserId = msg.getSender().getUserId().equals(userId)
                    ? msg.getReceiver().getUserId()
                    : msg.getSender().getUserId();
            String otherUsername = msg.getSender().getUserId().equals(userId)
                    ? msg.getReceiver().getUsername()
                    : msg.getSender().getUsername();
            String otherFullName = msg.getSender().getUserId().equals(userId)
                    ? msg.getReceiver().getFullName()
                    : msg.getSender().getFullName();

            map.put("otherUserId", otherUserId);
            map.put("otherUsername", otherUsername);
            map.put("otherFullName", otherFullName);

            // Unread count from this user
            long unreadCount = chatMessageRepository.countUnreadFromUser(otherUserId, userId);
            map.put("unreadCount", unreadCount);

            return map;
        }).collect(Collectors.toList());
    }

    /**
     * Mark messages from a sender as read
     */
    public void markAsRead(Long senderId, Long receiverId) {
        chatMessageRepository.markAsRead(senderId, receiverId);
        log.info("Marked messages as read: {} -> {}", senderId, receiverId);
    }

    /**
     * Get all users (for starting new conversation)
     */
    @Transactional(readOnly = true)
    public List<Map<String, Object>> getAllUsers(Long excludeUserId) {
        return userRepository.findAll().stream()
                .filter(u -> !u.getUserId().equals(excludeUserId))
                .map(u -> {
                    Map<String, Object> map = new HashMap<>();
                    map.put("userId", u.getUserId());
                    map.put("username", u.getUsername());
                    map.put("fullName", u.getFullName());
                    return map;
                })
                .collect(Collectors.toList());
    }

    /**
     * Get total unread count for a user
     */
    @Transactional(readOnly = true)
    public long getUnreadCount(Long userId) {
        return chatMessageRepository.countUnreadMessages(userId);
    }

    private Map<String, Object> toMessageMap(ChatMessage msg) {
        Map<String, Object> map = new HashMap<>();
        map.put("messageId", msg.getMessageId());
        map.put("senderId", msg.getSender().getUserId());
        map.put("senderName", msg.getSender().getUsername());
        map.put("receiverId", msg.getReceiver().getUserId());
        map.put("receiverName", msg.getReceiver().getUsername());
        map.put("content", msg.getContent());
        map.put("isRead", msg.isReadStatus());
        map.put("createdAt", msg.getCreatedAt().toString());
        return map;
    }
}
