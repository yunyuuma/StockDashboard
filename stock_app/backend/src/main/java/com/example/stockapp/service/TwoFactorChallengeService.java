package com.example.stockapp.service;

import com.example.stockapp.entity.User;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
@RequiredArgsConstructor
public class TwoFactorChallengeService {

    private final OtpMailService otpMailService;

    private final SecureRandom random = new SecureRandom();
    private final Map<String, Challenge> challenges = new ConcurrentHashMap<>();

    public String createChallenge(User user) {
        String challengeId = UUID.randomUUID().toString();
        String code = String.format("%06d", random.nextInt(1_000_000));

        challenges.put(
                challengeId,
                new Challenge(
                        user.getId(),
                        code,
                        LocalDateTime.now().plusMinutes(5)
                )
        );

        otpMailService.sendOtpCode(
                user.getEmail(),
                user.getUserName(),
                code
        );

        return challengeId;
    }

    public Long verify(String challengeId, String code) {
        Challenge challenge = challenges.get(challengeId);

        if (challenge == null) {
            throw new IllegalArgumentException("認証情報が存在しません。");
        }

        if (challenge.getExpiresAt().isBefore(LocalDateTime.now())) {
            challenges.remove(challengeId);
            throw new IllegalArgumentException("認証コードの有効期限が切れています。");
        }

        if (!challenge.getCode().equals(code)) {
            throw new IllegalArgumentException("認証コードが違います。");
        }

        challenges.remove(challengeId);
        return challenge.getUserId();
    }

    public Long getUserId(String challengeId) {
        Challenge challenge = challenges.get(challengeId);

        if (challenge == null) {
            throw new IllegalArgumentException("認証情報が存在しません。");
        }

        return challenge.getUserId();
    }

    @Getter
    private static class Challenge {
        private final Long userId;
        private final String code;
        private final LocalDateTime expiresAt;

        private Challenge(Long userId, String code, LocalDateTime expiresAt) {
            this.userId = userId;
            this.code = code;
            this.expiresAt = expiresAt;
        }
    }
}