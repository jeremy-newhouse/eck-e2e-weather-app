"use strict";

const express = require("express");
const path = require("path");

const app = express();

app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

app.use("/api", require("./routes/weather"));

app.use(express.static(path.join(__dirname, "public")));

module.exports = app;

if (require.main === module) {
  app.listen(3000, () => console.log("Server running on port 3000"));
}
