package com.example.stockapp.client;

import com.example.stockapp.config.JQuantsProperties;
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
        String url = UriComponentsBuilder
                .fromHttpUrl(properties.getBaseUrl() + "/equities/master")
                .queryParamIfPresent("pagination_key", Optional.ofNullable(paginationKey))
                .toUriString();

        HttpHeaders headers = new HttpHeaders();
        headers.set("x-api-key", properties.getApiKey());
        headers.setAccept(java.util.List.of(MediaType.APPLICATION_JSON));

        HttpEntity<Void> entity = new HttpEntity<>(headers);

        try {
            ResponseEntity<JQuantsMasterResponse> response =
                    restTemplate.exchange(url, HttpMethod.GET, entity, JQuantsMasterResponse.class);

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