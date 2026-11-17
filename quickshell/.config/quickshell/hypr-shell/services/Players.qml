pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The media player the shell talks to: the one picked by the user, else a playing one, else the first.
Singleton {
    id: root

    readonly property var list: Mpris.players.values
    property string chosen: ""

    readonly property var player: {
        if (chosen !== "") for (const p of list) if (p.dbusName === chosen) return p
        for (const p of list) if (p.isPlaying) return p
        return list.length > 0 ? list[0] : null
    }

    readonly property bool has: player !== null
    readonly property bool playing: player !== null && player.isPlaying
    readonly property string title: player ? (player.trackTitle !== "" ? player.trackTitle : player.identity) : ""
    readonly property string artist: player ? player.trackArtist : ""
    readonly property string album: player ? player.trackAlbum : ""
    readonly property string art: player ? player.trackArtUrl : ""
    readonly property bool canSeek: player !== null && player.canSeek && player.positionSupported && player.lengthSupported && player.length > 0
    readonly property real ratio: player !== null && player.lengthSupported && player.length > 0 && player.positionSupported
        ? Math.max(0, Math.min(1, player.position / player.length)) : 0

    readonly property int index: {
        for (let i = 0; i < list.length; i++) if (list[i] === player) return i
        return -1
    }

    // Human name of a player: the desktop entry's name, else the identity without a trailing app id.
    function name(p) {
        if (!p) return ""
        const e = p.desktopEntry ? DesktopEntries.heuristicLookup(p.desktopEntry) : null
        if (e && e.name) return e.name
        return p.identity.replace(/\s+[a-z][a-z0-9_-]*(\.[a-z0-9_-]+)+$/i, "")
    }

    function clock(s) {
        s = Math.max(0, s)
        const m = Math.floor(s / 60), sec = Math.floor(s % 60)
        return m + ":" + (sec < 10 ? "0" : "") + sec
    }

    // Position is not pushed by the player, so whoever shows it calls this while visible.
    function refreshPosition() {
        if (player) player.positionChanged()
    }

    function seekTo(ratio) {
        if (!canSeek) return
        player.position = Math.max(0, Math.min(1, ratio)) * player.length
    }

    function pick(p) { chosen = p ? p.dbusName : "" }

    function cycle() {
        if (list.length < 2) return
        pick(list[(index + 1) % list.length])
    }

    function cycleLoop() {
        if (!player || !player.loopSupported) return
        const s = player.loopState
        player.loopState = s === MprisLoopState.None ? MprisLoopState.Playlist
            : (s === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None)
    }

    function toggleShuffle() {
        if (player && player.shuffleSupported) player.shuffle = !player.shuffle
    }
}
