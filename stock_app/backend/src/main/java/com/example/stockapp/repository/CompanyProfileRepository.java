package com.example.stockapp.repository;

import com.example.stockapp.entity.CompanyProfile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface CompanyProfileRepository extends JpaRepository<CompanyProfile, Integer> {

    Optional<CompanyProfile> findByStockCode(String stockCode);

    boolean existsByStockCode(String stockCode);

    void deleteByStockCode(String stockCode);
}