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

        @JsonAlias({"DisclosedDate", "disclosedDate", "Date", "date"})
        private String disclosedDate;

        @JsonAlias({"DisclosedTime", "disclosedTime"})
        private String disclosedTime;

        @JsonAlias({"LocalCode", "localCode", "Code", "code"})
        private String localCode;

        @JsonAlias({"DisclosureNumber", "disclosureNumber"})
        private String disclosureNumber;

        @JsonAlias({"TypeOfDocument", "typeOfDocument"})
        private String typeOfDocument;

        @JsonAlias({"TypeOfCurrentPeriod", "typeOfCurrentPeriod"})
        private String typeOfCurrentPeriod;

        @JsonAlias({"CurrentPeriodStartDate", "currentPeriodStartDate"})
        private String currentPeriodStartDate;

        @JsonAlias({"CurrentPeriodEndDate", "currentPeriodEndDate"})
        private String currentPeriodEndDate;

        @JsonAlias({"CurrentFiscalYearStartDate", "currentFiscalYearStartDate"})
        private String currentFiscalYearStartDate;

        @JsonAlias({"CurrentFiscalYearEndDate", "currentFiscalYearEndDate"})
        private String currentFiscalYearEndDate;

        @JsonAlias({"NetSales", "netSales"})
        private Double netSales;

        @JsonAlias({"OperatingProfit", "operatingProfit"})
        private Double operatingProfit;

        @JsonAlias({"OrdinaryProfit", "ordinaryProfit"})
        private Double ordinaryProfit;

        @JsonAlias({"Profit", "profit"})
        private Double profit;

        @JsonAlias({"EarningsPerShare", "earningsPerShare", "EPS", "eps"})
        private Double earningsPerShare;

        @JsonAlias({"ForecastNetSales", "forecastNetSales"})
        private Double forecastNetSales;

        @JsonAlias({"ForecastOperatingProfit", "forecastOperatingProfit"})
        private Double forecastOperatingProfit;

        @JsonAlias({"ForecastOrdinaryProfit", "forecastOrdinaryProfit"})
        private Double forecastOrdinaryProfit;

        @JsonAlias({"ForecastProfit", "forecastProfit"})
        private Double forecastProfit;

        @JsonAlias({
                "ForecastEarningsPerShare",
                "forecastEarningsPerShare",
                "ForecastEPS",
                "forecastEPS"
        })
        private Double forecastEarningsPerShare;

        @JsonAlias({
                "ForecastAnnualDividendPerShare",
                "forecastAnnualDividendPerShare",
                "AnnualDividendPerShareForecast",
                "annualDividendPerShareForecast"
        })
        private Double forecastAnnualDividendPerShare;
    }
}