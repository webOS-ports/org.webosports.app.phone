// Ported from com.palm.app.phone source/telephonydialhandler/MmiService.js
// GSM supplementary-service (MMI) code tables, 3GPP TS 22.030.
//
// Each service code maps an MMI action (activate/deactivate/register/unregister/
// interrogate) onto a command name plus its arguments. Argument values of the form
// #{si.N} / #{ic.N} / #{bs.N} are substituted with the supplementary information the
// user typed (si), its matching bearer/info class (ic) or call-barring type (bs).

.pragma library

var MmiServiceCodes = {
    "04": {
        register: {
            cmd: "pin1Change",
            oldPin: "#{si.1}",
            newPin: "#{si.2}",
            newPinConfirm: "#{si.3}"
        }
    },
    "042": {
        register: {
            cmd: "pin2Change",
            oldPin: "#{si.1}",
            newPin: "#{si.2}",
            newPinConfirm: "#{si.3}"
        }
    },
    "05": {
        register: {
            cmd: "pin1Unblock",
            puk: "#{si.1}",
            newPin: "#{si.2}",
            newPinConfirm: "#{si.3}"
        }
    },
    "052": {
        register: {
            cmd: "pin2Unblock",
            puk2: "#{si.1}",
            newPin2: "#{si.2}",
            newPinConfirm: "#{si.3}"
        }
    },
    "002": {
        activate: {
            cmd: "forwardActivate",
            condition: "allforwarding",
            bearer: "#{ic.2}",
            activate: true
        },
        deactivate: {
            cmd: "forwardActivate",
            condition: "allforwarding",
            bearer: "#{ic.2}",
            activate: false
        },
        register: {
            cmd: "forwardRegister",
            number: "#{si.1}",
            condition: "allforwarding",
            bearer: "#{ic.2}",
            time: "#{si.3}"
        },
        unregister: {
            cmd: "forwardRegister",
            number: "",
            condition: "allforwarding",
            bearer: "#{ic.2}",
            time: "#{si.3}"
        },
        interrogate: {
            cmd: "forwardQuery",
            condition: "allforwarding",
            bearer: "#{ic.2}"
        }
    },
    "004": {
        activate: {
            cmd: "forwardActivate",
            condition: "allconditional",
            bearer: "#{ic.2}",
            activate: true
        },
        deactivate: {
            cmd: "forwardActivate",
            condition: "allconditional",
            bearer: "#{ic.2}",
            activate: false
        },
        register: {
            cmd: "forwardRegister",
            number: "#{si.1}",
            condition: "allconditional",
            bearer: "#{ic.2}",
            time: "#{si.3}"
        },
        unregister: {
            cmd: "forwardRegister",
            number: "",
            condition: "allconditional",
            bearer: "#{ic.2}",
            time: "#{si.3}"
        },
        interrogate: {
            cmd: "forwardQuery",
            condition: "allconditional",
            bearer: "#{ic.2}"
        }
    },
    "21": {
        activate: {
            cmd: "forwardActivate",
            condition: "unconditional",
            bearer: "#{ic.2}",
            activate: true
        },
        deactivate: {
            cmd: "forwardActivate",
            condition: "unconditional",
            bearer: "#{ic.2}",
            activate: false
        },
        register: {
            cmd: "forwardRegister",
            number: "#{si.1}",
            condition: "unconditional",
            bearer: "#{ic.2}",
            time: "#{si.3}"
        },
        unregister: {
            cmd: "forwardRegister",
            number: "",
            condition: "unconditional",
            bearer: "#{ic.2}",
            time: "#{si.3}"
        },
        interrogate: {
            cmd: "forwardQuery",
            condition: "unconditional",
            bearer: "#{ic.2}"
        }
    },
    "61": {
        activate: {
            cmd: "forwardActivate",
            condition: "noreply",
            bearer: "#{ic.2}",
            activate: true
        },
        deactivate: {
            cmd: "forwardActivate",
            condition: "noreply",
            bearer: "#{ic.2}",
            activate: false
        },
        register: {
            cmd: "forwardRegister",
            number: "#{si.1}",
            condition: "noreply",
            bearer: "#{ic.2}",
            time: "#{si.3}"
        },
        unregister: {
            cmd: "forwardRegister",
            number: "",
            condition: "noreply",
            bearer: "#{ic.2}",
            time: "#{si.3}"
        },
        interrogate: {
            cmd: "forwardQuery",
            condition: "noreply",
            bearer: "#{ic.2}"
        }
    },
    "62": {
        activate: {
            cmd: "forwardActivate",
            condition: "unreachable",
            bearer: "#{ic.2}",
            activate: true
        },
        deactivate: {
            cmd: "forwardActivate",
            condition: "unreachable",
            bearer: "#{ic.2}",
            activate: false
        },
        register: {
            cmd: "forwardRegister",
            number: "#{si.1}",
            condition: "unreachable",
            bearer: "#{ic.2}",
            time: "#{si.3}"
        },
        unregister: {
            cmd: "forwardRegister",
            number: "",
            condition: "unreachable",
            bearer: "#{ic.2}",
            time: "#{si.3}"
        },
        interrogate: {
            cmd: "forwardQuery",
            condition: "unreachable",
            bearer: "#{ic.2}"
        }
    },
    "67": {
        activate: {
            cmd: "forwardActivate",
            condition: "mobilebusy",
            bearer: "#{ic.2}",
            activate: true
        },
        deactivate: {
            cmd: "forwardActivate",
            condition: "mobilebusy",
            bearer: "#{ic.2}",
            activate: false
        },
        register: {
            cmd: "forwardRegister",
            number: "#{si.1}",
            condition: "mobilebusy",
            bearer: "#{ic.2}",
            time: "#{si.3}"
        },
        unregister: {
            cmd: "forwardRegister",
            number: "",
            condition: "mobilebusy",
            bearer: "#{ic.2}",
            time: "#{si.3}"
        },
        interrogate: {
            cmd: "forwardQuery",
            condition: "mobilebusy",
            bearer: "#{ic.2}"
        }
    },
    "43": {
        activate: {
            cmd: "callWaitingSet",
            bearer: "#{ic.1}",
            enable: true
        },
        deactivate: {
            cmd: "callWaitingSet",
            bearer: "#{ic.1}",
            enable: false
        },
        register: {
            cmd: "callWaitingSet",
            bearer: "#{ic.1}",
            enable: true
        },
        unregister: {
            cmd: "callWaitingSet",
            bearer: "#{ic.1}",
            enable: false
        },
        interrogate: {
            cmd: "callWaitingQuery",
            bearer: "#{ic.1}"
        }
    },
    "03": {
        activate: {
            cmd: "barringPasswordChange",
            condition: "#{bs.1}",
            oldpassword: "#{si.2}",
            newpassword: "#{si.3}",
            newpasswordconfirm: "#{si.4}"
        },
        register: {
            cmd: "barringPasswordChange",
            condition: "#{bs.1}",
            oldpassword: "#{si.2}",
            newpassword: "#{si.3}",
            newpasswordconfirm: "#{si.4}"
        }
    },
    "33": {
        activate: {
            cmd: "barringSet",
            condition: "baralloutgoing",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: true
        },
        deactivate: {
            cmd: "barringSet",
            condition: "baralloutgoing",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: false
        },
        register: {
            cmd: "barringSet",
            condition: "baralloutgoing",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: true
        },
        unregister: {
            cmd: "barringSet",
            condition: "baralloutgoing",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: false
        },
        interrogate: {
            cmd: "barringQuery",
            condition: "baralloutgoing",
            bearer: "#{ic.2}"
        }
    },
    "331": {
        activate: {
            cmd: "barringSet",
            condition: "baroutgoingint",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: true
        },
        deactivate: {
            cmd: "barringSet",
            condition: "baroutgoingint",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: false
        },
        register: {
            cmd: "barringSet",
            condition: "baroutgoingint",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: true
        },
        unregister: {
            cmd: "barringSet",
            condition: "baroutgoingint",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: false
        },
        interrogate: {
            cmd: "barringQuery",
            condition: "baroutgoingint",
            bearer: "#{ic.2}"
        }
    },
    "332": {
        activate: {
            cmd: "barringSet",
            condition: "baroutgoingintextohome",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: true
        },
        deactivate: {
            cmd: "barringSet",
            condition: "baroutgoingintextohome",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: false
        },
        register: {
            cmd: "barringSet",
            condition: "baroutgoingintextohome",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: true
        },
        unregister: {
            cmd: "barringSet",
            condition: "baroutgoingintextohome",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: false
        },
        interrogate: {
            cmd: "barringQuery",
            condition: "baroutgoingintextohome",
            bearer: "#{ic.2}"
        }
    },
    "35": {
        activate: {
            cmd: "barringSet",
            condition: "barallincoming",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: true
        },
        deactivate: {
            cmd: "barringSet",
            condition: "barallincoming",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: false
        },
        register: {
            cmd: "barringSet",
            condition: "barallincoming",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: true
        },
        unregister: {
            cmd: "barringSet",
            condition: "barallincoming",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: false
        },
        interrogate: {
            cmd: "barringQuery",
            condition: "barallincoming",
            bearer: "#{ic.2}"
        }
    },
    "351": {
        activate: {
            cmd: "barringSet",
            condition: "barincomingroaming",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: true
        },
        deactivate: {
            cmd: "barringSet",
            condition: "barincomingroaming",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: false
        },
        register: {
            cmd: "barringSet",
            condition: "barincomingroaming",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: true
        },
        unregister: {
            cmd: "barringSet",
            condition: "barincomingroaming",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: false
        },
        interrogate: {
            cmd: "barringQuery",
            condition: "barincomingroaming",
            bearer: "#{ic.2}"
        }
    },
    "330": {
        activate: {
            cmd: "barringSet",
            condition: "barallbarring",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: true
        },
        deactivate: {
            cmd: "barringSet",
            condition: "barallbarring",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: false
        },
        register: {
            cmd: "barringSet",
            condition: "barallbarring",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: true
        },
        unregister: {
            cmd: "barringSet",
            condition: "barallbarring",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: false
        },
        interrogate: {
            cmd: "barringQuery",
            condition: "barallbarring",
            bearer: "#{ic.2}"
        }
    },
    "333": {
        activate: {
            cmd: "barringSet",
            condition: "baroutgoing",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: true
        },
        deactivate: {
            cmd: "barringSet",
            condition: "baroutgoing",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: false
        },
        register: {
            cmd: "barringSet",
            condition: "baroutgoing",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: true
        },
        unregister: {
            cmd: "barringSet",
            condition: "baroutgoing",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: false
        },
        interrogate: {
            cmd: "barringQuery",
            condition: "baroutgoing",
            bearer: "#{ic.2}"
        }
    },
    "353": {
        activate: {
            cmd: "barringSet",
            condition: "barincoming",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: true
        },
        deactivate: {
            cmd: "barringSet",
            condition: "barincoming",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: false
        },
        register: {
            cmd: "barringSet",
            condition: "barincoming",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: true
        },
        unregister: {
            cmd: "barringSet",
            condition: "barincoming",
            bearer: "#{ic.2}",
            password: "#{si.1}",
            enable: false
        },
        interrogate: {
            cmd: "barringQuery",
            condition: "barincoming",
            bearer: "#{ic.2}"
        }
    },
    "30": {
        activate: {
            cmd: "clipSet",
            restrict: false
        },
        deactivate: {
            cmd: "clipSet",
            restrict: true
        },
        interrogate: {
            cmd: "clipQuery"
        }
    },
    "31": {
        activate: {
            cmd: "clirSet",
            restrict: true
        },
        deactivate: {
            cmd: "clirSet",
            restrict: false
        },
        register: {
            cmd: "clirSet",
            restrict: true
        },
        unregister: {
            cmd: "clirSet",
            restrict: false
        },
        interrogate: {
            cmd: "clirQuery"
        }
    },
    "300": {
        interrogate: {
            cmd: "cnapQuery"
        }
    },
    "06": {
        interrogate: {
            cmd: "imeiQuery"
        }
    },
};

var MmiInfoClass = {
    "11": "voice",
    "12": "data",
    "13": "fax",
    "16": "sms",
    "21": "allasyncservices",
    "22": "allsyncservices",
    "24": "datacircuitsync",
    "25": "datacircuitasync",
    "26": "packetaccess",
    "27": "padaccess",
    "89": "auxiliarytelephony"
};

var MmiInfoClassDefault = "defaultbearer";

// Call barring type
var MmiCallBarringType = {
    "33": "baralloutgoing",
    "331": "baroutgoingint",
    "332": "baroutgoingintextohome",
    "35": "barallincoming",
    "351": "barincomingroaming",
    "330": "barallbarring",
    "333": "baroutgoing",
    "353": "barincoming"
};

var MmiCallBarringTypeDefault = "barallservices";
