package com.example.stockapp.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "trades")
@Getter
@Setter
public class Trade {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long orderId;
    private Long userId;

    @Column(length = 10)
    private String stockCode;

    @Column(length = 10)
    private String side;

    private Integer quantity;

    @Column(precision = 15, scale = 2)
    private BigDecimal price;

    private LocalDateTime tradedAt;
}