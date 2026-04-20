package com.example.stockapp.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@JsonIgnoreProperties(ignoreUnknown = true)
public class JQuantsFinSummaryResponse {

    @JsonProperty("pagination_key")
    private String paginationKey;

    @JsonProperty("data")
    private List<Item> data;

    @Getter
    @Setter
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Item {

        @JsonAlias({"Code", "code"})
        private String code;

        @JsonAlias({"Date", "date", "DiscDate"})
        private String date;

        @JsonAlias({"PER", "per"})
        private Double per;

        @JsonAlias({"PBR", "pbr"})
        private Double pbr;

        @JsonAlias({"ROE", "roe"})
        private Double roe;

        @JsonAlias({"ForecastDividendYieldAnnual", "forecastDividendYieldAnnual", "DividendYield"})
        private Double dividendYield;

        @JsonAlias({"MarketCapitalization", "marketCapitalization", "MarketCap"})
        private Double marketCap;
    }
}