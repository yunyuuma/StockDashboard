package com.example.stockapp.controller;

import com.example.stockapp.dto.admin.AdminUserResponse;
import com.example.stockapp.dto.admin.AdminUserRoleUpdateRequest;
import com.example.stockapp.service.AdminUserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.HttpStatus;

import java.util.List;

@RestController
@RequestMapping("/api/admin/users")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AdminUserController {

    private final AdminUserService adminUserService;

    @GetMapping
    public List<AdminUserResponse> getUsers() {
        return adminUserService.getUsers();
    }

    @PutMapping("/{userId}/role")
    public AdminUserResponse updateRole(
            @PathVariable Long userId,
            @Valid @RequestBody AdminUserRoleUpdateRequest request
    ) {
        return adminUserService.updateRole(userId, request);
    }

    @DeleteMapping("/{userId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteUser(@PathVariable Long userId) {
        adminUserService.deleteUser(userId);
    }

}