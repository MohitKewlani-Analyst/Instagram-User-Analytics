# Instagram-User-Analytics

1. Project Description:

a) Problem Statement –  
The marketing team needs to design a Re-engagement campaign to activate 
users who signed up but have never engaged with the core products. 
Therefore, problem here is to identify the inactive users and help the marketing 
team by providing the necessary information which help them in creating a 
high value marketing campaign. 
Also, investors want transparency into user engagement for which they want to 
know that the platform is filled with real time users or bot accounts. Therefore, 
another problem from investor point of view is, to identify how well the users 
are engaging with the products features and what percentage of users are bot 
accounts. 

b) Project Overview – 
Executed an end-to-end user analytics project on Instagram's relational 
database by querying, cleaning, and transforming over 24,000 multi-table 
interaction records in MySQL using advanced CTEs, window functions, and join 
logic. Audited platform health to uncover a 38% synthetic engagement rate 
driven by automated bot accounts while identifying high-priority inactive 
segments for targeted marketing re-engagement. Modelled pre-aggregated 
SQL views directly into an executive Power BI dashboard featuring interactive 
DAX KPIs, user behavioural archetypes, and campaign scheduling trends to 
guide product and investor decisions.


2. Dataset Overview: 
 
Volume Scale: 7 relational tables totalling 24,752 records. 
Data Source – Trainity 
Detailed information about the dataset tables,primary keys,foreign keys,
attributes were given in the report pdf.


3. Tech Stack Used:
   
MySQL     -    Using MySQL for data cleaning, transformation, and data analysis.  
Power BI  -   Using Power BI for Data Visualization. 


4. Data Cleaning:

Duplicate & Null Value Auditing: Audited all 7 relational tables (24,752 total records) for duplicate rows using ROW_NUMBER() OVER (PARTITION BY ...)
window functions and verified column completeness via UNION null checks, removing empty or placeholder comments with COALESCE and NULLIF.

Text & String Standardization: Normalized user profiles and hashtag taxonomies using LOWER(), TRIM(), and REPLACE() to strip leading # symbols
and whitespace, while repairing malformed image URLs with CASE WHEN and CONCAT to enforce valid https:// prefixes.

Temporal Formatting & Schema Enforcement: Converted raw string timestamps into native MySQL DATETIME formats via STR_TO_DATE() 
and executed ALTER TABLE statements to enforce NOT NULL constraints and default timestamp rules on core user attributes.

Logical Anomaly Removal: Identified and purged corrupted records violating platform business logic, including future-dated
account registrations (created_at > NOW()) and self-following social graph loops (follower_id = followee_id).


5. Data Analysis

Conducted in-depth exploratory and behavioral analysis across 24,752 relational records using MySQL Common Table Expressions (CTEs), 
window functions (DENSE_RANK, LAG), and complex multi-table joins to solve critical business challenges for marketing and investor stakeholders.
For the marketing team, the analysis segmented inactive users into dormancy tenure cohorts (revealing 76.9% inactivity over 90 days), pinpointed peak registration
windows on Thursdays and Sundays, and identified top-performing viral content and hashtags (#smile, #beach) to power targeted win-back campaigns.
For investors, the audit evaluated the core user conversion funnel (74% creator activation and 64% full-feature adoption), confirmed a 10.5% year-over-year
increase in creator posting velocity, and uncovered 13 automated bot accounts responsible for 38% of all platform likes to establish an authentic
organic engagement baseline.


6. Recommendations

Formulated 10 data-driven strategic recommendations across marketing, product, and platform security to boost user retention and protect platform integrity.
In order to reactivate dormant users and optimize ad spend, the strategy includes purging the 13 identified bot accounts 
from mailing lists, tailoring win-back emails by inactivity duration (90 vs. 180+ days), and concentrating paid campaigns between Thursday and Sunday to match peak signup windows.
In order to strengthen community engagement and investor trust, key initiatives include launching dual-incentive user-generated content (UGC) contests,
auto-suggesting high-reach hashtags (#smile, #beach) during post uploads, introducing "People You May Know" friend recommendations,
and enforcing CAPTCHA rate-limiting alongside automated contest vote auditing to eliminate synthetic bot inflation.



