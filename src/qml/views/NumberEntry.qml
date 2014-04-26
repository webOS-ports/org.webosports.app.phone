import QtQuick 2.0

Item {
    id:root

    property alias text:textedit.text
    property alias color:textedit.color
    property alias alignment:textedit.horizontalAlignment
    property alias inputMethodHints:textedit.inputMethodHints

    property string __previousCharacter

    function insertChar(character) {
        var text = textedit.text
        var cpos = textedit.cursorPosition;

        if(text.length == 0) {
            textedit.text = character
            textedit.cursorPosition = textedit.text.length
        } else {
            textedit.text = text.slice(0, cpos) + character + text.slice(cpos,text. length);
            textedit.cursorPosition = cpos + 1;
        }

        root.__previousCharacter = character;
        interactionTimeout.restart();
    }

    function backspace() {
        var cpos = textedit.cursorPosition == 0 ? 1 : textedit.cursorPosition;
        var text = textedit.text

        if(text.length == 0) return;

        textedit.text = text.slice(0, cpos - 1) + text.slice(cpos, text.length)
        textedit.cursorPosition = cpos - 1;

        root.__previousCharacter = '';
        interactionTimeout.restart();
    }

    function resetCursor() {
        textedit.cursorPosition = textedit.text.length;
        textedit.cursorVisible = false;
    }

    function clear() {

        resetCursor();
        textedit.text = '';
    }

    Timer {
        id:interactionTimeout
        interval:4000
        running:false
        repeat:false
        onTriggered:root.resetCursor();
    }

    Image {
        id:backspace

        anchors {verticalCenter:parent.verticalCenter;right:parent.right; margins:34}
        source: 'images/icon-m-common-backspace.svg'

        MouseArea {
            anchors.fill:parent

            onClicked: root.backspace();
            onPressAndHold: root.clear();
        }
    }

    TextEdit {
        id:textedit

        anchors {
            left:parent.left;right:backspace.left
            leftMargin:30;rightMargin:20
            verticalCenter:parent.verticalCenter
        }

        activeFocusOnPress: false
        cursorVisible:false
        inputMethodHints:Qt.ImhDialableCharactersOnly
        font.pixelSize:64//TODO:Theme
        horizontalAlignment:TextEdit.AlignRight

        onTextChanged:__resizeText();

        function __resizeText() {
            if(paintedWidth < 0 || paintedHeight < 0) return;

            while(paintedWidth > width) {
                if(font.pixelSize <= 0) break;
                font.pixelSize--;
            }

            while(paintedWidth < width) {
                if(font.pixelSize >= 72) break;
                font.pixelSize++;
            }
        }
    }

    MouseArea {
        anchors.fill:textedit

        onPressed: {
            textedit.cursorVisible = true;
            interactionTimeout.restart();
            mouse.accepted = false;
        }
    }
}
