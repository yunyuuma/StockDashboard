package com.example.stockapp.client;

import com.example.stockapp.config.JQuantsProperties;
import com.example.stockapp.dto.JQuantsDailyBarsResponse;
import com.example.stockapp.dto.JQuantsDividendResponse;
import com.example.stockapp.dto.JQuantsFinSummaryResponse;
import com.example.stockapp.dto.JQuantsMasterResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.util.Optional;

@Component
@RequiredArgsConstructor
public class JQuantsClient {

    private final JQuantsProperties properties;
    private final RestTemplate restTemplate = new RestTemplate();

    public JQuantsMasterResponse getMaster(String paginationKey) {
        return get(
                UriComponentsBuilder
                        .fromHttpUrl(properties.getBaseUrl() + "/equities/master")
                        .queryParamIfPresent("pagination_key", Optional.ofNullable(paginationKey))
                        .toUriString(),
                JQuantsMasterResponse.class
        );
    }

    public JQuantsDailyBarsResponse getDailyBars(String code, String from, String to) {
        return get(
                UriComponentsBuilder
                        .fromHttpUrl(properties.getBaseUrl() + "/equities/bars/daily")
                        .queryParam("code", code)
                        .queryParamIfPresent("from", Optional.ofNullable(from))
                        .queryParamIfPresent("to", Optional.ofNullable(to))
                        .toUriString(),
                JQuantsDailyBarsResponse.class
        );
    }

    // 概要タブ用
    public JQuantsFinSummaryResponse getFinSummary(String code) {
        return get(
                UriComponentsBuilder
                        .fromHttpUrl(properties.getBaseUrl() + "/fins/summary")
                        .queryParam("code", code)
                        .toUriString(),
                JQuantsFinSummaryResponse.class
        );
    }

    public JQuantsDividendResponse getDividend(String code) {
        return get(
                UriComponentsBuilder
                        .fromHttpUrl(properties.getBaseUrl() + "/fins/dividend")
                        .queryParam("code", code)
                        .toUriString(),
                JQuantsDividendResponse.class
        );
    }

    private <T> T get(String url, Class<T> responseType) {
        HttpHeaders headers = new HttpHeaders();
        headers.set("x-api-key", properties.getApiKey());
        headers.setAccept(java.util.List.of(MediaType.APPLICATION_JSON));

        HttpEntity<Void> entity = new HttpEntity<>(headers);

        try {
            ResponseEntity<T> response =
                    restTemplate.exchange(url, HttpMethod.GET, entity, responseType);
            return response.getBody();
        } catch (HttpStatusCodeException e) {
            throw new RuntimeException(
                    "J-Quants API error: status=" + e.getStatusCode().value()
                            + ", body=" + e.getResponseBodyAsString(),
                    e
            );
        } catch (Exception e) {
            throw new RuntimeException("J-Quants API call failed: " + e.getMessage(), e);
        }
    }
}