document
  .getElementById("search-form")
  .addEventListener("submit", async function (event) {
    event.preventDefault();

    const city = document.getElementById("city-input").value;
    const resultEl = document.getElementById("result");

    resultEl.textContent = "";

    const url = "/api/weather/" + encodeURIComponent(city.trim());

    try {
      const response = await fetch(url);

      if (response.ok) {
        const data = await response.json();

        for (const [label, value] of [
          ["City", data.city],
          ["Temperature", data.temperature],
          ["Description", data.description],
          ["Humidity", data.humidity],
        ]) {
          const el = document.createElement("p");
          el.textContent = label + ": " + value;
          resultEl.appendChild(el);
        }
      } else {
        const errorData = await response.json();
        resultEl.textContent = errorData.error || "An error occurred.";
      }
    } catch {
      resultEl.textContent = "Network error: unable to reach the server.";
    }
  });
