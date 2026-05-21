package com.example.stockapp.service;

import com.example.stockapp.dto.CompanyProfileAutoFillResult;
import com.example.stockapp.entity.CompanyProfile;
import com.example.stockapp.repository.CompanyProfileRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.net.URI;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

@Service
@RequiredArgsConstructor
public class CompanyProfileStructuredDataAutoFillService {

    private final CompanyProfileRepository companyProfileRepository;
    private final StockService stockService;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Transactional
    public CompanyProfileAutoFillResult autoFillByStockCode(String stockCode) {
        String normalizedCode = normalize(stockCode);

        CompanyProfile profile = companyProfileRepository.findByStockCode(normalizedCode)
                .orElseGet(() -> {
                    CompanyProfile p = new CompanyProfile();
                    p.setStockCode(normalizedCode);
                    p.setWebsite("");
                    p.setDescription("");
                    p.setMapQuery(stockService.findNameByCode(normalizedCode) + " 本社");
                    p.setTrendsKeyword(stockService.findNameByCode(normalizedCode));
                    return companyProfileRepository.save(p);
                });

        String homepage = nullToEmpty(profile.getWebsite()).trim();

        if (homepage.isEmpty()) {
            return new CompanyProfileAutoFillResult(
                    normalizedCode,
                    nullToEmpty(profile.getWebsite()),
                    nullToEmpty(profile.getDescription()),
                    false
            );
        }

        boolean updated = false;

        try {
            Document doc = Jsoup.connect(homepage)
                    .userAgent("Mozilla/5.0")
                    .timeout((int) Duration.ofSeconds(15).toMillis())
                    .followRedirects(true)
                    .get();

            ExtractedProfile extracted = extractFromDocument(doc, homepage);

            if (isBlank(profile.getWebsite()) && !isBlank(extracted.website())) {
                profile.setWebsite(trimLong(extracted.website(), 255));
                updated = true;
            }

            if (isBlank(profile.getDescription()) && !isBlank(extracted.description())) {
                profile.setDescription(trimLong(extracted.description(), 500));
                updated = true;
            }

            if (updated) {
                companyProfileRepository.save(profile);
            }

            return new CompanyProfileAutoFillResult(
                    normalizedCode,
                    nullToEmpty(profile.getWebsite()),
                    nullToEmpty(profile.getDescription()),
                    updated
            );

        } catch (Exception e) {
            return new CompanyProfileAutoFillResult(
                    normalizedCode,
                    nullToEmpty(profile.getWebsite()),
                    nullToEmpty(profile.getDescription()),
                    false
            );
        }
    }

    private ExtractedProfile extractFromDocument(Document doc, String fallbackUrl) {
        List<JsonNode> candidates = extractJsonLdCandidates(doc);

        String website = "";
        String description = "";

        for (JsonNode node : candidates) {
            website = firstNonBlank(
                    website,
                    extractUrl(node),
                    extractSameAsOfficial(node)
            );

            description = firstNonBlank(
                    description,
                    extractDescription(node)
            );
        }

        if (isBlank(website)) {
            website = normalizeUrl(fallbackUrl);
        }

        if (isBlank(description)) {
            description = extractMetaDescription(doc);
        }

        return new ExtractedProfile(
                normalizeUrl(website),
                cleanText(description)
        );
    }

    private List<JsonNode> extractJsonLdCandidates(Document doc) {
        List<JsonNode> nodes = new ArrayList<>();
        Elements scripts = doc.select("script[type=application/ld+json]");

        for (Element script : scripts) {
            String raw = script.data();
            if (isBlank(raw)) {
                raw = script.html();
            }
            if (isBlank(raw)) {
                continue;
            }

            try {
                JsonNode root = objectMapper.readTree(raw);
                flattenJsonLd(root, nodes);
            } catch (Exception ignored) {
            }
        }

        return nodes;
    }

    private void flattenJsonLd(JsonNode node, List<JsonNode> out) {
        if (node == null || node.isNull()) {
            return;
        }

        if (node.isArray()) {
            for (JsonNode child : node) {
                flattenJsonLd(child, out);
            }
            return;
        }

        if (node.isObject()) {
            if (node.has("@graph")) {
                flattenJsonLd(node.get("@graph"), out);
            }
            out.add(node);
        }
    }

    private String extractUrl(JsonNode node) {
        if (!looksLikeOrganization(node)) {
            return "";
        }

        JsonNode url = node.get("url");
        if (url != null && url.isTextual()) {
            return url.asText();
        }
        return "";
    }

    private String extractSameAsOfficial(JsonNode node) {
        if (!looksLikeOrganization(node)) {
            return "";
        }

        JsonNode sameAs = node.get("sameAs");
        if (sameAs == null) {
            return "";
        }

        if (sameAs.isTextual()) {
            return sameAs.asText();
        }

        if (sameAs.isArray()) {
            for (JsonNode child : sameAs) {
                if (child.isTextual()) {
                    String value = child.asText();
                    if (looksLikeWebsite(value)) {
                        return value;
                    }
                }
            }
        }

        return "";
    }

    private String extractDescription(JsonNode node) {
        if (!looksLikeOrganization(node)) {
            return "";
        }

        JsonNode description = node.get("description");
        if (description != null && description.isTextual()) {
            return description.asText();
        }

        JsonNode disambiguatingDescription = node.get("disambiguatingDescription");
        if (disambiguatingDescription != null && disambiguatingDescription.isTextual()) {
            return disambiguatingDescription.asText();
        }

        return "";
    }

    private boolean looksLikeOrganization(JsonNode node) {
        JsonNode type = node.get("@type");
        if (type == null) {
            return false;
        }

        if (type.isTextual()) {
            String v = type.asText().toLowerCase(Locale.ROOT);
            return v.contains("organization")
                    || v.contains("corporation")
                    || v.contains("localbusiness");
        }

        if (type.isArray()) {
            for (JsonNode child : type) {
                if (child.isTextual()) {
                    String v = child.asText().toLowerCase(Locale.ROOT);
                    if (v.contains("organization") || v.contains("corporation") || v.contains("localbusiness")) {
                        return true;
                    }
                }
            }
        }

        return false;
    }

    private String extractMetaDescription(Document doc) {
        Element meta = doc.selectFirst("meta[name=description]");
        if (meta != null) {
            return meta.attr("content");
        }

        Element og = doc.selectFirst("meta[property=og:description]");
        if (og != null) {
            return og.attr("content");
        }

        return "";
    }

    private String normalizeUrl(String value) {
        if (isBlank(value)) {
            return "";
        }

        try {
            URI uri = URI.create(value.trim());
            String scheme = uri.getScheme();
            if (scheme == null) {
                return value.trim();
            }
            return uri.toString();
        } catch (Exception e) {
            return value.trim();
        }
    }

    private boolean looksLikeWebsite(String value) {
        if (isBlank(value)) {
            return false;
        }
        String v = value.toLowerCase(Locale.ROOT);
        return v.startsWith("http://") || v.startsWith("https://");
    }

    private String firstNonBlank(String... values) {
        for (String value : values) {
            if (!isBlank(value)) {
                return value;
            }
        }
        return "";
    }

    private String cleanText(String s) {
        if (s == null) {
            return "";
        }
        return s.replaceAll("\\s+", " ").trim();
    }

    private String trimLong(String s, int max) {
        if (s == null) {
            return "";
        }
        return s.length() <= max ? s : s.substring(0, max);
    }

    private String normalize(String stockCode) {
        return stockCode == null ? "" : stockCode.trim().toUpperCase();
    }

    private boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }

    private String nullToEmpty(String s) {
        return s == null ? "" : s;
    }

    private record ExtractedProfile(
            String website,
            String description
    ) {}
}