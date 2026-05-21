package com.example.stockapp.service;

import com.example.stockapp.dto.user.PasswordUpdateRequest;
import com.example.stockapp.dto.user.TwoFactorSettingRequest;
import com.example.stockapp.dto.user.UserProfileResponse;
import com.example.stockapp.dto.user.UserUpdateRequest;
import com.example.stockapp.entity.User;
import com.example.stockapp.repository.UserRepository;
import com.example.stockapp.security.CustomUserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional(readOnly = true)
    public UserProfileResponse getMyProfile(CustomUserPrincipal principal) {
        User user = getUser(principal.getId());
        return toResponse(user);
    }

    public UserProfileResponse updateMyProfile(
            CustomUserPrincipal principal,
            UserUpdateRequest request
    ) {
        User user = getUser(principal.getId());

        String userName = request.getUserName().trim();
        String email = request.getEmail().trim().toLowerCase();

        if (!user.getEmail().equals(email)
                && userRepository.existsByEmail(email)) {
            throw new IllegalArgumentException(
                    "このメールアドレスは既に登録されています。"
            );
        }

        user.setUserName(userName);
        user.setEmail(email);

        return toResponse(userRepository.save(user));
    }

    public void updateMyPassword(
            CustomUserPrincipal principal,
            PasswordUpdateRequest request
    ) {
        User user = getUser(principal.getId());

        if (!passwordEncoder.matches(
                request.getCurrentPassword(),
                user.getPasswordHash()
        )) {
            throw new IllegalArgumentException(
                    "現在のパスワードが違います。"
            );
        }

        validatePasswordPolicy(request.getNewPassword());

        user.setPasswordHash(
                passwordEncoder.encode(request.getNewPassword())
        );

        userRepository.save(user);
    }

    public UserProfileResponse updateTwoFactorSetting(
            CustomUserPrincipal principal,
            TwoFactorSettingRequest request
    ) {
        User user = getUser(principal.getId());

        user.setTwoFactorEnabled(request.isEnabled());

        return toResponse(userRepository.save(user));
    }

    private User getUser(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() ->
                        new IllegalArgumentException(
                                "ユーザが存在しません。"
                        ));
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

        if (password == null
                || password.length() < 8
                || password.length() > 16) {
            throw new IllegalArgumentException(
                    "パスワードは8〜16文字で入力してください。"
            );
        }

        boolean hasLetter =
                password.matches(".*[A-Za-z].*");

        boolean hasDigit =
                password.matches(".*\\d.*");

        boolean hasSymbol =
                password.matches(".*[^A-Za-z0-9].*");

        int count = 0;
        if (hasLetter) count++;
        if (hasDigit) count++;
        if (hasSymbol) count++;

        if (count < 2) {
            throw new IllegalArgumentException(
                    "パスワードは英字・数字・記号のうち2種類以上を含めてください。"
            );
        }
    }
}