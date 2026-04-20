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
public class JQuantsDailyBarsResponse {

    @JsonProperty("pagination_key")
    private String paginationKey;

    @JsonProperty("data")
    private List<Item> data;

    @Getter
    @Setter
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Item {

        @JsonAlias({"Date", "date"})
        private String date;

        @JsonAlias({"Code", "code"})
        private String code;

        @JsonAlias({"Open", "open", "O"})
        private Double open;

        @JsonAlias({"High", "high", "H"})
        private Double high;

        @JsonAlias({"Low", "low", "L"})
        private Double low;

        @JsonAlias({"Close", "close", "C"})
        private Double close;

        @JsonAlias({"Volume", "volume", "Vo"})
        private Double volume;

        @JsonAlias({"AdjClose", "adjClose", "AdjC"})
        private Double adjClose;
    }
}