package com.example.stockapp.service;

import com.example.stockapp.entity.User;
import com.example.stockapp.repository.FavoriteRepository;
import com.example.stockapp.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.*;

class AdminServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private FavoriteRepository favoriteRepository;

    @InjectMocks
    private AdminUserService adminUserService;

    @BeforeEach
    void setup() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void ユーザ削除時にお気に入りも削除されること() {
        User user = new User();
        user.setId(1L);

        when(userRepository.findById(1L))
                .thenReturn(Optional.of(user));

        adminUserService.deleteUser(1L);

        verify(favoriteRepository, times(1)).deleteByUserId(1);
        verify(userRepository, times(1)).delete(user);
    }

    @Test
    void 存在しないユーザ削除なら例外になること() {
        when(userRepository.findById(99L))
                .thenReturn(Optional.empty());

        assertThrows(
                IllegalArgumentException.class,
                () -> adminUserService.deleteUser(99L)
        );
    }

    @Test
    void 存在しないユーザ削除なら例外() {

        when(userRepository.findById(99L))
                .thenReturn(Optional.empty());

        assertThrows(
                IllegalArgumentException.class,
                () -> adminUserService.deleteUser(99L)
        );
    }

    @Test
    void 自分自身を削除できないこと() {

        assertThrows(
                IllegalArgumentException.class,
                () -> adminUserService.deleteUser(null)
        );
    }
}