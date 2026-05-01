package com.example.stockapp.repository;

import com.example.stockapp.entity.CashBalance;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface CashBalanceRepository extends JpaRepository<CashBalance, Long> {
    Optional<CashBalance> findByUserId(Long userId);
}