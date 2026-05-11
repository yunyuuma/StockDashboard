package com.example.stockapp.service;

import com.example.stockapp.dto.auth.AuthResponse;
import com.example.stockapp.dto.auth.LoginRequest;
import com.example.stockapp.dto.auth.RegisterRequest;
import com.example.stockapp.dto.auth.TwoFactorResendRequest;
import com.example.stockapp.dto.auth.TwoFactorVerifyRequest;
import com.example.stockapp.entity.User;
import com.example.stockapp.repository.UserRepository;
import com.example.stockapp.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final TwoFactorChallengeService twoFactorChallengeService;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        validatePasswordPolicy(request.getPassword());

        String email = request.getEmail().trim().toLowerCase();

        if (userRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("このメールアドレスは既に登録されています。");
        }

        User user = new User();
        user.setUserName(request.getUserName().trim());
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setRole("USER");
        user.setTwoFactorEnabled(request.isTwoFactorEnabled());

        User saved = userRepository.save(user);

        String token = jwtService.generateToken(
                saved.getId(),
                saved.getEmail(),
                saved.getRole()
        );

        return AuthResponse.loginSuccess(
                saved.getId(),
                saved.getUserName(),
                saved.getEmail(),
                saved.getRole(),
                token
        );
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        String email = request.getEmail().trim().toLowerCase();

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("メールアドレスまたはパスワードが違います。"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("メールアドレスまたはパスワードが違います。");
        }

        if (user.isTwoFactorEnabled()) {
            String challengeId = twoFactorChallengeService.createChallenge(user);

            return AuthResponse.twoFactorRequired(
                    user.getId(),
                    user.getUserName(),
                    user.getEmail(),
                    user.getRole(),
                    challengeId
            );
        }

        String token = jwtService.generateToken(
                user.getId(),
                user.getEmail(),
                user.getRole()
        );

        return AuthResponse.loginSuccess(
                user.getId(),
                user.getUserName(),
                user.getEmail(),
                user.getRole(),
                token
        );
    }

    @Transactional
    public AuthResponse verifyTwoFactor(TwoFactorVerifyRequest request) {
        Long userId = twoFactorChallengeService.verify(
                request.getChallengeId(),
                request.getCode()
        );

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザが存在しません。"));

        String token = jwtService.generateToken(
                user.getId(),
                user.getEmail(),
                user.getRole()
        );

        return AuthResponse.loginSuccess(
                user.getId(),
                user.getUserName(),
                user.getEmail(),
                user.getRole(),
                token
        );
    }

    @Transactional
    public void resendTwoFactor(TwoFactorResendRequest request) {
        Long userId = twoFactorChallengeService.getUserId(request.getChallengeId());

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザが存在しません。"));

        twoFactorChallengeService.createChallenge(user);
    }

    private void validatePasswordPolicy(String password) {
        if (password == null || password.length() < 8 || password.length() > 16) {
            throw new IllegalArgumentException("パスワードは8~16文字で入力してください。");
        }

        boolean hasLetter = password.matches(".*[a-zA-Z].*");
        boolean hasDigit = password.matches(".*\\d.*");
        boolean hasSymbol = password.matches(".*[^a-zA-Z0-9].*");

        int count = 0;
        if (hasLetter) count++;
        if (hasDigit) count++;
        if (hasSymbol) count++;

        if (count < 2) {
            throw new IllegalArgumentException("パスワードは英字、数字、記号のうち2種類以上を含めてください。");
        }
    }
}