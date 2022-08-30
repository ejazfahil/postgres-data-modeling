# Query Optimisation 2022-08-30

## EXPLAIN ANALYZE findings
- Seq scan on fact_sales (12M rows) → add BRIN index on sold_at ✅
- Hash join on customer_id faster than nested loop for >100K rows

## Partitioning gains
- Query on single month partition: 8× faster (pruning 11 partitions)
