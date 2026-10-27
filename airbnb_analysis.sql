/* =============================================================
   Where the Money Is in Seattle's Airbnb Market
   Author: Faith Faithful Usenideh
   Tool:   Microsoft SQL Server (T-SQL)
   Tables: AirbnbListings (l)  - one row per listing, incl. neighbourhood and price
           AirbnbPricing  (p)  - many pricing rows per listing (listing_id, price)
   ============================================================= */


-- -------------------------------------------------------------
-- PART 1: FOLLOW THE MONEY
-- Which neighbourhoods earn the most revenue, and what do they charge?
--
-- Why a CTE: AirbnbPricing has many rows per listing. Joining it
-- straight to AirbnbListings repeats each listing many times, which
-- distorts AVG(l.price). The CTE first totals revenue per listing,
-- so each listing appears once and the average is accurate.
--
-- Why REPLACE + CAST: price can be stored as text such as '$1,250'.
-- Cleaning it first means SUM works on real numbers.
-- -------------------------------------------------------------
WITH ListingRevenue AS (                      -- CTE: temporary table of revenue per listing
    SELECT
        listing_id,
        SUM(                                      -- SUM: add up all prices for the listing
            CAST(                                 -- CAST: turn cleaned text into a number
                REPLACE(REPLACE(                  -- REPLACE: strip '$' and ',' from '$1,250'
                    CAST(price AS VARCHAR(20)), '$', ''), ',', '')
            AS DECIMAL(12,2))
        ) AS Revenue
    FROM AirbnbPricing
    GROUP BY listing_id                           -- one revenue total per listing
)
SELECT TOP 5                                      -- TOP 5: keep the five highest results
    l.neighbourhood,
    SUM(r.Revenue)          AS Total_Revenue,     -- total revenue per neighbourhood
    ROUND(AVG(l.price), 2)  AS Average_Listing_Price  -- AVG + ROUND: average price, 2 decimals
FROM AirbnbListings l
JOIN ListingRevenue r                             -- JOIN: link each listing to its revenue
    ON l.id = r.listing_id
GROUP BY l.neighbourhood                          -- GROUP BY: one row per neighbourhood
ORDER BY Total_Revenue DESC;                      -- ORDER BY DESC: highest revenue first

/* Result (top 5 by revenue):
   Neighbourhood     | Total Revenue
   Belltown          | $18.93M   (average listing price $235.59)
   Broadway          | $12.33M
   South Lake Union  | $12.11M
   Minor             |  $7.53M
   Fremont           |  $7.22M

   What it means: Belltown is Seattle's highest-earning neighbourhood. Its
   revenue comes from steady demand and many active listings, not
   from the highest nightly prices.
*/


-- -------------------------------------------------------------
-- PART 2: SAME CITY, DIFFERENT PRICE
-- How does the average nightly price change across neighbourhoods?
-- -------------------------------------------------------------
SELECT
    neighbourhood,                                -- the category being compared
    ROUND(AVG(price), 2) AS Average_Listing_Price -- AVG: average price; ROUND: 2 decimals
FROM AirbnbListings                               -- FROM: the listings table
WHERE price IS NOT NULL                           -- WHERE: exclude listings with no price
GROUP BY neighbourhood                            -- GROUP BY: one average per neighbourhood
ORDER BY Average_Listing_Price DESC;              -- ORDER BY DESC: most expensive first

/* Result:
   Highest average price          | Lowest average price
   Industrial District  $625.00   | Riverview            $137.50
   Windermere           $511.67   | Bitter Lake          $136.00
   Laurelhurst          $344.05   | Pinehurst            $133.21
   Phinney Ridge        $303.93   | North College Park   $130.66
   View Ridge           $302.86   | Crown Hill           $129.21

   What it means: Prices vary 4.8x across the city. Location strongly
   shapes what a listing can charge.
*/


-- -------------------------------------------------------------
-- PART 3: THE SURPRISE
-- Is luxury worth it? How much revenue comes from stays above $700?
--     (price is stored as text such as '$1,250', so it is cleaned
--      and converted to a number before filtering and summing)
-- -------------------------------------------------------------
SELECT
    SUM(                                          -- SUM: add up the qualifying prices
        CAST(                                     -- CAST: convert cleaned text to a number
            REPLACE(REPLACE(price, '$', ''), ',', '')  -- REPLACE: '$1,250' -> '1250'
        AS DECIMAL(10,2))
    ) AS Total_Revenue_Above_700
FROM AirbnbPricing                                -- FROM: the pricing table
WHERE CAST(REPLACE(REPLACE(price, '$', ''), ',', '')
           AS DECIMAL(10,2)) > 700;               -- WHERE: keep only prices above $700

/* Result: $39.6M from listings above $700/night (19% of revenue);
           listings under $700 earned $170.0M (81%).

   What it means: Premium stays add revenue, but four of every five dollars
   come from everyday and mid-priced listings.
*/
