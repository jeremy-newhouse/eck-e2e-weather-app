document
  .getElementById("search-form")
  .addEventListener("submit", async function (event) {
    event.preventDefault();

    var city = document.getElementById("city-input").value;
    var resultEl = document.getElementById("result");

    // Clear previous result on each submission
    resultEl.textContent = "";

    var url = "/api/weather/" + encodeURIComponent(city.trim());

    try {
      var response = await fetch(url);

      if (response.ok) {
        var data = await response.json();

        var cityEl = document.createElement("p");
        cityEl.textContent = "City: " + data.city;

        var tempEl = document.createElement("p");
        tempEl.textContent = "Temperature: " + data.temperature;

        var descEl = document.createElement("p");
        descEl.textContent = "Description: " + data.description;

        var humidityEl = document.createElement("p");
        humidityEl.textContent = "Humidity: " + data.humidity;

        resultEl.appendChild(cityEl);
        resultEl.appendChild(tempEl);
        resultEl.appendChild(descEl);
        resultEl.appendChild(humidityEl);
      } else {
        var errorData = await response.json();
        resultEl.textContent = errorData.error || "An error occurred.";
      }
    } catch (err) {
      resultEl.textContent = "Network error: unable to reach the server.";
    }
  });
