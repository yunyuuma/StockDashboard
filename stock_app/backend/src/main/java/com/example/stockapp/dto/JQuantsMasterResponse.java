package com.example.stockapp.dto;

import com.fasterxml.jackson.annotation.JsonAnySetter;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Setter;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Setter
@JsonIgnoreProperties(ignoreUnknown = true)
public class JQuantsMasterResponse {

    @JsonProperty("data")
    private List<Item> data;

    @JsonProperty("pagination_key")
    private String paginationKey;

    public List<Item> getData() {
        return data;
    }

    public String getPaginationKey() {
        return paginationKey;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Item {

        private final Map<String, Object> values = new HashMap<>();

        @JsonAnySetter
        public void put(String key, Object value) {
            values.put(key, value);
        }

        public Map<String, Object> getValues() {
            return values;
        }

        public String getCode() {
            return pick("Code", "code", "LocalCode", "localCode");
        }

        public String getCompanyName() {
            return pick(
                    "CoName",
                    "CompanyName",
                    "companyName",
                    "CompanyNameFull",
                    "companyNameFull",
                    "Name",
                    "name"
            );
        }

        public String getMarketCodeName() {
            return pick(
                    "MktNm",
                    "MarketCodeName",
                    "marketCodeName",
                    "MarketName",
                    "marketName",
                    "Market",
                    "market"
            );
        }

        public String getSector33CodeName() {
            return pick(
                    "S33Nm",
                    "Sector33CodeName",
                    "sector33CodeName",
                    "Sector17CodeName",
                    "sector17CodeName",
                    "Sector",
                    "sector"
            );
        }

        private String pick(String... keys) {
            for (String key : keys) {
                Object value = values.get(key);
                if (value != null && !value.toString().isBlank()) {
                    return value.toString();
                }
            }
            return "";
        }
    }
}