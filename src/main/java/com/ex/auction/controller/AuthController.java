package com.ex.auction.controller;

import com.ex.auction.domain.entity.User;
import com.ex.auction.dto.AuthResponse;
import com.ex.auction.dto.LoginRequest;
import com.ex.auction.dto.RegisterRequest;
import com.ex.auction.service.AuthService;
import com.ex.auction.util.JwtUtil;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class AuthController {

    private final AuthService authService;
    private final JwtUtil jwtUtil;

    /**
     * Register new user
     * POST /api/auth/register
     */
    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        log.info("POST /api/auth/register - username: {}", request.getUsername());

        try {
            AuthResponse response = authService.register(request);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            log.error("Registration failed: {}", e.getMessage());
            throw e;
        }
    }

    /**
     * Login user
     * POST /api/auth/login
     */
    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        log.info("POST /api/auth/login - username: {}", request.getUsername());

        try {
            AuthResponse response = authService.login(request);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            log.error("Login failed: {}", e.getMessage());
            throw e;
        }
    }

    /**
     * Get current user info
     * GET /api/auth/me
     * Requires: Authorization header with Bearer token
     */
    @GetMapping("/me")
    public ResponseEntity<AuthResponse> getCurrentUser(@RequestHeader("Authorization") String authHeader) {
        log.info("GET /api/auth/me");

        try {
            // Extract token from "Bearer {token}"
            String token = authHeader.substring(7);

            // Validate token
            if (!jwtUtil.validateToken(token)) {
                throw new RuntimeException("Invalid token");
            }

            // Extract user ID and get user info
            Long userId = jwtUtil.extractUserId(token);
            User user = authService.getUserById(userId);

            return ResponseEntity.ok(AuthResponse.builder()
                    .token(token)
                    .userId(user.getUserId())
                    .username(user.getUsername())
                    .email(user.getEmail())
                    .fullName(user.getFullName())
                    .build());
        } catch (Exception e) {
            log.error("Get current user failed: {}", e.getMessage());
            throw new RuntimeException("Unauthorized");
        }
    }
}
