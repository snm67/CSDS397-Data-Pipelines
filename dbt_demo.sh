# Clone an already initialized project.
git clone https://github.com/dbt-labs/jaffle_shop_duckdb.git
cd jaffle_shop_duckdb
# Create a virtual python environment (to avoid conflicts)
python3 -m pip install --upgrade pip
python3 -m pip install -r requirements.txt
# DBT build will run the entire project.
dbt build
# Validate Models ran as expected
duckcli jaffle_shop.duckdb -e "SELECT * FROM orders;"
# DBT docs will generate the documentation based on the metadata from the project.
dbt docs generate
# DBT docs serve will publish the documentation as a website.
dbt docs serve --port 8082
# duckcli jaffle_shop.duckdb 
## select * from orders
