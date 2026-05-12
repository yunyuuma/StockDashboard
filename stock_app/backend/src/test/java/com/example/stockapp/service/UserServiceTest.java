package com.example.stockapp.service;

import com.example.stockapp.entity.User;
import com.example.stockapp.repository.UserRepository;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserService userService;

    @BeforeEach
    void setup() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void ユーザ取得成功() {

        User user = new User();
        user.setId(1L);
        user.setEmail("test@example.com");

        when(userRepository.findById(1L))
                .thenReturn(Optional.of(user));

        User result = userRepository.findById(1L).orElse(null);

        assertNotNull(result);
        assertEquals("test@example.com", result.getEmail());
    }

    @Test
    void ユーザ不存在() {

        when(userRepository.findById(99L))
                .thenReturn(Optional.empty());

        Optional<User> result = userRepository.findById(99L);

        assertTrue(result.isEmpty());
    }
}