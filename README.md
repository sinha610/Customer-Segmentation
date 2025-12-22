# Customer Segmentation & Value Analysis using RFM

Problem Statement:
Retail businesses often struggle to identify which customers drive long-term value versus those who contribute volume without profitability. This project applies RFM (Recency, Frequency, Monetary) analysis to segment customers, evaluate value concentration, and identify reactivation and retention opportunities.

Dataset Overview:

Source: Transactional retail dataset (off-price fashion retail)

Time Period: January 2019 – January 2024

Size: ~30,000 transaction-level records

Granularity: One row per order line item

Customer Identifier: AMPERITY_ID

Key Data Handling Decisions:

  - Returns and cancellations were excluded to avoid distortion in recency, frequency, and revenue metrics.
  
  - Line-item data was aggregated at the customer level for analysis.

Methodology

1. RFM Metric Construction (SQL)
  Recency: Days since last purchase
  Frequency: Total number of completed purchases
  Monetary: Total revenue generated
  Percentile-based scoring (NTILE(5)) was used instead of fixed thresholds due to skewed retail distributions.

2. Customer Segmentation

Customers were segmented using a combination of R, F, and M scores into standard RFM groups such as:

 -- Loyal
 -- Potential Loyalist
 -- Recent Customers
 -- Need Attention
 -- About to Sleep
 -- At Risk
 -- Hibernating
 -- Lost

Segment definitions were adapted from common RFM heuristics and validated through exploratory analysis.

3. Exploratory Data Analysis (SQL)

Exploratory checks were performed to:

- Validate time coverage and customer consistency
- Confirm skewness in frequency and monetary metrics
- Compare segment-level customer volume vs. value
- Identify high-value but inactive customer segments
- SQL-based EDA was completed prior to visualization to ensure insights were data-driven.

4. Visualization (Power BI)

Power BI was used only to summarize validated insights, focusing on:

  Customer distribution by RFM segment
  Average revenue per segment
  Clear contrast between customer volume and value
  The dashboard was intentionally kept concise to highlight decision-driving insights.

Key Insights

High-frequency customers are not always high-value:
Loyal customers tend to purchase frequently but with lower average order value.

Revenue is concentrated in fewer customers:
Segments such as About to Sleep and Hibernating show high average revenue despite lower customer counts.

Significant reactivation opportunity exists:
Several high-value customers have become inactive, indicating potential ROI from targeted win-back strategies.

Customer volume alone is misleading:
Large segments like Lost contribute relatively less value per customer compared to smaller, high-spend segments.

Business Recommendations

Prioritize reactivation campaigns for high-value inactive segments.

Avoid blanket discounting; use targeted incentives based on segment behavior.

Treat loyalty as a behavioral metric, not purely a revenue indicator.

Use segmentation insights to guide marketing and retention strategy.

Tools & Technologies

SQL: Data cleaning, aggregation, RFM scoring, and exploratory analysis

Power BI: Insight summarization and stakeholder-friendly visualization

Scope Notes

This project focuses on descriptive and diagnostic analysis.

No predictive modeling or advanced statistics were applied.

Power BI usage was intentionally minimal to emphasize analytical reasoning over visual complexity.


-------

![Pg1](https://github.com/user-attachments/assets/a2b57cd7-566d-4433-b45a-20752f917532)


------
