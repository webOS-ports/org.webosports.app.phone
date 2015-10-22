import QtQuick 2.0

Item {
    property ListModel voiceCalls: ListModel {}
    property ListModel providers: ListModel {}

    property string defaultProviderId: "provider"

    property Item activeVoiceCall: Item {}

    property string audioMode: "normal"
    property bool isAudioRouted: true
    property bool isMicrophoneMuted: false
    property bool isSpeakerMuted: false

    signal error(string message);

    signal defaultProviderChanged();

    signal audioRoutedChanged();
    signal microphoneMutedChanged();
    signal speakerMutedChanged();

    function dial(providerId, msisdn)
    {
        console.log("--> dial: providerId=" + providerId + " msisdn=" + msisdn);
    }

    function silenceRingtone()
    {
        console.log("--> silenceRingtone");
    }

    function setAudioMode(mode)
    {
        console.log("--> setAudioMode mode="+mode);
    }
    function setAudioRouted(isOn)
    {
        console.log("--> setAudioRouted on="+isOn);
    }
    function setMuteMicrophone(isOn)
    {
        console.log("--> setMuteMicrophone on="+isOn);
    }
    function setMuteSpeaker(isOn)
    {
        console.log("--> setMuteSpeaker on="+isOn);
    }

    function startDtmfTone(tone)
    {
        console.log("--> startDtmfTone tone="+tone);
    }
    function stopDtmfTone()
    {
        console.log("--> stopDtmfTone");
    }

}
