.pragma library

// Weather sources, all keyless and reachable from mainland China and Russia, normalized to one shape:
// { source, temp, feels, humidity, wind, pressure, uv, precip, sunrise, sunset, cond, isDay,
//   hourly: [{ t, cond, isDay, temp, pop }], daily: [{ date, cond, min, max, pop }] }  (°C, km/h, hPa, mm)
// `cond` is one of: clear, mostlyclear, partly, cloud, fog, drizzle, rain, heavyrain, sleet, snow, storm.
// `hourly` holds up to 8 points three hours apart, the first being now; `t` is the local time of the place
// as "YYYY-MM-DDTHH:MM". A value a source does not provide is null (`pop` is a percentage, `precip` is today's mm,
// `sunrise` and `sunset` are "HH:MM").

var SOURCES = [
    { id: "auto", label: "Automatic" },
    { id: "cma", label: "CMA (China)" },
    { id: "openmeteo", label: "Open-Meteo" },
    { id: "metno", label: "MET Norway" },
    { id: "wttr", label: "wttr.in" }
]

var NAMES = { cma: "CMA via Open-Meteo", openmeteo: "Open-Meteo", metno: "MET Norway", wttr: "wttr.in" }

var LABELS = {
    clear: "Clear", mostlyclear: "Mostly clear", partly: "Partly cloudy", cloud: "Overcast", fog: "Fog",
    drizzle: "Drizzle", rain: "Rain", heavyrain: "Heavy rain", sleet: "Sleet", snow: "Snow", storm: "Thunderstorm"
}

function label(cond) { return LABELS[cond] || "—" }

function icon(cond, isDay) {
    switch (cond) {
    case "clear": return isDay ? "sun" : "moon"
    case "mostlyclear":
    case "partly": return isDay ? "cloudSun" : "cloudMoon"
    case "fog": return "fog"
    case "drizzle":
    case "rain":
    case "heavyrain": return "rain"
    case "sleet":
    case "snow": return "snow"
    case "storm": return "storm"
    default: return "cloud"
    }
}

// Which sources to try and in what order. In China the CMA model comes first; a pinned source is the only one used.
function order(source, cc) {
    if (source && source !== "auto" && NAMES[source]) return [source]
    if (cc === "CN" || cc === "HK" || cc === "MO") return ["cma", "openmeteo", "metno", "wttr"]
    return ["openmeteo", "metno", "wttr"]
}

function wmo(code) {
    if (code === 0) return "clear"
    if (code === 1) return "mostlyclear"
    if (code === 2) return "partly"
    if (code === 3) return "cloud"
    if (code === 45 || code === 48) return "fog"
    if (code >= 51 && code <= 57) return "drizzle"
    if (code === 61 || code === 63 || code === 80 || code === 81) return "rain"
    if (code === 65 || code === 82) return "heavyrain"
    if (code === 66 || code === 67) return "sleet"
    if ((code >= 71 && code <= 77) || code === 85 || code === 86) return "snow"
    if (code >= 95) return "storm"
    return "cloud"
}

function metno(symbol) {
    const s = String(symbol || "").replace(/_(day|night|polartwilight)$/, "")
    if (/thunder/.test(s)) return "storm"
    if (/sleet/.test(s)) return "sleet"
    if (/snow/.test(s)) return "snow"
    if (/heavyrain/.test(s)) return "heavyrain"
    if (/rain/.test(s)) return "rain"
    if (/fog/.test(s)) return "fog"
    if (s === "clearsky") return "clear"
    if (s === "fair") return "mostlyclear"
    if (s === "partlycloudy") return "partly"
    return "cloud"
}

// World Weather Online codes (wttr.in); unknown ones fall back to the description text.
function wwo(code, desc) {
    const c = Number(code)
    if (c === 113) return "clear"
    if (c === 116) return "partly"
    if (c === 119 || c === 122) return "cloud"
    if (c === 143 || c === 248 || c === 260) return "fog"
    if (c === 263 || c === 266) return "drizzle"
    if ([176, 293, 296, 299, 302, 353].indexOf(c) >= 0) return "rain"
    if ([305, 308, 356, 359].indexOf(c) >= 0) return "heavyrain"
    if ([182, 185, 281, 284, 311, 314, 317, 350, 362, 365, 374, 377].indexOf(c) >= 0) return "sleet"
    if ([179, 227, 230, 323, 326, 329, 332, 335, 338, 368, 371].indexOf(c) >= 0) return "snow"
    if ([200, 386, 389, 392, 395].indexOf(c) >= 0) return "storm"
    const d = String(desc || "").toLowerCase()
    if (/thunder/.test(d)) return "storm"
    if (/sleet/.test(d)) return "sleet"
    if (/snow|blizzard/.test(d)) return "snow"
    if (/drizzle/.test(d)) return "drizzle"
    if (/rain|shower/.test(d)) return "rain"
    if (/fog|mist|haze|smoke/.test(d)) return "fog"
    if (/sunny|clear/.test(d)) return "clear"
    if (/partly/.test(d)) return "partly"
    return "cloud"
}

function enc(s) { return encodeURIComponent(s) }

function num(v) { return v === null || v === undefined || v === "" || isNaN(Number(v)) ? null : Number(v) }

function pad2(n) { return (n < 10 ? "0" : "") + n }

function fmtMin(m) { return pad2(Math.floor(m / 60) % 24) + ":" + pad2(m % 60) }

function hhmm(s) { return s ? String(s).slice(11, 16) : null }

// Local time of a place as "YYYY-MM-DDTHH:MM", from a UTC moment and the hour offset
function localStr(ms, offsetHours) { return new Date(ms + offsetHours * 3600000).toISOString().slice(0, 16) }

function geocodeUrl(name) {
    const lang = /[㐀-鿿]/.test(name) ? "zh" : (/[Ѐ-ӿ]/.test(name) ? "ru" : "en")
    return "https://geocoding-api.open-meteo.com/v1/search?count=1&format=json&language=" + lang + "&name=" + enc(name)
}

function parseGeocode(text) {
    const r = JSON.parse(text).results
    if (!r || r.length === 0) return null
    const p = r[0]
    return { id: p.id, name: p.name, lat: p.latitude, lon: p.longitude, cc: (p.country_code || "").toUpperCase(), country: p.country || "" }
}

// A place is always shown by its English name, whatever it was typed in.
function isLatin(name) { return !/[^\u0000-\u024f]/.test(name) }

function englishNameUrl(id) { return "https://geocoding-api.open-meteo.com/v1/get?language=en&id=" + id }

function parseEnglishName(text) {
    const n = JSON.parse(text).name
    return n ? String(n) : null
}

// IP lookups, tried in turn. Behind a VPN they report the VPN exit, so a typed city is preferred.
var IP_LOOKUPS = [
    { url: "https://ipwho.is/", parse: function (d) { return d.success === false ? null : { name: d.city, lat: d.latitude, lon: d.longitude, cc: d.country_code, country: d.country } } },
    { url: "http://ip-api.com/json/", parse: function (d) { return d.status !== "success" ? null : { name: d.city, lat: d.lat, lon: d.lon, cc: d.countryCode, country: d.country } } },
    { url: "https://ipinfo.io/json", parse: function (d) {
        const l = String(d.loc || "").split(",")
        return l.length < 2 ? null : { name: d.city, lat: Number(l[0]), lon: Number(l[1]), cc: d.country, country: d.country }
    } }
]

function parseIp(i, text) {
    const loc = IP_LOOKUPS[i].parse(JSON.parse(text))
    return loc && loc.name && isFinite(loc.lat) && isFinite(loc.lon) ? loc : null
}

function openMeteoUrl(loc, model) {
    return "https://api.open-meteo.com/v1/forecast?latitude=" + loc.lat + "&longitude=" + loc.lon
        + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,is_day,surface_pressure"
        + "&hourly=temperature_2m,weather_code,precipitation_probability,is_day"
        + "&daily=temperature_2m_max,temperature_2m_min,weather_code,sunrise,sunset,precipitation_sum,precipitation_probability_max,uv_index_max"
        + "&forecast_days=5&timezone=auto"
        + (model ? "&models=" + model : "")
}

function parseOpenMeteo(text, name) {
    const d = JSON.parse(text), c = d.current, D = d.daily
    if (!c || c.temperature_2m == null || c.weather_code == null) throw new Error("no current data")
    const at = function (a, i) { return a ? num(a[i]) : null }
    const daily = []
    for (let i = 0; i < D.time.length; i++) {
        if (D.temperature_2m_max[i] == null || D.temperature_2m_min[i] == null) continue
        daily.push({ date: D.time[i], cond: wmo(D.weather_code[i]), min: D.temperature_2m_min[i], max: D.temperature_2m_max[i], pop: at(D.precipitation_probability_max, i) })
    }

    const hourly = [], H = d.hourly
    if (H && H.time && c.time) {
        const now = String(c.time).slice(0, 13)
        let i = 0
        while (i < H.time.length && H.time[i].slice(0, 13) < now) i++
        for (; i < H.time.length && hourly.length < 8; i += 3) {
            if (H.temperature_2m[i] == null) break
            hourly.push({ t: H.time[i], cond: wmo(H.weather_code[i]), isDay: H.is_day ? H.is_day[i] === 1 : true, temp: H.temperature_2m[i], pop: at(H.precipitation_probability, i) })
        }
    }

    return {
        source: name, temp: c.temperature_2m, feels: num(c.apparent_temperature), humidity: num(c.relative_humidity_2m),
        wind: num(c.wind_speed_10m), pressure: num(c.surface_pressure), uv: at(D.uv_index_max, 0), precip: at(D.precipitation_sum, 0),
        sunrise: D.sunrise ? hhmm(D.sunrise[0]) : null, sunset: D.sunset ? hhmm(D.sunset[0]) : null,
        cond: wmo(c.weather_code), isDay: c.is_day === 1, hourly: hourly, daily: daily
    }
}

function metnoUrl(loc) {
    return "https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=" + loc.lat.toFixed(4) + "&lon=" + loc.lon.toFixed(4)
}

function parseMetno(text, loc) {
    const ts = JSON.parse(text).properties.timeseries
    if (!ts || ts.length === 0) throw new Error("no data")
    // Times are UTC; the place's own clock is approximated by its longitude
    const off = Math.round(loc.lon / 15)
    const first = ts[0].data, inst = first.instant.details
    const next = first.next_1_hours || first.next_6_hours
    const sym = next ? next.summary.symbol_code : "cloudy"
    const hourOf = function (ms) { return Number(localStr(ms, off).slice(11, 13)) }
    const dayOf = function (code, ms) {
        return /_night$/.test(code) ? false : (/_day$/.test(code) ? true : (hourOf(ms) >= 6 && hourOf(ms) < 18))
    }
    const t0 = new Date(ts[0].time).getTime()

    const days = {}, order = []
    for (const e of ts) {
        const ms = new Date(e.time).getTime(), k = localStr(ms, off).slice(0, 10)
        if (!days[k]) { days[k] = { date: k, min: 1e9, max: -1e9, best: null, bestGap: 1e9 }; order.push(k) }
        const day = days[k], v = e.data.instant.details.air_temperature
        if (v < day.min) day.min = v
        if (v > day.max) day.max = v
        const n = e.data.next_6_hours || e.data.next_1_hours
        const gap = Math.abs(hourOf(ms) - 12)
        if (n && gap < day.bestGap) { day.bestGap = gap; day.best = n.summary.symbol_code }
    }

    const hourly = []
    for (let k = 0; k < 8; k++) {
        const want = t0 + k * 3 * 3600000
        const e = ts.find(function (x) { return new Date(x.time).getTime() === want })
        if (!e) break
        const n = e.data.next_1_hours || e.data.next_6_hours
        const code = n ? n.summary.symbol_code : "cloudy"
        hourly.push({ t: localStr(want, off), cond: metno(code), isDay: dayOf(code, want), temp: e.data.instant.details.air_temperature, pop: null })
    }

    return {
        source: NAMES.metno, temp: inst.air_temperature, feels: null, humidity: num(inst.relative_humidity),
        wind: inst.wind_speed * 3.6, pressure: num(inst.air_pressure_at_sea_level), uv: null, precip: null, sunrise: null, sunset: null,
        cond: metno(sym), isDay: dayOf(sym, t0), hourly: hourly,
        daily: order.slice(0, 5).map(function (k) { return { date: k, cond: metno(days[k].best), min: days[k].min, max: days[k].max, pop: null } })
    }
}

function wttrUrl(loc) {
    return "https://wttr.in/" + loc.lat.toFixed(3) + "," + loc.lon.toFixed(3) + "?format=j1"
}

function clockMinutes(s) {
    const m = /(\d+):(\d+)\s*(AM|PM)/i.exec(String(s))
    if (!m) return -1
    return (Number(m[1]) % 12 + (m[3].toUpperCase() === "PM" ? 12 : 0)) * 60 + Number(m[2])
}

function parseWttr(text, loc) {
    const d = JSON.parse(text), c = d.current_condition[0]
    const desc = c.weatherDesc && c.weatherDesc[0] ? c.weatherDesc[0].value : ""
    const descOf = function (h) { return h.weatherDesc && h.weatherDesc[0] ? h.weatherDesc[0].value : "" }

    // observation_time is UTC; shift it to the place by longitude and compare with the local sunrise and sunset
    const utc = clockMinutes(c.observation_time)
    const local = utc >= 0 ? ((utc + Math.round(loc.lon / 15 * 60)) % 1440 + 1440) % 1440 : 720
    const bounds = function (w) {
        const a = w.astronomy && w.astronomy[0]
        return a ? { rise: clockMinutes(a.sunrise), set: clockMinutes(a.sunset) } : { rise: -1, set: -1 }
    }
    const dayAt = function (w, mins) {
        const b = bounds(w)
        return b.rise >= 0 && b.set >= 0 ? mins >= b.rise && mins < b.set : true
    }
    const maxChance = function (hs) {
        let m = null
        for (const h of hs) {
            const v = Math.max(num(h.chanceofrain) || 0, num(h.chanceofsnow) || 0)
            if (m === null || v > m) m = v
        }
        return m
    }

    // The 3-hour slots of all days in a row; start at the last one that is not in the future
    const slots = []
    d.weather.forEach(function (w, di) {
        (w.hourly || []).forEach(function (h) {
            const mins = Math.floor(Number(h.time) / 100) * 60 + Number(h.time) % 100
            slots.push({ at: di * 1440 + mins, mins: mins, w: w, h: h })
        })
    })
    let from = 0
    while (from + 1 < slots.length && slots[from + 1].at <= local) from++
    const hourly = slots.slice(from, from + 8).map(function (s) {
        return {
            t: s.w.date + "T" + fmtMin(Math.floor(s.mins / 60) * 60), cond: wwo(s.h.weatherCode, descOf(s.h)), isDay: dayAt(s.w, s.mins),
            temp: Number(s.h.tempC), pop: Math.max(num(s.h.chanceofrain) || 0, num(s.h.chanceofsnow) || 0)
        }
    })

    const w0 = d.weather[0], b0 = bounds(w0)
    let precip = 0
    for (const h of w0.hourly || []) precip += num(h.precipMM) || 0

    return {
        source: NAMES.wttr, temp: Number(c.temp_C), feels: num(c.FeelsLikeC), humidity: num(c.humidity),
        wind: num(c.windspeedKmph), pressure: num(c.pressure), uv: num(c.uvIndex), precip: precip,
        sunrise: b0.rise >= 0 ? fmtMin(b0.rise) : null, sunset: b0.set >= 0 ? fmtMin(b0.set) : null,
        cond: wwo(c.weatherCode, desc), isDay: dayAt(w0, local), hourly: hourly,
        daily: d.weather.map(function (w) {
            const noon = w.hourly[Math.min(4, w.hourly.length - 1)]
            return { date: w.date, cond: wwo(noon.weatherCode, descOf(noon)), min: Number(w.mintempC), max: Number(w.maxtempC), pop: maxChance(w.hourly || []) }
        })
    }
}

// What to fetch for a source: { url, parse(text) }.
function request(source, loc) {
    switch (source) {
    case "cma": return { url: openMeteoUrl(loc, "cma_grapes_global"), parse: function (t) { return parseOpenMeteo(t, NAMES.cma) } }
    case "openmeteo": return { url: openMeteoUrl(loc, ""), parse: function (t) { return parseOpenMeteo(t, NAMES.openmeteo) } }
    case "metno": return { url: metnoUrl(loc), parse: function (t) { return parseMetno(t, loc) } }
    case "wttr": return { url: wttrUrl(loc), parse: function (t) { return parseWttr(t, loc) } }
    }
    return null
}
