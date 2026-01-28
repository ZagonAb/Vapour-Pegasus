import QtQuick 2.15
import QtMultimedia 5.15

Item {
    id: soundManager

    property SoundEffect navigationSound: SoundEffect {
        source: "assets/sound/navigation.wav"
        volume: 0.7
    }

    /*property SoundEffect upSound: SoundEffect {
        source: "assets/sound/up.wav"
        volume: 0.7
    }

    property SoundEffect downSound: SoundEffect {
        source: "assets/sound/ok.wav"
        volume: 0.7
    }

    property SoundEffect cancelSound: SoundEffect {
        source: "assets/sound/cancel.wav"
        volume: 0.7
    }

    property SoundEffect noticeSound: SoundEffect {
        source: "assets/sound/notice.wav"
        volume: 0.7
    }

    property SoundEffect noticeBackSound: SoundEffect {
        source: "assets/sound/notice_back.wav"
        volume: 0.7
    }*/

    function play(soundEffect) {
        if (soundEffect && soundEffect.source !== "") {
            soundEffect.play()
        }
    }

    /*function playUp() { play(upSound) }
    function playDown() { play(downSound) }
    function playCancel() { play(cancelSound) }
    function playNotice() { play(noticeSound) }
    function playNoticeBack() { play(noticeBackSound) }*/
    function playNavigation() { play(navigationSound) }
}
