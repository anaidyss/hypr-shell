pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme
import "weather.js" as W

// Current weather and a short forecast for the dashboard.
// Place: the typed city (geocoded) or, when empty, found by IP. Source: pinned in settings, or tried in turn
// (CMA first in China, then Open-Meteo, MET Norway, wttr.in). The last good answer is kept in weather.json for 30 minutes.
Singleton {
    id: root

    readonly property string city: Theme.cfg.dashboard.weatherCity
    readonly property string sourcePref: Theme.cfg.dashboard.weatherSource
    readonly property string units: Theme.cfg.dashboard.weatherUnits
    readonly property string queryKey: city.trim() + "|" + sourcePref

    readonly property int maxAge: 30 * 60 * 1000

    property var data: null
    property string place: ""
    property real updatedAt: 0
    property string cachedKey: ""
    property bool loading: false
    property string error: ""

    // Data of another city (after the setting changed) is never shown while the new one loads.
    readonly property bool has: data !== null && cachedKey.split("|")[0] === city.trim()
    readonly property string cond: has ? data.cond : ""
    readonly property bool isDay: has ? data.isDay : true
    readonly property string icon: has ? W.icon(data.cond, data.isDay) : "cloud"
    readonly property string text: has ? W.label(data.cond) : ""
    readonly property string source: has ? data.source : ""
    readonly property var daily: has ? data.daily : []
    readonly property var hourly: has && data.hourly ? data.hourly : []

    property bool wanted: false
    property bool busy: false
    property bool again: false
    property var geo: null
    property var pending: null

    function convert(c) { return units === "imperial" ? c * 9 / 5 + 32 : c }
    function deg(c) { return c === null || c === undefined || isNaN(c) ? "—" : Math.round(convert(c)) + "°" }
    function wind(kmh) {
        if (kmh === null || kmh === undefined || isNaN(kmh)) return "—"
        return units === "imperial" ? Math.round(kmh / 1.609) + " mph" : Math.round(kmh) + " km/h"
    }
    function pressure(hpa) {
        if (hpa === null || hpa === undefined || isNaN(hpa)) return "—"
        return units === "imperial" ? (hpa * 0.02953).toFixed(2) + " inHg" : Math.round(hpa) + " hPa"
    }
    function rain(mm) {
        if (mm === null || mm === undefined || isNaN(mm)) return "—"
        if (units === "imperial") return (mm / 25.4).toFixed(2) + " in"
        return (mm < 10 ? mm.toFixed(1) : Math.round(mm)) + " mm"
    }
    function percent(v) { return v === null || v === undefined || isNaN(v) ? "—" : Math.round(v) + "%" }
    function weekday(date) {
        return Qt.locale("en_US").dayName(new Date(date + "T12:00:00").getDay(), Locale.ShortFormat)
    }
    function iconFor(cond, day) { return W.icon(cond, day) }

    // Called by whatever shows the weather; fetches only when the data is stale or the settings changed.
    function ensure() {
        wanted = true
        if (has && cachedKey === queryKey && Date.now() - updatedAt < maxAge) return
        refresh()
    }

    function refresh() {
        if (busy) { again = true; return }
        busy = true
        loading = true
        const key = queryKey
        locate((loc, err) => {
            if (!loc) return finish(key, null, null, err)
            const list = W.order(sourcePref, loc.cc)
            tryProviders(key, loc, list, 0)
        })
    }

    function locate(done) {
        const want = city.trim()
        if (want !== "") {
            if (geo && geo.name === want) return done(geo.loc, "")
            get(W.geocodeUrl(want), t => {
                let loc = null
                try { loc = W.parseGeocode(t) } catch (e) {}
                if (!loc) return done(null, t === "" ? "No connection" : "City not found")
                const remember = () => { geo = { name: want, loc: loc, at: Date.now() }; done(loc, "") }
                if (W.isLatin(loc.name)) return remember()
                get(W.englishNameUrl(loc.id), n => {
                    try { loc.name = W.parseEnglishName(n) || loc.name } catch (e) {}
                    remember()
                })
            })
        } else {
            if (geo && geo.name === "" && Date.now() - geo.at < 6 * 3600 * 1000) return done(geo.loc, "")
            tryIp(0, done)
        }
    }

    function tryIp(i, done) {
        if (i >= W.IP_LOOKUPS.length) return done(null, "Could not detect the location")
        get(W.IP_LOOKUPS[i].url, t => {
            let loc = null
            try { loc = W.parseIp(i, t) } catch (e) {}
            if (loc) { geo = { name: "", loc: loc, at: Date.now() }; done(loc, "") }
            else tryIp(i + 1, done)
        })
    }

    function tryProviders(key, loc, list, i) {
        if (i >= list.length) return finish(key, loc, null, "No weather source reachable")
        const req = W.request(list[i], loc)
        get(req.url, t => {
            let d = null
            try { d = req.parse(t) } catch (e) {}
            if (d) finish(key, loc, d, "")
            else tryProviders(key, loc, list, i + 1)
        })
    }

    function finish(key, loc, d, err) {
        busy = false
        loading = false
        if (d) {
            data = d
            place = loc.name
            updatedAt = Date.now()
            cachedKey = key
            error = ""
            save()
        } else {
            error = err
        }
        if (again) { again = false; refresh() }
    }

    function get(url, done) {
        pending = done
        http.command = ["curl", "-sS", "--fail", "-L", "-m", "10", "-A", "hypr-shell/0.1 (personal dotfiles)", url]
        http.running = true
    }

    Process {
        id: http
        stdout: StdioCollector {
            onStreamFinished: {
                const f = root.pending
                root.pending = null
                if (f) f(text)
            }
        }
    }

    onQueryKeyChanged: if (wanted) refresh()

    function save() {
        store.setText(JSON.stringify({ key: cachedKey, at: updatedAt, place: place, data: data }))
    }

    FileView {
        id: store
        path: Quickshell.env("HOME") + "/.local/state/hypr-shell/weather.json"
        blockLoading: true
        printErrors: false
    }

    Component.onCompleted: {
        try {
            const c = JSON.parse(store.text())
            // Caches written before the hourly forecast existed are refetched
            if (c.data && c.data.hourly) { data = c.data; place = c.place; updatedAt = c.at; cachedKey = c.key }
        } catch (e) {}
    }
}
