# Where the Money Is in Seattle's Airbnb Market


**Tools:** Microsoft SQL Server (T-SQL) · PowerPoint
**Skills shown:** JOINs, CTEs, aggregation (`SUM`, `AVG`, `ROUND`), filtering, data cleaning with `REPLACE` and `CAST`

Seattle has 6,442 Airbnb listings spread across 88 neighbourhoods. Some earn millions of dollars; others struggle to compete. Every host and investor wants to know the same thing: **where is the money, and what should I charge?**

I used SQL to follow the money through the data. What I found surprised me: the biggest earners are not the most expensive listings.

---

## Dataset
- **Market:** Seattle, USA Airbnb listings
- **Size:** 6,442 active listings across 88 neighbourhoods
- **Tables:** `AirbnbListings` (one row per listing, with neighbourhood and price) and `AirbnbPricing` (many pricing rows per listing)

## The Questions I Set Out to Answer
- **Where does the money go?** Which neighbourhoods earn the most revenue?
- **What can a host charge?** How do prices change from one neighbourhood to the next?
- **Is luxury worth it?** How much revenue really comes from $700+ stays?

## Tools & SQL Functions Used
**Tools:** Microsoft SQL Server Management Studio (SSMS) to write and run the queries · PowerPoint to present the results

| Function | What it does in this analysis | Used to find |
| --- | --- | --- |
| `SELECT ... FROM` | Chooses the columns to show and the table to read from | All findings |
| `WITH` (CTE) | Builds a temporary table of revenue per listing before joining | Revenue |
| `JOIN ... ON` | Links each listing to its pricing records by listing ID | Revenue |
| `SUM()` | Adds prices together to calculate total revenue | Revenue, luxury |
| `AVG()` | Calculates the average listing price | Revenue, price |
| `ROUND(x, 2)` | Rounds results to two decimal places | Revenue, price |
| `REPLACE()` | Removes the `$` sign and commas from text prices like `'$1,250'` | Revenue, luxury |
| `CAST(... AS DECIMAL)` | Converts cleaned text into a number so it can be summed | Revenue, luxury |
| `WHERE` | Filters rows: drops missing prices, keeps prices above $700 | Price, luxury |
| `GROUP BY` | Groups rows so there is one result per neighbourhood or listing | Revenue, price |
| `ORDER BY ... DESC` / `TOP` | Ranks results from highest to lowest and keeps the top 5 | Revenue, price |

---

## Part 1: Follow the money

My first step was to find where the revenue goes. I totalled the revenue for every listing, then added it up by neighbourhood.

```sql
WITH ListingRevenue AS (
    SELECT listing_id,
           SUM(CAST(REPLACE(REPLACE(CAST(price AS VARCHAR(20)), '$', ''), ',', '')
                    AS DECIMAL(12,2))) AS Revenue
    FROM AirbnbPricing
    GROUP BY listing_id
)
SELECT TOP 5
    l.neighbourhood,
    SUM(r.Revenue)         AS Total_Revenue,
    ROUND(AVG(l.price), 2) AS Average_Listing_Price
FROM AirbnbListings l
JOIN ListingRevenue r ON l.id = r.listing_id
GROUP BY l.neighbourhood
ORDER BY Total_Revenue DESC;
```

| Rank | Neighbourhood | Total revenue |
| --- | --- | --- |
| 1 | Belltown | $18.93M |
| 2 | Broadway | $12.33M |
| 3 | South Lake Union | $12.11M |
| 4 | Minor | $7.53M |
| 5 | Fremont | $7.22M |

**How I built it:**
1. The `WITH` block (CTE) uses `REPLACE` and `CAST` to clean each price, then `SUM` and `GROUP BY listing_id` total the revenue for each listing.
2. `JOIN ... ON l.id = r.listing_id` links each listing to its revenue total.
3. `GROUP BY l.neighbourhood` adds up revenue for each neighbourhood, and `ROUND(AVG(l.price), 2)` gives its average price.
4. `ORDER BY Total_Revenue DESC` with `TOP 5` keeps the five highest-earning neighbourhoods.

**Why a CTE?** `AirbnbPricing` has many rows per listing. Joining it directly repeats each listing many times and distorts the average price. The CTE totals revenue per listing first, so each listing counts once.

**What it means:** Belltown leads with **$18.93M**, yet at **$235.59** a night it is not the most expensive area. It wins on steady demand and many active listings. Volume beats price.

## Part 2: Same city, different price

If Belltown isn't the priciest area, which is? I compared the average nightly price in every neighbourhood.

```sql
SELECT neighbourhood,
       ROUND(AVG(price), 2) AS Average_Listing_Price
FROM AirbnbListings
WHERE price IS NOT NULL
GROUP BY neighbourhood
ORDER BY Average_Listing_Price DESC;
```

| Highest average price | $/night | Lowest average price | $/night |
| --- | --- | --- | --- |
| Industrial District | 625.00 | Riverview | 137.50 |
| Windermere | 511.67 | Bitter Lake | 136.00 |
| Laurelhurst | 344.05 | Pinehurst | 133.21 |
| Phinney Ridge | 303.93 | North College Park | 130.66 |
| View Ridge | 302.86 | Crown Hill | 129.21 |

**How I built it:**
1. `WHERE price IS NOT NULL` removes listings with no price, so they don't distort the average.
2. `GROUP BY neighbourhood` puts listings in each neighbourhood together.
3. `ROUND(AVG(price), 2)` calculates each neighbourhood's average price to two decimals.
4. `ORDER BY ... DESC` ranks neighbourhoods from most to least expensive.

**What it means:** A few miles change the price almost fivefold, from **$625** in Industrial District to **$129** in Crown Hill. A city-wide average misleads; hosts must price against their own neighbourhood.

## Part 3: The surprise

With prices this high in some areas, I expected luxury listings to drive the market. To test it, I measured how much revenue comes from stays above $700 a night. The prices were stored as text (such as `'$1,250'`), so I cleaned them first.

```sql
SELECT SUM(CAST(REPLACE(REPLACE(price, '$', ''), ',', '') AS DECIMAL(10,2)))
           AS Total_Revenue_Above_700
FROM AirbnbPricing
WHERE CAST(REPLACE(REPLACE(price, '$', ''), ',', '') AS DECIMAL(10,2)) > 700;
```

| Price band | Revenue | Share |
| --- | --- | --- |
| Under $700/night | $170.0M | 81% |
| Above $700/night | $39.6M | 19% |

**How I built it:**
1. `REPLACE(price, '$', '')` removes the dollar sign, and the second `REPLACE` removes commas: `'$1,250'` becomes `'1250'`.
2. `CAST(... AS DECIMAL(10,2))` converts the cleaned text into a number.
3. `WHERE ... > 700` keeps only listings priced above $700 a night.
4. `SUM(...)` adds those prices to give the total revenue from premium listings.

**What it means:** Luxury is not where the money is. Four of every five dollars come from everyday listings under $700. The market rewards affordable, well-booked homes.

---

## What This Means for Hosts and Investors
1. **Invest where demand is steady.** Belltown, Broadway and South Lake Union combine high demand with many active listings.
2. **Price by neighbourhood.** With a 4.8× price gap, set nightly rates against local averages, not one city-wide figure.
3. **Compete on occupancy.** Most revenue comes from listings under $700; consistent bookings at competitive prices beat waiting for luxury guests.

## The Bottom Line
The money in Seattle's Airbnb market follows **location and steady bookings**, not luxury prices.

## Files in this Repository
- `airbnb_analysis.sql` – all queries with line-by-line explanations and results
- `Airbnb_Seattle_SQL_Analysis.pptx` – presentation of the findings
