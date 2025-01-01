let goldPriceContainer, closeBtn, filterDayBtn, filterWeekBtn, filterMonthBtn, fullChartBtn;
let lineChartBtn, barChartBtn, areaChartBtn, goldAndSilverChart;
let chartType = 'line';
let goldHistory = [];
let silverHistory = [];

function createCombinedChart(ctx, goldData, silverData) {
    const labels = goldData.map(entry => new Date(entry.timestamp).toLocaleString());
    const goldPrices = goldData.map(entry => parseFloat(entry.price));
    const silverPrices = silverData.map(entry => parseFloat(entry.price));

    const goldMaxPrice = Math.max(...goldPrices);
    const goldMinPrice = Math.min(...goldPrices);

    const silverMaxPrice = Math.max(...silverPrices);
    const silverMinPrice = Math.min(...silverPrices);

    const goldPointColors = goldPrices.map(price => {
        if (price === goldMaxPrice) return 'green';
        if (price === goldMinPrice) return 'red';
        return '#f0c674';
    });

    const goldBarColors = goldPrices.map(price => {
        if (price === goldMaxPrice) return 'green';
        if (price === goldMinPrice) return 'red';
        return '#f0c674';
    });

    const silverPointColors = silverPrices.map(price => {
        if (price === silverMaxPrice) return 'green';
        if (price === silverMinPrice) return 'red';
        return '#c0c0c0';
    });

    const silverBarColors = silverPrices.map(price => {
        if (price === silverMaxPrice) return 'green';
        if (price === silverMinPrice) return 'red';
        return '#c0c0c0';
    });

    return new Chart(ctx, {
        type: chartType === 'area' ? 'line' : chartType,
        data: {
            labels,
            datasets: [
                {
                    label: "Gold",
                    data: goldPrices,
                    borderColor: '#f0c674',
                    backgroundColor: chartType === 'bar' ? goldBarColors : 'rgba(240, 198, 116, 0.2)',
                    borderWidth: 2,
                    tension: 0.3,
                    fill: chartType === 'area' ? 'start' : false,
                    pointBackgroundColor: chartType !== 'bar' ? goldPointColors : undefined,
                    pointRadius: chartType !== 'bar' ? goldPrices.map(price => (price === goldMaxPrice || price === goldMinPrice ? 6 : 3.5)) : undefined,
                    pointHoverRadius: chartType !== 'bar' ? 9 : undefined,
                },
                {
                    label: "Silver",
                    data: silverPrices,
                    borderColor: '#c0c0c0',
                    backgroundColor: chartType === 'bar' ? silverBarColors : 'rgba(192, 192, 192, 0.2)',
                    borderWidth: 2,
                    tension: 0.3,
                    fill: chartType === 'area' ? 'start' : false,
                    pointBackgroundColor: chartType !== 'bar' ? silverPointColors : undefined,
                    pointRadius: chartType !== 'bar' ? silverPrices.map(price => (price === silverMaxPrice || price === silverMinPrice ? 6 : 3.5)) : undefined,
                    pointHoverRadius: chartType !== 'bar' ? 9 : undefined,
                },
            ],
        },
        options: {
            responsive: true,
            plugins: {
                legend: {
                    display: true,
                    position: 'top',
                    labels: { color: '#ffffff' },
                },
                tooltip: {
                    callbacks: {
                        title: function (tooltipItems) {
                            const index = tooltipItems[0].dataIndex;
                            return labels[index];
                        },
                        label: function (tooltipItem) {
                            const pointValue = tooltipItem.raw;
                            return `Prezzo: $${pointValue.toFixed(2)}`;
                        },
                    },
                    backgroundColor: '#1c1f2b',
                    titleColor: '#ffffff',
                    bodyColor: '#ffffff',
                },
            },
            scales: {
                x: {
                    ticks: { display: false },
                    grid: { display: false },
                },
                y: {
                    ticks: { color: '#ffffff' },
                    grid: { color: 'rgba(240, 198, 116, 0.2)' },
                },
            },
        },
    });
}

function regenerateChart(goldData, silverData) {
    const ctx = document.getElementById("goldPriceChart").getContext("2d");
    if (goldAndSilverChart) goldAndSilverChart.destroy();
    goldAndSilverChart = createCombinedChart(ctx, goldData, silverData);
}

function filterHistory(history, filterFunction) {
    return filterFunction(history);
}

function filterLastDay(history) {
    return history.slice(-12);
}
function filterLastWeek(history) {
    return history.slice(-84);
}
function filterLastMonth(history) {
    return history.slice(-360);
}

function setActiveButton(button, buttons) {
    buttons.forEach(btn => btn.classList.remove("active"));
    button.classList.add("active");
}

function updatePriceInfo(prices) {
    if (!prices || prices.length === 0) return;

    const originPrice = prices[0];
    const minPrice = Math.min(...prices);
    const maxPrice = Math.max(...prices);
    const currentPrice = prices[prices.length - 1];
    const previousPrice = prices[prices.length - 2] || currentPrice;

    const difference = previousPrice !== 0 ? ((currentPrice - previousPrice) / previousPrice) * 100 : 0;

    document.getElementById("origin-price").textContent = `$${originPrice.toFixed(2)}`;
    document.getElementById("min-price").textContent = `$${minPrice.toFixed(2)}`;
    document.getElementById("max-price").textContent = `$${maxPrice.toFixed(2)}`;
    document.getElementById("current-price").textContent = `$${currentPrice.toFixed(2)}`;

    const diffElement = document.getElementById("price-difference");
    diffElement.textContent = `${difference >= 0 ? '+' : ''}${difference.toFixed(2)}%`;
    diffElement.className = `price-difference ${difference >= 0 ? "positive" : "negative"}`;
}

function updateSilverPriceInfo(prices) {
    if (!prices || prices.length === 0) return;

    const originPrice = prices[0];
    const minPrice = Math.min(...prices);
    const maxPrice = Math.max(...prices);
    const currentPrice = prices[prices.length - 1];
    const previousPrice = prices[prices.length - 2] || currentPrice;

    const difference = previousPrice !== 0 ? ((currentPrice - previousPrice) / previousPrice) * 100 : 0;

    document.getElementById("silver-origin-price").textContent = `$${originPrice.toFixed(2)}`;
    document.getElementById("silver-min-price").textContent = `$${minPrice.toFixed(2)}`;
    document.getElementById("silver-max-price").textContent = `$${maxPrice.toFixed(2)}`;
    document.getElementById("silver-current-price").textContent = `$${currentPrice.toFixed(2)}`;

    const diffElement = document.getElementById("silver-price-difference");
    diffElement.textContent = `${difference >= 0 ? '+' : ''}${difference.toFixed(2)}%`;
    diffElement.className = `price-difference ${difference >= 0 ? "positive" : "negative"}`;
}

function openGoldAndSilverPriceHistory(goldData, silverData) {
    goldHistory = goldData;
    silverHistory = silverData;

    regenerateChart(goldHistory, silverHistory);
    updatePriceInfo(goldData.map(entry => parseFloat(entry.price)));
    updateSilverPriceInfo(silverData.map(entry => parseFloat(entry.price)));

    document.getElementById("gold-price-container").classList.remove("hidden");
}

document.addEventListener("DOMContentLoaded", () => {
    goldPriceContainer = document.getElementById("gold-price-container");
    closeBtn = document.getElementById("close-btn");
    filterDayBtn = document.getElementById("filter-day-btn");
    filterWeekBtn = document.getElementById("filter-week-btn");
    filterMonthBtn = document.getElementById("filter-month-btn");
    fullChartBtn = document.getElementById("full-chart-btn");
    lineChartBtn = document.getElementById("line-chart-btn");
    barChartBtn = document.getElementById("bar-chart-btn");
    areaChartBtn = document.getElementById("area-chart-btn");

    const timeFilterButtons = [filterDayBtn, filterWeekBtn, filterMonthBtn, fullChartBtn];
    const chartTypeButtons = [lineChartBtn, barChartBtn, areaChartBtn];

    closeBtn.addEventListener("click", () => {
        goldPriceContainer.classList.add("hidden");
        fetch(`https://${GetParentResourceName()}/closeNUI`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({}),
        });
    });

    filterDayBtn.addEventListener("click", () => {
        const filteredGold = filterLastDay(goldHistory);
        const filteredSilver = filterLastDay(silverHistory);
    
        regenerateChart(filteredGold, filteredSilver);
        updatePriceInfo(filteredGold.map(entry => parseFloat(entry.price)));
        updateSilverPriceInfo(filteredSilver.map(entry => parseFloat(entry.price)));
        setActiveButton(filterDayBtn, timeFilterButtons);
    });
    filterWeekBtn.addEventListener("click", () => {
        regenerateChart(filterLastWeek(goldHistory), filterLastWeek(silverHistory));
        setActiveButton(filterWeekBtn, timeFilterButtons);
    });
    filterMonthBtn.addEventListener("click", () => {
        regenerateChart(filterLastMonth(goldHistory), filterLastMonth(silverHistory));
        setActiveButton(filterMonthBtn, timeFilterButtons);
    });
    fullChartBtn.addEventListener("click", () => {
        regenerateChart(goldHistory, silverHistory);
        setActiveButton(fullChartBtn, timeFilterButtons);
    });

    lineChartBtn.addEventListener("click", () => {
        chartType = 'line';
        regenerateChart(goldHistory, silverHistory);
        setActiveButton(lineChartBtn, chartTypeButtons);
    });
    barChartBtn.addEventListener("click", () => {
        chartType = 'bar';
        regenerateChart(goldHistory, silverHistory);
        setActiveButton(barChartBtn, chartTypeButtons);
    });
    areaChartBtn.addEventListener("click", () => {
        chartType = 'area';
        regenerateChart(goldHistory, silverHistory);
        setActiveButton(areaChartBtn, chartTypeButtons);
    });

    window.addEventListener("message", (event) => {
        if (event.data.type === "openGoldAndSilverPriceHistory") {
            openGoldAndSilverPriceHistory(event.data.goldHistory, event.data.silverHistory);
        }
    });
});