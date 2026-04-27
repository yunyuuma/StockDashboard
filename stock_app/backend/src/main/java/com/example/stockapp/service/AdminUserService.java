package com.example.stockapp.service;

import com.example.stockapp.dto.admin.AdminUserResponse;
import com.example.stockapp.dto.admin.AdminUserRoleUpdateRequest;
import com.example.stockapp.entity.User;
import com.example.stockapp.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AdminUserService {

    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public List<AdminUserResponse> getUsers() {
        return userRepository.findAll()
                .stream()
                .sorted(Comparator.comparing(User::getId))
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public AdminUserResponse updateRole(
            Long userId,
            AdminUserRoleUpdateRequest request
    ) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザが存在しません。"));

        String role = normalizeRole(request.getRole());

        user.setRole(role);

        User saved = userRepository.save(user);

        return toResponse(saved);
    }

    private String normalizeRole(String role) {
        if (role == null) {
            throw new IllegalArgumentException("権限は必須です。");
        }

        String normalized = role.trim().toUpperCase();

        if ("2".equals(normalized) || "ADMIN".equals(normalized) || "ROLE_ADMIN".equals(normalized)) {
            return "ADMIN";
        }

        if ("1".equals(normalized) || "USER".equals(normalized) || "ROLE_USER".equals(normalized)) {
            return "USER";
        }

        throw new IllegalArgumentException("権限はUSERまたはADMINで指定してください。");
    }

    private AdminUserResponse toResponse(User user) {
        return new AdminUserResponse(
                user.getId(),
                user.getUserName(),
                user.getEmail(),
                user.getRole(),
                user.isTwoFactorEnabled()
        );
    }
}