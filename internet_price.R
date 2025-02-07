---
title: "World Cities Average Internet Prices EDA with R"
author: "Zarina U."
date: "Last edited `r format(Sys.time(), '%B %d, %Y')`"
output:
  pdf_document: default
  html_notebook: default
---

# Introduction
In this report, we're going to find out:  
1. Top 10 country of the highest and the lowest average internet prices during 2010-2020  
2. Description of average internet prices each continent in every year  
3. The Outlier of internet prices in every year  
4. Comparison of Indonesia's internet prices among other Southeast Asian Country

## Dataset
Dataset that will be used in this notebook is World cities average internet prices on 2010 - 2020. You can go to this link to download the dataset ->  https://www.kaggle.com/cityapiio/world-cities-average-internet-prices-2010-2020

## Load Package
```{r load-package, message=FALSE, warning=FALSE}
library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(forcats)
library(stringr)
```

## Data Preparation

### Input Data
```{r input-data, message=FALSE}
internet_prices <- read_csv("cities_internet_prices_historical.24-10-2021.csv")

# fix variable name
internet_prices <- internet_prices %>%
  select(city = City,
         region = Region,
         country = Country,
         price_2010 = `Internet Price, 2010`,
         price_2011 = `Internet Price, 2011`,
         price_2012 = `Internet Price, 2012`,
         price_2013 = `Internet Price, 2013`,
         price_2014 = `Internet Price, 2014`,
         price_2015 = `Internet Price, 2015`,
         price_2016 = `Internet Price, 2016`,
         price_2017 = `Internet Price, 2017`,
         price_2018 = `Internet Price, 2018`,
         price_2019 = `Internet Price, 2019`,
         price_2020 = `Internet Price, 2020`,)

```

### Checking data type
Based on the structure of `internet_prices`, we can see that all variables have corresponding data type. Column city, region and country are character, and column prices are numeric. 
```{r data-type}
str(internet_prices)
```

### Checking missing value
There are 92 missing values on region column. But, in this case, we ignore this column because we just want to see the difference based on country instead of region.
```{r missing-value}
missing_values <- function(df) {
    missing_val <- c()
    for (c in colnames(df)) {
        missing <- sum(is.na(df[[c]]))
        missing_val <- c(missing_val, missing)
    }
    tibble(colnames(df), missing_val)
}
missing_values(internet_prices)
```

### Add continent variable
We want to know the description of average internet prices for each continent in every year. So, this dataset will be useful later.
```{r add-continent-variable, message=FALSE}
# load data continent
data_continent <- read_csv("continents2.csv")
data_continent <- data_continent %>%
  select(country = name, continent = region)

# add several countries that haven't in data_continent
add <- data.frame(country = c("United States of America",			
"North Macedonia", "People's Republic of China", "The Bahamas", "Brunei", "Bosnia and Herzegovina", "Antarctica"), continent = c("Americas", "Europe", "Asia", "Americas", "Asia", "Europe", "Oceania"))

# combine the data
data_continent <- bind_rows(data_continent, add)
```

# THE QUESTION
## Which country of the highest and the lowest average internet prices during 2010-2020? 
```{r Q1, message=FALSE}
gather_year <- internet_prices %>%
  gather(year, price, price_2010:price_2020)
  
gather_year$year <- str_remove_all(gather_year$year, "price_")

# the highest
top10 <-  gather_year %>%
  group_by(country) %>%
  summarize(mean = mean(price)) %>%
  arrange(desc(mean))
top10 <- top10[1:10,]

ggplot(top10, aes(x = fct_reorder(country, mean), y = mean)) +
  geom_col(fill = c("#014636", "#016C59", "#016C59", "#02818A", "#02818A", "#3690C0", "#3690C0",  "#67A9CF", "#67A9CF", "#A6BDDB")) +
  geom_text(aes(label = round(mean, digits = 1)), color = "white", size = 3, nudge_y = -3) +
  coord_flip() +
  labs(
    title = "10 Country of the highest Internet Prices in the world",
    subtitle = "Qatar is the number one country of the most expensive internet price.\nEven the price is far from Oman who ranks number two.",
    x = "Country",
    y = "Average internet prices"
  ) +
  theme_bw() +
  theme(
    plot.title = element_text(size = 15),
    plot.subtitle = element_text(size = 10)
    )
  

# the lowest
below10 <- gather_year %>%
  group_by(country) %>%
  summarize(mean = mean(price)) %>%
  arrange(mean)
below10 <- below10[1:10,]

ggplot(below10, aes(x = fct_reorder(country, mean), y = mean)) +
  geom_col(fill = c("#FFF7FB", "#ECE2F0", "#ECE2F0", "#D0D1E6", "#D0D1E6", "#A6BDDB", "#A6BDDB",  "#67A9CF", "#67A9CF", "#3690C0")) +
  coord_flip() +
  geom_text(aes(label = round(mean, digits = 2)), color = "black", size = 3, nudge_y = -0.2) +
  coord_flip() +
  labs(
    title = "10 Country of the lowest Internet Prices in the world",
    subtitle = "Malta is the number one country of the most inexpensive internet price.\nNot much different with Ukraine who ranks number two.",
    x = "Country",
    y = "Average internet prices"
  ) +
  theme_bw() +
  theme(
    plot.title = element_text(size = 15),
    plot.subtitle = element_text(size = 10)
    )
```

## The description of average internet prices each continent every year
```{r}
# join with continent data
join_continent <- gather_year %>%
  inner_join(data_continent, by = c("country" = "country"))

by_continent_year <- join_continent %>%
  group_by(year, continent) %>%
  summarise(mean = mean(price), .groups = "keep")

#plot
ggplot(by_continent_year, aes(x = year, y = mean, group = continent)) +
  geom_line(aes(colour = continent), size = 1) +
  
  labs(
    title = "Time Series of Internet Prices Every Continent",
    subtitle = "It can be seen that the price for each country move volatile.\nFound that the most expensive is belong to Oceania and the most inexpensive belong to Europe",
    x = "Year",
    y = "Average Internet Prices"
  ) +
  theme_bw() +
  theme(
    plot.title = element_text(size = 15),
    plot.subtitle = element_text(size = 10)
    )
```


## Is there any outlier of internet prices in each year?
```{r}
# distribution of internet price in every year
gather_year %>%
  ggplot(aes(price)) +
  geom_histogram(bins = 30) +
  facet_wrap(~ year) +
  labs(
    title = "Distribution of internet price in every year",
    subtitle = "The distribution of data seems like the uniform distribution\nIt can be seen that the data contains 0 the most especially in 2010 until 2014, maybe the internet has not arrived for several country in\nthat year"
  ) +
  theme_bw() +
  theme(
    plot.title = element_text(size = 15),
    plot.subtitle = element_text(size = 7)
    )

# check the outlier
gather_year %>%
  filter(price != 0.000000) %>%
  ggplot(aes(price)) +
  geom_boxplot() +
  facet_wrap(~ year) +
  labs(
    title = "The Outlier",
    subtitle = "Based on boxplot, the outlier is shown by the dot. As we can see that every year has the outlier except 2020."
  ) +
  theme_bw() +
  theme(
    plot.title = element_text(size = 15),
    plot.subtitle = element_text(size = 7)
  )

outlier <- gather_year %>%
  filter(price > 120) %>%
  arrange(desc(price))
outlier[,3:5]
```


## Comparison of Indonesia's internet prices among other Southeast Asian Country
```{r}
sea_country <- c("Cambodia", "Myanmar", "Thailand", "Vietnam", "Brunei", "Philippines", "Indonesia", "Malaysia", "Singapore")

by_sea_country <- gather_year %>%
  filter(country %in% sea_country) %>%
  group_by(country) %>%
  summarise(mean = mean(price))

mean_sea_country <- mean(by_sea_country$mean)

ggplot(by_sea_country, aes(x = fct_reorder(country, mean, .desc = TRUE), y = mean)) +
  geom_col(fill = rep(c("grey","#D35151","grey"), times = c(2,1,6))) +
  geom_hline(yintercept = mean_sea_country) +
  geom_text(aes(label = round(mean, digits = 2)), color = "black", size = 3, nudge_y = -1) +
  annotate(
    "text",
    x = 9, y = mean_sea_country+5,
    label = c(round(mean_sea_country, digits = 2), "\naverage\nprice"),
    vjust = 0.95, size = 3, color = "black"
  ) +
  labs(
    title = "Indonesia internet prices among other Southeast Asian Country",
    subtitle = "Internet prices in Indonesia belong to the cheapest among the Southeast Asian Country.\nIndonesia ranks #3 for the cheapest internet prices among its neighbor",
    x = "Country",
    y = "Average internet prices"
  ) +
  theme_bw() +
  theme(
    plot.title = element_text(size = 15),
    plot.subtitle = element_text(size = 10)
    )
```
