package com.example.stockapp.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "jquants")
public class JQuantsProperties {
    private String baseUrl;
    private String apiKey;
    private long cacheMinutes = 30;
}