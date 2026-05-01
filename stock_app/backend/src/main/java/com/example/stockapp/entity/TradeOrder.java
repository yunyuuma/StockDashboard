package com.example.stockapp.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "trade_orders")
@Getter
@Setter
public class TradeOrder {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long userId;

    @Column(length = 10)
    private String stockCode;

    @Column(length = 10)
    private String side; // BUY / SELL

    @Column(length = 10)
    private String orderType; // MARKET / LIMIT

    private Integer quantity;

    @Column(precision = 15, scale = 2)
    private BigDecimal limitPrice;

    @Column(precision = 15, scale = 2)
    private BigDecimal currentPrice;

    @Column(length = 20)
    private String status; // OPEN / FILLED / CANCELED

    private LocalDateTime orderedAt;
    private LocalDateTime filledAt;
}