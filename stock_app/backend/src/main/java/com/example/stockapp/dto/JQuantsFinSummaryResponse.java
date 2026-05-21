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

        @JsonAlias({"DiscDate"})
        private String disclosedDate;

        @JsonAlias({"DiscTime"})
        private String disclosedTime;

        @JsonAlias({"Code"})
        private String code;

        @JsonAlias({"DocType"})
        private String typeOfDocument;

        @JsonAlias({"DiscNo"})
        private String disclosureNumber;

        @JsonAlias({"CurPerEn"})
        private String currentPeriodEndDate;

        @JsonAlias({"Sales"})
        private Double netSales;

        @JsonAlias({"OP"})
        private Double operatingProfit;

        @JsonAlias({"OdP"})
        private Double ordinaryProfit;

        @JsonAlias({"NP"})
        private Double profit;

        @JsonAlias({"EPS"})
        private Double earningsPerShare;

        @JsonAlias({"FSales"})
        private Double forecastNetSales;

        @JsonAlias({"FOP"})
        private Double forecastOperatingProfit;

        @JsonAlias({"FOdP"})
        private Double forecastOrdinaryProfit;

        @JsonAlias({"FNP"})
        private Double forecastProfit;

        @JsonAlias({"FDivAnn"})
        private Double annualDividendPerShareForecast;
    }
}