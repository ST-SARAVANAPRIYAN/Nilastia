pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Nilastia
import Nilastia.Config
import qs.utils

Singleton {
    id: root

    property int locationIndex: 0

    readonly property var locationsList: [
        { name: "Karur", query: GlobalConfig.services.weatherLocation || "Karur", subtitle: "Tamil Nadu, India", isF1: false },
        { name: "Tokyo", query: "Tokyo", subtitle: "Japan", isF1: false }
    ]

    readonly property int totalLocations: locationsList.length

    // Active location properties
    property string city: "Karur"
    property string loc: ""
    property string subtitle: "Tamil Nadu, India"
    property bool isCurrentF1: false
    property var cc: null
    property list<var> forecast: []
    property list<var> hourlyForecast: []

    property bool ipApiRequestPending: false
    property double ipApiBlockedUntil: 0
    property bool citiesLoaded: false
    property string pendingCoords

    readonly property string icon: cc ? Icons.getWeatherIcon(cc.weatherCode) : "cloud_alert"
    readonly property string description: cc?.weatherDesc ?? qsTr("No weather")
    readonly property string temp: formatTemp(cc?.tempC)
    readonly property string feelsLike: formatTemp(cc?.feelsLikeC)
    readonly property int humidity: cc?.humidity ?? 0
    readonly property real windSpeed: cc?.windSpeed ?? 0
    readonly property string sunrise: cc ? Qt.formatDateTime(new Date(cc.sunrise), GlobalConfig.services.useTwelveHourClock ? "h:mm A" : "h:mm") : "--:--"
    readonly property string sunset: cc ? Qt.formatDateTime(new Date(cc.sunset), GlobalConfig.services.useTwelveHourClock ? "h:mm A" : "h:mm") : "--:--"

    readonly property var cachedCities: new Map()
    property var locationDataMap: ({})

    function formatTemp(temp: var): string {
        return GlobalConfig.services.useFahrenheit ? `${temp !== undefined ? Math.round(toFahrenheit(temp)) : "--"}°F` : `${temp !== undefined ? Math.round(temp) : "--"}°C`;
    }

    function toFahrenheit(celcius: real): real {
        return celcius * 9 / 5 + 32;
    }

    function nextLocation(): void {
        setLocationIndex((locationIndex + 1) % locationsList.length);
    }

    function prevLocation(): void {
        setLocationIndex((locationIndex - 1 + locationsList.length) % locationsList.length);
    }

    function setLocationIndex(idx: int): void {
        if (idx < 0 || idx >= locationsList.length)
            return;
        locationIndex = idx;
        applyLocationData(idx);
    }

    function applyLocationData(idx: int): void {
        const data = locationDataMap[idx];
        const locInfo = locationsList[idx];
        if (data && data.loaded) {
            city = data.city || locInfo.name;
            subtitle = locInfo.subtitle || "";
            isCurrentF1 = false;
            cc = data.cc;
            forecast = data.forecast || [];
            hourlyForecast = data.hourlyForecast || [];
        } else {
            city = locInfo.name;
            subtitle = locInfo.subtitle || "";
            isCurrentF1 = false;
            cc = null;
            forecast = [];
            hourlyForecast = [];
            fetchLocationWeather(idx);
        }
    }

    function reload(): void {
        refreshAllLocations();
    }

    function refreshAllLocations(): void {
        for (let i = 0; i < locationsList.length; i++) {
            fetchLocationWeather(i);
        }
    }

    function fetchLocationWeather(index: int): void {
        const locInfo = locationsList[index];
        if (!locInfo) return;

        const cityNameQuery = locInfo.query.split(",")[0].trim();
        const lang = Qt.locale().name.split("_")[0] || "en";
        const geoUrl = `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(cityNameQuery)}&count=1&language=${lang}&format=json`;

        Requests.get(geoUrl, geoText => {
            try {
                const geoJson = JSON.parse(geoText);
                if (geoJson.results && geoJson.results.length > 0) {
                    const res = geoJson.results[0];
                    const lat = res.latitude;
                    const lon = res.longitude;
                    const resolvedCity = fixCityName(res.name);
                    fetchOpenMeteoData(index, lat, lon, resolvedCity);
                } else {
                    console.warn(lc, `Geocoding returned no results for query "${cityNameQuery}"`);
                }
            } catch (e) {
                console.error(lc, `Geocoding parse error for query "${cityNameQuery}": ${e}`);
            }
        }, err => {
            console.error(lc, `Geocoding request failed for query "${cityNameQuery}": ${err}`);
        });
    }

    function fetchOpenMeteoData(index: int, lat: real, lon: real, cityName: string): void {
        const baseUrl = "https://api.open-meteo.com/v1/forecast";
        const params = [
            `latitude=${lat}`,
            `longitude=${lon}`,
            "hourly=weather_code,temperature_2m,precipitation_probability",
            "daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset",
            "current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m",
            "timezone=auto",
            "forecast_days=7"
        ];
        const url = baseUrl + "?" + params.join("&");

        Requests.get(url, text => {
            try {
                const json = JSON.parse(text);
                if (!json.current || !json.daily)
                    return;

                const curCC = {
                    weatherCode: json.current.weather_code,
                    weatherDesc: getWeatherCondition(json.current.weather_code),
                    tempC: json.current.temperature_2m,
                    feelsLikeC: json.current.apparent_temperature,
                    humidity: json.current.relative_humidity_2m,
                    windSpeed: json.current.wind_speed_10m,
                    isDay: json.current.is_day,
                    sunrise: json.daily.sunrise[0].replace("T", " "),
                    sunset: json.daily.sunset[0].replace("T", " ")
                };

                const forecastList = [];
                for (let i = 0; i < json.daily.time.length; i++) {
                    forecastList.push({
                        date: json.daily.time[i].replace(/-/g, "/"),
                        maxTempC: json.daily.temperature_2m_max[i],
                        minTempC: json.daily.temperature_2m_min[i],
                        weatherCode: json.daily.weather_code[i],
                        icon: Icons.getWeatherIcon(json.daily.weather_code[i])
                    });
                }

                const hourlyList = [];
                const now = new Date();
                for (let i = 0; i < json.hourly.time.length; i++) {
                    const time = new Date(json.hourly.time[i].replace("T", " "));
                    if (time < now) continue;
                    hourlyList.push({
                        timestamp: json.hourly.time[i],
                        hour: time.getHours(),
                        tempC: Math.round(json.hourly.temperature_2m[i]),
                        precipChance: json.hourly.precipitation_probability[i],
                        weatherCode: json.hourly.weather_code[i],
                        icon: Icons.getWeatherIcon(json.hourly.weather_code[i])
                    });
                }

                const map = Object.assign({}, locationDataMap);
                map[index] = {
                    loaded: true,
                    city: cityName,
                    cc: curCC,
                    forecast: forecastList,
                    hourlyForecast: hourlyList
                };
                locationDataMap = map;

                if (index === locationIndex) {
                    applyLocationData(index);
                }
            } catch (err) {
                console.error(lc, `Error parsing open-meteo response for index ${index}: ${err}`);
            }
        });
    }

    function fixCityName(cityName: string): string {
        if (!cityName)
            return "";
        const mapping = {
            "Poznan": "Poznań", "Wroclaw": "Wrocław", "Krakow": "Kraków",
            "Gdansk": "Gdańsk", "Lodz": "Łódź", "Munchen": "München",
            "Koln": "Köln", "Dusseldorf": "Düsseldorf", "Sao Paulo": "São Paulo",
            "Montreal": "Montréal"
        };
        return mapping[cityName] || cityName;
    }

    function getWeatherCondition(code: string): string {
        const conditions = {
            "0": "Clear", "1": "Clear", "2": "Partly cloudy", "3": "Overcast",
            "45": "Fog", "48": "Fog", "51": "Drizzle", "53": "Drizzle",
            "55": "Drizzle", "56": "Freezing drizzle", "57": "Freezing drizzle",
            "61": "Light rain", "63": "Rain", "65": "Heavy rain",
            "71": "Light snow", "73": "Snow", "75": "Heavy snow",
            "80": "Light rain", "81": "Rain", "82": "Heavy rain",
            "95": "Thunderstorm", "96": "Thunderstorm with hail", "99": "Thunderstorm with hail"
        };
        return conditions[code] || "Unknown";
    }

    Component.onCompleted: reload()

    Timer {
        interval: 1800000 // 30 minutes
        running: true
        repeat: true
        onTriggered: reload()
    }

    LoggingCategory {
        id: lc
        name: "nilastia.qml.services.weather"
        defaultLogLevel: LoggingCategory.Info
    }
}
