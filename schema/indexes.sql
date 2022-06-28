-- Indexes 2022-06-28
CREATE INDEX idx_fact_sales_date ON fact_sales USING BRIN (sold_at);
CREATE INDEX idx_fact_sales_customer ON fact_sales (customer_id);
CREATE INDEX idx_dim_product_sku ON dim_product (sku);
CREATE INDEX idx_high_value_sales ON fact_sales (amount) WHERE amount > 1000;
