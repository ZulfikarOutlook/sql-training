// ShopDB sample data for MongoDB (Day 6). Runs automatically on the first start of the mongo container.
db = db.getSiblingDB("shopdb");

db.customers.insertMany([
  { _id: 1, name: "Nimal Perera",    email: "nimal@example.lk",  city: "Colombo" },
  { _id: 2, name: "Ayesha Khan",     email: "ayesha@example.kw", city: "Kuwait City" },
  { _id: 3, name: "Ravi Fernando",   email: "ravi@example.lk",   city: "Kandy" },
  { _id: 4, name: "Fatima Rahman",   email: "fatima@example.lk", city: "Galle" },
  { _id: 5, name: "Omar Hussain",    email: "omar@example.kw",   city: "Salmiya" },
  { _id: 6, name: "Priya Nair",      email: "priya@example.lk",  city: "Colombo" },
  { _id: 7, name: "Kasun Bandara",   email: "kasun@example.lk",  city: "Negombo" },
  { _id: 8, name: "Sara Al-Sabah",   email: "sara@example.kw",   city: "Hawalli" }
]);

db.products.insertMany([
  { _id: 1,  name: "Acme Phone X",      category: "Phones",      price: 45000, stock: 25,  attributes: { color: "black", storage_gb: 128 }, tags: ["5g", "new"] },
  { _id: 2,  name: "Nova Phone Lite",   category: "Phones",      price: 32000, stock: 40,  attributes: { color: "blue", storage_gb: 64 },   tags: ["sale"] },
  { _id: 3,  name: "Zen Phone Pro",     category: "Phones",      price: 89000, stock: 8,   attributes: { color: "silver", storage_gb: 256 }, tags: ["5g", "premium"] },
  { _id: 4,  name: "Acme Tab S",        category: "Tablets",     price: 72000, stock: 10,  attributes: { color: "silver", screen_in: 11 } },
  { _id: 5,  name: "Orbit Tab Mini",    category: "Tablets",     price: 48000, stock: 0,   attributes: { color: "grey", screen_in: 8.3 }, tags: ["clearance"] },
  { _id: 6,  name: "Acme Case",         category: "Accessories", price: 1500,  stock: 200, attributes: { fits: ["Acme Phone X"], material: "silicone" }, tags: ["sale"] },
  { _id: 7,  name: "Charger 20W",       category: "Accessories", price: 3000,  stock: 80 },
  { _id: 8,  name: "Lumo Earbuds",      category: "Accessories", price: 9500,  stock: 60,  attributes: { color: "white", battery_h: 6 }, tags: ["new"] },
  { _id: 9,  name: "Zen Blender 600",   category: "Home & Kitchen", price: 11000, stock: 15, attributes: { watts: 600, jar_l: 1.5 } },
  { _id: 10, name: "Nova Rice Cooker",  category: "Home & Kitchen", price: 8500,  stock: 22, attributes: { capacity_l: 1.8 } },
  { _id: 11, name: "SQL for Beginners", category: "Books",       price: 2400,  stock: 35,  attributes: { author: "A. Writer", pages: 320 } },
  { _id: 12, name: "Orbit Football",    category: "Sports",      price: 4200,  stock: 50,  attributes: { size: 5 } },
  { _id: 13, name: "Acme T-Shirt",      category: "Fashion",     price: 2500,  stock: 120, attributes: { sizes: ["S", "M", "L", "XL"], color: "red" } },
  { _id: 14, name: "Lumo Puzzle 1000",  category: "Toys",        price: 1900,  stock: 3,   tags: ["new"] },
  { _id: 15, name: "Zen Yoga Mat",      category: "Sports",      price: 5200,  stock: 18,  attributes: { color: "green", thickness_mm: 6 } }
]);

// 300 orders with embedded items (a snapshot of name and price at the time of sale)
const products = db.products.find().toArray();
const statuses = ["delivered", "delivered", "delivered", "shipped", "paid", "pending", "cancelled"];
const orders = [];
for (let i = 1; i <= 300; i++) {
  const items = [];
  const lines = 1 + Math.floor(Math.random() * 3);
  for (let j = 0; j < lines; j++) {
    const p = products[Math.floor(Math.random() * products.length)];
    items.push({ product_id: p._id, name: p.name, qty: 1 + Math.floor(Math.random() * 3), unit_price: p.price });
  }
  orders.push({
    _id: i,
    customer_id: 1 + Math.floor(Math.random() * 8),
    order_date: new Date(Date.now() - Math.floor(Math.random() * 540) * 86400000),
    status: statuses[Math.floor(Math.random() * statuses.length)],
    items: items,
    total: items.reduce((sum, it) => sum + it.qty * it.unit_price, 0)
  });
}
db.orders.insertMany(orders);

db.orders.createIndex({ customer_id: 1, order_date: -1 });
print("ShopDB (MongoDB) loaded: " + db.orders.countDocuments() + " orders");
