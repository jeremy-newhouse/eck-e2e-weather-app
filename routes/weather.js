"use strict";

const express = require("express");
const { getWeather } = require("../data/stub");

const router = express.Router();

/**
 * GET /api/weather/:city
 *
 * Returns weather data for the given city, or 404 if not found.
 *
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @returns {void}
 */
router.get("/weather/:city", (req, res) => {
  const city = req.params.city.toLowerCase().trim();
  const data = getWeather(city);

  if (data) {
    res.json(data);
  } else {
    res.status(404).json({ error: "City not found" });
  }
});

module.exports = router;
