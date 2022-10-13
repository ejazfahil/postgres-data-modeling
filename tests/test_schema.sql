-- pgTAP tests 2022-10-13
SELECT plan(4);
SELECT has_table('fact_sales');
SELECT has_column('fact_sales','amount');
SELECT col_not_null('fact_sales','quantity');
SELECT has_index('fact_sales','idx_fact_sales_date');
SELECT finish();
