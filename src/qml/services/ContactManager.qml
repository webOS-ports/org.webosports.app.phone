import QtQuick 2.0
import "../model"

QtObject {
    property Contact john: Contact{displayLabel: "John Smith"}
    property Contact steve: Contact{displayLabel: "Steve Brown"}
    property Contact tom: Contact{displayLabel: "Tom Slater"}

    function personByPhoneNumber(remoteUid){
        console.log("Looking up Contact for remoteID: " + remoteUid)
        switch(remoteUid){
        case "1234567890":
            return john
        case "235892382":
            return steve
        case "81235892382":
            return tom
        default:
            return null
        }

    }

}
