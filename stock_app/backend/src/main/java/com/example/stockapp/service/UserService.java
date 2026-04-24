package com.example.stockapp.service;

import com.example.stockapp.dto.user.*;
import com.example.stockapp.entity.User;
import com.example.stockapp.repository.UserRepository;
import com.example.stockapp.security.CustomUserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public UserProfileResponse getMyProfile(CustomUserPrincipal principal) {
        User user = getUser(principal.getId());
        return toResponse(user);
    }

    public UserProfileResponse updateMyProfile(CustomUserPrincipal principal, UserUpdateRequest request) {
        User user = getUser(principal.getId());

        String normalizedEmail = request.getEmail().trim().toLowerCase();
        if (!user.getEmail().equals(normalizedEmail) && userRepository.existsByEmail(normalizedEmail)) {
            throw new IllegalArgumentException("このメールアドレスは既に登録されています。");
        }

        user.setUserName(request.getUserName().trim());
        user.setEmail(normalizedEmail);
        user.setTwoFactorEnabled(request.getTwoFactorEnabled() != null && request.getTwoFactorEnabled());

        return toResponse(userRepository.save(user));
    }

    public void updateMyPassword(CustomUserPrincipal principal, PasswordUpdateRequest request) {
        User user = getUser(principal.getId());

        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("現在のパスワードが違います。");
        }

        validatePasswordPolicy(request.getNewPassword());
        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);
    }

    private User getUser(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("ユーザが存在しません。"));
    }

    private UserProfileResponse toResponse(User user) {
        return new UserProfileResponse(
                user.getId(),
                user.getUserName(),
                user.getEmail(),
                user.getRole(),
                user.isTwoFactorEnabled()
        );
    }

    private void validatePasswordPolicy(String password) {
        if (password == null || password.length() < 8 || password.length() > 16) {
            throw new IllegalArgumentException("パスワードは8〜16文字で入力してください。");
        }

        boolean hasLetter = password.matches(".*[A-Za-z].*");
        boolean hasDigit = password.matches(".*\\d.*");
        boolean hasSymbol = password.matches(".*[^A-Za-z0-9].*");

        int count = 0;
        if (hasLetter) count++;
        if (hasDigit) count++;
        if (hasSymbol) count++;

        if (count < 2) {
            throw new IllegalArgumentException("パスワードは英字・数字・記号のうち2種類以上を含めてください。");
        }
    }
}