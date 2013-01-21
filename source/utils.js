/**
 * Simple utility method to parse arguments from a string like
 * key=value&key=value... like they are passed as part of URIs.
 *
 * Copied under the terms of the Apache 2.0 from Enyo 1.0
 */
var parseUrlArgs = function(inUrlArgs) {
    var args = inUrlArgs.split("&");
    var outArgs = {};
    for (var i=0, a, nv; a=args[i]; i++) {
        nv = args[i] = a.split("=");
        outArgs[nv[0]] = nv.length > 1 ? nv[1] : true;
    }
    return outArgs;
};
