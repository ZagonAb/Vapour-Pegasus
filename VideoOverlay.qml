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

    // Señales para comunicar cambios
    signal fullscreenChanged(bool fullscreen)
    signal muteStateChanged(bool muted)
    signal videoFinished()  // Señal para cuando el video termina

    // Video player
    Video {
        id: videoPlayer
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        autoPlay: false
        loops: MediaPlayer.Once  // Cambiado de Infinite a Once
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
                console.log("Video loaded successfully")
            } else if (status === MediaPlayer.Loading) {
                console.log("Loading video...")
            } else if (status === MediaPlayer.InvalidMedia) {
                console.log("Invalid video media")
            } else if (status === MediaPlayer.EndOfMedia) {
                console.log("Video reached end of media")
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
                // Verificar si terminó naturalmente
                if (videoPlayer.position >= videoPlayer.duration - 100) {
                    handleVideoEnd()
                }
            }
        }

        // Detectar cuando el video llega al final
        onPositionChanged: {
            if (duration > 0 && position >= duration - 100) {
                console.log("Video is about to end")
            }
        }
    }

    // Función para manejar el fin del video
    function handleVideoEnd() {
        console.log("Handling video end - Video finished naturally")
        isPlaying = false

        // Si estaba en fullscreen, salir de él
        if (isFullscreen) {
            isFullscreen = false
            videoPlayer.fillMode = VideoOutput.PreserveAspectCrop
            fullscreenChanged(false)
        }

        // Reiniciar el video a la posición inicial para que esté listo para reproducir de nuevo
        videoPlayer.seek(0)

        // Emitir señal de que el video terminó (al final para asegurar que todo esté listo)
        videoFinished()
    }

    // Funciones de control
    function togglePlayPause() {
        if (!videoPlayer.source || videoPlayer.source === "") {
            console.log("No video available")
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
        console.log("Mute toggled. isMuted:", isMuted, "volume:", volume)
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
        console.log("Stop function called")
        videoPlayer.stop()
        isPlaying = false

        // Forzar opacidad a 0 inmediatamente
        videoPlayer.opacity = 0

        // Al detener, también salir de fullscreen
        if (isFullscreen) {
            isFullscreen = false
            videoPlayer.fillMode = VideoOutput.PreserveAspectCrop
            fullscreenChanged(false)
        }

        // Reiniciar posición del video
        videoPlayer.seek(0)

        // IMPORTANTE: Emitir señal videoFinished al final para que DetailsView reciba la notificación
        videoFinished()
    }

    // Detener el video cuando cambia el juego
    onCurrentGameChanged: {
        if (isPlaying) {
            stop()
        }
    }

    // Para asegurar que el estado sea consistente
    onIsMutedChanged: {
        console.log("isMuted property changed to:", isMuted)
    }
}
