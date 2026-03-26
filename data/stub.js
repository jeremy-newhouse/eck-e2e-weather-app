"use strict";

/** @type {Record<string, { city: string, temperature: number, description: string, humidity: number }>} */
const WEATHER_MAP = {
  london: {
    city: "London",
    temperature: 12,
    description: "Partly cloudy",
    humidity: 78,
  },
  miami: { city: "Miami", temperature: 28, description: "Sunny", humidity: 65 },
  tokyo: { city: "Tokyo", temperature: 18, description: "Clear", humidity: 55 },
};

/**
 * Look up stub weather data for a city.
 *
 * @param {string} city
 * @returns {{ city: string, temperature: number, description: string, humidity: number } | null}
 */
function getWeather(city) {
  const key = city.toLowerCase();
  return WEATHER_MAP[key] ?? null;
}

module.exports = { getWeather };
