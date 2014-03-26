import QtQuick 2.0

Item {

    property Person john: Person{displayLabel: "John Smith"}
    property Person steve: Person{displayLabel: "Steve Brown"}
    property Person tom: Person{displayLabel: "Tom Slater"}

    function personByPhoneNumber(remoteUid){
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
