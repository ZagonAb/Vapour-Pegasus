import QtQuick 2.15
import QtMultimedia 5.15

Item {
    id: videoOverlay
    anchors.fill: parent

    property var currentGame: null
    property bool isPlaying: false
    property bool isMuted: false
    property bool isFullscreen: false
    property real volume: isMuted ? 0.0 : 0.5

    signal fullscreenChanged(bool fullscreen)
    signal muteStateChanged(bool muted)
    signal videoFinished()

    Video {
        id: videoPlayer
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        autoPlay: false
        loops: MediaPlayer.Once
        volume: videoOverlay.volume

        source: {
            if (currentGame && currentGame.assets && currentGame.assets.video) {
                return currentGame.assets.video
            }
            return ""
        }

        opacity: 0

        Behavior on opacity {
            NumberAnimation { duration: 500; easing.type: Easing.InOutQuad }
        }

        onStatusChanged: {
            if (status === MediaPlayer.Loaded) {
            } else if (status === MediaPlayer.Loading) {
            } else if (status === MediaPlayer.InvalidMedia) {
            } else if (status === MediaPlayer.EndOfMedia) {
                handleVideoEnd()
            }
        }

        onPlaybackStateChanged: {
            if (playbackState === MediaPlayer.PlayingState) {
                isPlaying = true
                opacity = 1
            } else if (playbackState === MediaPlayer.PausedState) {
                isPlaying = false
            } else if (playbackState === MediaPlayer.StoppedState) {
                isPlaying = false
                opacity = 0
                if (videoPlayer.position >= videoPlayer.duration - 100) {
                    handleVideoEnd()
                }
            }
        }

        onPositionChanged: {
            if (duration > 0 && position >= duration - 100) {
            }
        }
    }

    function handleVideoEnd() {
        isPlaying = false

        if (isFullscreen) {
            isFullscreen = false
            videoPlayer.fillMode = VideoOutput.PreserveAspectCrop
            fullscreenChanged(false)
        }

        videoPlayer.seek(0)

        videoFinished()
    }

    function togglePlayPause() {
        if (!videoPlayer.source || videoPlayer.source === "") {
            return
        }

        if (isPlaying) {
            videoPlayer.pause()
        } else {
            videoPlayer.play()
        }
    }

    function toggleMute() {
        isMuted = !isMuted
        if (isMuted) {
            volume = 0.0
        } else {
            volume = 0.5
        }
        muteStateChanged(isMuted)
    }

    function toggleFullscreen() {
        isFullscreen = !isFullscreen
        fullscreenChanged(isFullscreen)

        if (isFullscreen) {
            videoPlayer.fillMode = VideoOutput.PreserveAspectFit
        } else {
            videoPlayer.fillMode = VideoOutput.PreserveAspectCrop
        }
    }

    function stop() {
        videoPlayer.stop()
        isPlaying = false
        videoPlayer.opacity = 0

        if (isFullscreen) {
            isFullscreen = false
            videoPlayer.fillMode = VideoOutput.PreserveAspectCrop
            fullscreenChanged(false)
        }

        videoPlayer.seek(0)

        videoFinished()
    }

    onCurrentGameChanged: {
        if (isPlaying) {
            stop()
        }
    }

    onIsMutedChanged: {
    }
}
