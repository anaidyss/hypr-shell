pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Calendar events with optional reminders, stored in ~/.local/state/hypr-shell/events.json.
// An event: { id, date: "YYYY-MM-DD", time: "HH:MM" or "" (all day), title, remind: minutes before or -1, fired }
// All-day events are due at 09:00; a reminder that is long overdue is dropped silently instead of fired.
Singleton {
    id: root

    property var list: []
    readonly property var byDate: {
        const m = ({})
        for (const e of list) m[e.date] = (m[e.date] || 0) + 1
        return m
    }

    readonly property int allDayHour: 9

    function start() { check() }

    function pad(n) { return (n < 10 ? "0" : "") + n }

    function key(d) { return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) }

    function forDate(k) {
        return list.filter(e => e.date === k).sort((a, b) => a.time < b.time ? -1 : (a.time > b.time ? 1 : 0))
    }

    // The next events from `now` on: timed ones until half an hour after they start, all-day ones for the whole day.
    function upcoming(n, now) {
        const from = now.getTime() - 30 * 60000
        return list.map(e => ({ e: e, at: baseTime(e) }))
            .filter(x => x.e.time !== "" ? x.at.getTime() >= from : x.e.date >= key(now))
            .sort((a, b) => a.at - b.at)
            .slice(0, n)
            .map(x => x.e)
    }

    function whenLabel(e, now) {
        const tomorrow = new Date(now.getTime() + 86400000)
        const day = e.date === key(now) ? "Today" : (e.date === key(tomorrow) ? "Tomorrow" : Qt.locale("en_US").toString(baseTime(e), "ddd d"))
        return e.time !== "" ? day + " " + e.time : day
    }

    function remindChoices(timed) { return timed ? [-1, 0, 5, 15, 60, 1440] : [-1, 0, 1440] }

    function remindLabel(minutes, timed) {
        if (minutes < 0) return "No reminder"
        if (!timed) return minutes === 0 ? "At 09:00" : "Day before"
        if (minutes === 0) return "At time"
        if (minutes === 1440) return "1 day before"
        if (minutes === 60) return "1 hour before"
        return minutes + " min before"
    }

    function add(date, time, title, remind) {
        const e = { id: Date.now().toString(36) + Math.random().toString(36).slice(2, 6), date: date, time: time, title: title, remind: remind, fired: false }
        list = list.concat([e])
        save()
        check()
    }

    function remove(id) {
        list = list.filter(e => e.id !== id)
        save()
    }

    function save() { store.setText(JSON.stringify(list)) }

    function baseTime(e) {
        const p = e.date.split("-")
        const t = e.time !== "" ? e.time.split(":") : [allDayHour, 0]
        return new Date(+p[0], +p[1] - 1, +p[2], +t[0], +t[1])
    }

    function check() {
        const now = new Date()
        let changed = false
        const next = list.map(e => {
            if (e.fired || e.remind < 0) return e
            const base = baseTime(e)
            if (now < new Date(base.getTime() - e.remind * 60000)) return e
            const grace = e.time !== "" ? 3600000 : 14 * 3600000
            if (now.getTime() - base.getTime() <= grace) notify(e)
            changed = true
            return Object.assign({}, e, { fired: true })
        })
        if (changed) {
            list = next
            save()
        }
    }

    function notify(e) {
        const body = e.time !== ""
            ? (e.remind > 0 ? e.time + " · in " + (e.remind >= 1440 ? "1 day" : e.remind >= 60 ? "1 hour" : e.remind + " min") : e.time)
            : "All day · " + e.date
        Quickshell.execDetached(["notify-send", "-a", "Calendar", "-i", "appointment-soon", e.title, body])
    }

    FileView {
        id: store
        path: Quickshell.env("HOME") + "/.local/state/hypr-shell/events.json"
        printErrors: false
        onLoaded: {
            try { root.list = JSON.parse(text()) } catch (err) { root.list = [] }
            root.check()
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: root.check()
    }
}
