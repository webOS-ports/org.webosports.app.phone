enyo.kind({
	name: "Backend",
	kind: enyo.Component,
	pinCard: null,
	components: [
		{ kind: "Signals", ondeviceready: "deviceready" },
	],
	create: function() {
		this.inherited(arguments);
	},
	deviceready: function(inSender, inEvent) {
		this.inherited(arguments);
		enyo.log("Constructing Backend");
	},
});
