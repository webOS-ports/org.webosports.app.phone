/*
 * Copyright (C) 2013 Christophe Chapuis <chris.chapuis@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

import QtQuick 2.0

import "LunaServiceRegistering.js" as LSRegisteredMethods

QtObject {
    id: service

    property string name
    property string method
    property bool usePrivateBus: false
    property string service

    property string currentSimState: "pinrequired"

    signal response(variant message)
    signal initialized
    signal error(string message)

    Component.onCompleted: {
        initialized();
    }

    function call(serviceURI, jsonArgs, returnFct, handleError) {
        console.log("LunaService::call called with serviceURI=" + serviceURI + ", args=" + jsonArgs);
        var args = JSON.parse(jsonArgs);
        if( serviceURI === "luna://com.palm.applicationManager/listLaunchPoints" ) {
            listLaunchPoints_call(args, returnFct, handleError);
        }
        else {
            // Embed the jsonArgs into a payload message
            var message = { applicationId: "org.webosports.tests.dummyWindow", payload: jsonArgs };
            if( !(LSRegisteredMethods.executeMethod(serviceURI, message)) ) {
                if (handleError)
                    handleError("unrecognized call: " + serviceURI);
            }
        }
    }

    function subscribe(serviceURI, jsonArgs, returnFct, handleError) {
        if( arguments.length === 1 ) {
            // handle the short form of subscribe
            return subscribe(service+"/"+method, arguments[0],
                             function(data) { console.log("Test2"); service.response(data); },
                             function(message) { console.log("test3"); service.error(message) });
        }
        else if(arguments.length === 3 ) {
            // handle the intermediate form of subscribe
            return subscribe(service+"/"+method, arguments[0], arguments[1], arguments[2]);
        }

        var args = JSON.parse(jsonArgs);
        if( serviceURI === "palm://com.palm.bus/signal/registerServerStatus" ||
            serviceURI === "luna://com.palm.bus/signal/registerServerStatus" )
        {
            returnFct({"payload": JSON.stringify({"connected": true})});
        }
        else if (serviceURI === "luna://com.palm.telephony/simStatusQuery") {
            var simState = {
                "subscribed": true,
                "returnValue":true,
                "extended": { "state": "pinrequired" }
            };

            var respData = {"payload": JSON.stringify(simState)};

            returnFct(respData);
        }
        else if (serviceURI === "palm://com.palm.bus/signal/addmatch" )
        {
            LSRegisteredMethods.addRegisteredMethod("palm://" + name + args.category + "/" + args.name, returnFct);
            returnFct({"payload": JSON.stringify({"subscribed": true})}); // simulate subscription answer
        }
    }

    function registerMethod(category, fct, callback) {
        console.log("registering " + "luna://" + name + category + fct);
        LSRegisteredMethods.addRegisteredMethod("luna://" + name + category + fct, callback);
    }

    function addSubscription() {
        /* do nothing */
    }

    function replyToSubscribers(path, callerAppId, jsonArgs) {
        console.log("replyToSubscribers " + "luna://" + name + path);
        LSRegisteredMethods.executeMethod("luna://" + name + path, {"applicationId": callerAppId, "payload": jsonArgs});
    }
}
