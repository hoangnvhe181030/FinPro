package com.ex.auction.controller;

import com.ex.auction.service.ChatService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/chat")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class ChatController {

    private final ChatService chatService;

    /**
     * WebSocket endpoint: /app/chat.send
     * Client sends message via STOMP, server broadcasts to receiver
     */
    @MessageMapping("/chat.send")
    public void sendMessageWS(@Payload Map<String, Object> payload) {
        Long senderId = ((Number) payload.get("senderId")).longValue();
        Long receiverId = ((Number) payload.get("receiverId")).longValue();
        String content = (String) payload.get("content");

        chatService.sendMessage(senderId, receiverId, content);
    }

    /**
     * POST /api/chat/send - Send message via REST (fallback)
     */
    @PostMapping("/send")
    public ResponseEntity<Map<String, Object>> sendMessage(@RequestBody Map<String, Object> request) {
        Long senderId = ((Number) request.get("senderId")).longValue();
        Long receiverId = ((Number) request.get("receiverId")).longValue();
        String content = (String) request.get("content");

        log.info("POST /api/chat/send - {} -> {}", senderId, receiverId);

        Map<String, Object> message = chatService.sendMessage(senderId, receiverId, content);
        return ResponseEntity.ok(message);
    }

    /**
     * GET /api/chat/conversations/{userId} - Get chat list for a user
     */
    @GetMapping("/conversations/{userId}")
    public ResponseEntity<List<Map<String, Object>>> getChatList(@PathVariable Long userId) {
        log.info("GET /api/chat/conversations/{}", userId);
        return ResponseEntity.ok(chatService.getChatList(userId));
    }

    /**
     * GET /api/chat/messages/{userId1}/{userId2} - Get conversation between two users
     */
    @GetMapping("/messages/{userId1}/{userId2}")
    public ResponseEntity<List<Map<String, Object>>> getConversation(
            @PathVariable Long userId1, @PathVariable Long userId2) {
        log.info("GET /api/chat/messages/{}/{}", userId1, userId2);
        return ResponseEntity.ok(chatService.getConversation(userId1, userId2));
    }

    /**
     * POST /api/chat/read - Mark messages as read
     */
    @PostMapping("/read")
    public ResponseEntity<Map<String, String>> markAsRead(@RequestBody Map<String, Object> request) {
        Long senderId = ((Number) request.get("senderId")).longValue();
        Long receiverId = ((Number) request.get("receiverId")).longValue();

        chatService.markAsRead(senderId, receiverId);

        return ResponseEntity.ok(Map.of("status", "ok"));
    }

    /**
     * GET /api/chat/users/{userId} - Get all users for new conversation
     */
    @GetMapping("/users/{userId}")
    public ResponseEntity<List<Map<String, Object>>> getUsers(@PathVariable Long userId) {
        log.info("GET /api/chat/users/{}", userId);
        return ResponseEntity.ok(chatService.getAllUsers(userId));
    }

    /**
     * GET /api/chat/unread/{userId} - Get unread message count
     */
    @GetMapping("/unread/{userId}")
    public ResponseEntity<Map<String, Object>> getUnreadCount(@PathVariable Long userId) {
        long count = chatService.getUnreadCount(userId);
        return ResponseEntity.ok(Map.of("unreadCount", count));
    }
}
