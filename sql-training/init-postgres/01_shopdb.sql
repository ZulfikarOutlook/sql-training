-- ShopDB training database: schema + sample data
-- Runs automatically on the first start of the postgres container.
SELECT setseed(0.42);   -- same "random" data for every student

-- ---------- Schema ----------
CREATE TABLE categories (
    category_id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        text NOT NULL UNIQUE,
    parent_id   int REFERENCES categories(category_id)
);

CREATE TABLE customers (
    customer_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name  text NOT NULL,
    last_name   text NOT NULL,
    email       text NOT NULL,
    phone       text,
    city        text,
    country     text,
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE products (
    product_id  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        text NOT NULL,
    category_id int REFERENCES categories(category_id),
    price       numeric(10,2) NOT NULL,
    stock_qty   int,
    is_active   boolean NOT NULL DEFAULT true,
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE orders (
    order_id     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id  bigint NOT NULL REFERENCES customers(customer_id),
    order_date   timestamptz NOT NULL DEFAULT now(),
    status       text NOT NULL DEFAULT 'pending',
    total_amount numeric(12,2) NOT NULL DEFAULT 0,
    shipped_at   timestamptz
);

CREATE TABLE order_items (
    order_item_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id      bigint NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id    bigint NOT NULL REFERENCES products(product_id),
    quantity      int NOT NULL,
    unit_price    numeric(10,2) NOT NULL
);

CREATE TABLE payments (
    payment_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id   bigint NOT NULL REFERENCES orders(order_id),
    amount     numeric(12,2) NOT NULL,
    method     text NOT NULL,
    paid_at    timestamptz NOT NULL
);

CREATE TABLE employees (
    employee_id int PRIMARY KEY,
    full_name   text NOT NULL,
    job_title   text NOT NULL,
    manager_id  int REFERENCES employees(employee_id),
    hire_date   date NOT NULL,
    salary      numeric(10,2) NOT NULL
);

CREATE TABLE reviews (
    review_id   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id  bigint NOT NULL REFERENCES products(product_id),
    customer_id bigint REFERENCES customers(customer_id),
    rating      smallint NOT NULL,
    comment     text,
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE accounts (             -- used in the Day 5 transaction examples
    account_id int PRIMARY KEY,
    owner      text NOT NULL,
    balance    numeric(12,2) NOT NULL
);

-- ---------- Data ----------
INSERT INTO categories (name) VALUES ('Electronics'), ('Home & Kitchen'), ('Books'), ('Fashion'),
                                     ('Sports'), ('Toys'), ('Discontinued');
INSERT INTO categories (name, parent_id)
SELECT v.name, c.category_id
FROM (VALUES ('Phones'), ('Tablets'), ('Accessories')) AS v(name)
CROSS JOIN categories c WHERE c.name = 'Electronics';
INSERT INTO categories (name, parent_id)
SELECT 'Phone Cases', category_id FROM categories WHERE name = 'Accessories';

INSERT INTO customers (first_name, last_name, email, phone, city, country, created_at)
SELECT fn, ln,
       lower(fn) || '.' || lower(ln) || g || '@' ||
         (ARRAY['gmail.com','yahoo.com','outlook.com','ideax.lk','mail.lk','mail.kw'])[1 + floor(random()*6)::int],
       CASE WHEN random() < 0.2 THEN NULL ELSE '077' || lpad(floor(random()*10000000)::int::text, 7, '0') END,
       city,
       CASE WHEN city IN ('Kuwait City','Hawalli','Salmiya') THEN 'Kuwait'
            WHEN city IS NULL THEN NULL ELSE 'Sri Lanka' END,
       now() - (random() * interval '1100 days')
FROM (
  SELECT g,
         (ARRAY['Nimal','Ayesha','Kamal','Fatima','Ravi','Priya','Ahmed','Sara','Dilan','Nadia',
                'Suresh','Mariam','Tharindu','Zainab','Kasun','Leila','Arjun','Hana','Isuru','Omar'])[1 + floor(random()*20)::int] AS fn,
         (ARRAY['Perera','Fernando','Silva','Khan','Jayasinghe','Rahman','Fonseka','Hussain',
                'Wickramasinghe','Al-Sabah','Bandara','Nair','Mendis','Farook','Dias'])[1 + floor(random()*15)::int] AS ln,
         CASE WHEN random() < 0.05 THEN NULL
              ELSE (ARRAY['Colombo','Colombo','Colombo','Kandy','Galle','Jaffna','Negombo',
                          'Kuwait City','Hawalli','Salmiya'])[1 + floor(random()*10)::int] END AS city
  FROM generate_series(1, 500) g
) s;

INSERT INTO products (name, category_id, price, stock_qty, is_active, created_at)
SELECT m.brand || ' ' || m.noun || m.suffix || ' ' || m.g,
       c.category_id,
       round((m.base * (0.5 + random() * 1.5))::numeric, 2),
       CASE WHEN random() < 0.05 THEN NULL ELSE floor(random() * 300)::int END,
       random() > 0.1,
       now() - (random() * interval '1200 days')
FROM (
  SELECT m0.g, m0.brand, m0.suffix, x.cat, x.noun, x.base
  FROM (
  SELECT g,
         (ARRAY['Acme','Nova','Zen','Orbit','Lumo'])[1 + floor(random()*5)::int] AS brand,
         (ARRAY['',' Pro',' Lite',' Max',' Mini'])[1 + floor(random()*5)::int]    AS suffix,
         (ARRAY[0,0,0,0,1,2,2,2,2,3,4,5,6,7,8,9,10])[1 + floor(random()*17)::int] AS k
  FROM generate_series(1, 200) g
) m0
JOIN (VALUES (0,'Phones','Phone',60000), (1,'Tablets','Tablet',80000), (2,'Accessories','Charger',3000),
               (3,'Phone Cases','Case',1500), (4,'Home & Kitchen','Blender',9000), (5,'Books','Novel',1200),
               (6,'Fashion','T-Shirt',2500), (7,'Sports','Football',4000), (8,'Toys','Puzzle',1800),
               (9,'Electronics','Headphones',12000), (10,'Discontinued','Legacy Item',500))
       AS x(k, cat, noun, base) ON x.k = m0.k
) m
JOIN categories c ON c.name = m.cat;

INSERT INTO orders (customer_id, order_date, status)
SELECT 1 + floor(random() * 450)::int,        -- customers 451-500 never order
       now() - (random() * interval '900 days'),
       CASE WHEN r < 0.60 THEN 'delivered' WHEN r < 0.70 THEN 'shipped' WHEN r < 0.78 THEN 'paid'
            WHEN r < 0.85 THEN 'pending' ELSE 'cancelled' END
FROM (SELECT random() AS r FROM generate_series(1, 5000)) s;

UPDATE orders SET shipped_at = order_date + (1 + random() * 3) * interval '1 day'
WHERE status IN ('shipped', 'delivered');

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT x.order_id, p.product_id, x.qty, p.price
FROM (
  SELECT o.order_id,
         1 + floor(random() * 180)::int AS pid,   -- products 181-200 are never ordered
         1 + floor(random() * 3)::int   AS qty
  FROM orders o
  CROSS JOIN LATERAL generate_series(1, 1 + floor(random() * 4)::int + (o.order_id * 0)::int)
) x
JOIN products p ON p.product_id = x.pid;

UPDATE orders o SET total_amount = t.total
FROM (SELECT order_id, sum(quantity * unit_price) AS total FROM order_items GROUP BY order_id) t
WHERE t.order_id = o.order_id;

INSERT INTO payments (order_id, amount, method, paid_at)
SELECT order_id, total_amount,
       (ARRAY['card','cash','bank_transfer'])[1 + floor(random()*3)::int],
       order_date + random() * interval '2 hours'
FROM orders
WHERE status IN ('paid','shipped','delivered') AND random() > 0.03;   -- a few paid orders miss a payment row

INSERT INTO employees (employee_id, full_name, job_title, manager_id, hire_date, salary) VALUES
 (1,  'Zahir Hameed',       'CEO',                 NULL, '2016-01-10', 950000),
 (2,  'Anoma Perera',       'Head of Operations',  1,    '2017-03-01', 520000),
 (3,  'Faisal Rahman',      'Head of Technology',  1,    '2018-06-15', 560000),
 (4,  'Chamari Silva',      'Warehouse Manager',   2,    '2019-02-11', 280000),
 (5,  'Imran Khan',         'Customer Care Lead',  2,    '2020-08-03', 240000),
 (6,  'Dilshan Fernando',   'Engineering Manager', 3,    '2019-11-20', 420000),
 (7,  'Rukshana Farook',    'Senior Developer',    6,    '2020-01-06', 330000),
 (8,  'Kavindu Bandara',    'Developer',           6,    '2023-04-17', 190000),
 (9,  'Aisha Nair',         'Developer',           6,    '2024-09-02', 170000),
 (10, 'Pradeep Jayasinghe', 'Store Keeper',        4,    '2021-05-12', 120000),
 (11, 'Hussain Ali',        'Driver',              4,    '2022-07-25', 95000),
 (12, 'Nethmi Dias',        'Support Agent',       5,    '2024-01-15', 110000),
 (13, 'Yusuf Mendis',       'Support Agent',       5,    '2025-06-30', 105000),
 (14, 'Tharushi Wick',      'Junior Developer',    7,    '2025-10-01', 140000),
 (15, 'Omar Al-Sabah',      'QA Engineer',         6,    '2022-02-14', 200000);

INSERT INTO reviews (product_id, customer_id, rating, comment, created_at)
SELECT DISTINCT ON (product_id, customer_id) product_id, customer_id, rating, comment, created_at
FROM (
  SELECT 1 + floor(random() * 170)::int AS product_id,   -- products 171-200 have no reviews
         1 + floor(random() * 500)::int AS customer_id,
         (ARRAY[1,2,3,3,4,4,4,5,5,5])[1 + floor(random()*10)::int] AS rating,
         CASE WHEN random() < 0.3 THEN NULL
              ELSE (ARRAY['Great value','Works as expected','Arrived late','Excellent quality',
                          'Not worth the price','Would buy again'])[1 + floor(random()*6)::int] END AS comment,
         now() - (random() * interval '800 days') AS created_at
  FROM generate_series(1, 1500)
) r;

INSERT INTO accounts VALUES (1, 'Nimal Perera', 100000), (2, 'Ayesha Khan', 50000);

-- ---------- Large table for Day 5 performance labs (no extra indexes on purpose) ----------
CREATE TABLE big_orders (
    order_id     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id  bigint NOT NULL,
    order_date   timestamptz NOT NULL,
    status       text NOT NULL,
    total_amount numeric(12,2) NOT NULL
);
INSERT INTO big_orders (customer_id, order_date, status, total_amount)
SELECT 1 + floor(random() * 500)::int,
       now() - (random() * interval '1000 days'),
       CASE WHEN r < 0.90 THEN 'delivered' WHEN r < 0.94 THEN 'shipped' WHEN r < 0.96 THEN 'pending'
            ELSE 'cancelled' END,
       round((100 + random() * 50000)::numeric, 2)
FROM (SELECT random() AS r FROM generate_series(1, 200000)) s;

ANALYZE;
