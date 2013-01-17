enyo.kind({
	name: "ListItem",
	classes: "list-item",
	layoutKind: "FittableColumnsLayout",
	handlers: {
		onmousedown: "pressed",
		ondragstart: "released",
		onmouseup: "released",
	},
	published: {
		icon: "",
		title: ""
	},
	components:[
		{name: "ItemIcon", kind: "Image", style: "height: 100%"},
		{name: "ItemTitle", style: "padding-left: 10px;"},
	],
	create: function() {
		this.inherited(arguments);
		this.$.ItemIcon.setSrc(this.icon);
		this.$.ItemTitle.setContent(this.title);
	},
	pressed: function() {
		this.addClass("onyx-selected");
	},
	released: function() {
		this.removeClass("onyx-selected");
	}
});

enyo.kind({
	name: "EmptyPanel",
	layoutKind: "FittableRowsLayout",
	style: "color: white; background-color: #555; box-shadow: 0 0 24px #111;",
	components:[
		{name: "Content", fit: true, style: "padding: 10px;"},
		{kind: "onyx.Toolbar"}
	],
	create: function() {
		this.inherited(arguments);
		this.$.Content.setContent(this.content);
	}
});

enyo.kind({
	name: "AppPanels",
	kind: "Panels",
	realtimeFit: true,
	arrangerKind: "CarouselArranger",
	classes: "app-panels",
	components:[
		{name: "Contacts",
		layoutKind: "FittableRowsLayout",
		style: "width: 33%; z-index: 10; color: white; background-color: #555; box-shadow: 0 0 24px #111;",
		components:[
			{kind: "onyx.Toolbar", components: [
				{content: "Contacts"}
			]}
		]},
		{name: "Dialpad",
		layoutKind: "FittableRowsLayout",
		style: "width: 34%; padding: 10px; z-index: 0; color: white; background-color: #555; box-shadow: 0 0 24px #111;",
		components:[
			{kind: "onyx.Toolbar",
			style: "border-radius: 16px; margin-bottom: 10px; text-align: right;",
			arrangerKind: "FittableColumnsArranger",
			components:[
				{name: "NumberInput", fit: true, style: "font-size: 24px; font-weight: bold;"},
				{kind: "onyx.Button", content: "<", ontap: "deleteTapped"}
			]},
			{tag: "div",
			fit: true,
			defaultKind: enyo.kind({kind: "onyx.Button",
						classes: "onyx-toolbar",
						style: "width: 33.3%; height: 25%; font-size: 32pt; font-weight: bold;",
						ontap: "keyTapped"}),
			components:[
				{content: "1", style: "border-radius: 16px 0 0 0;"},
				{content: "2", style: "border-radius: 0;"},
				{content: "3", style: "border-radius: 0 16px 0 0;"},
				{content: "4", style: "border-radius: 0;"},
				{content: "5", style: "border-radius: 0;"},
				{content: "6", style: "border-radius: 0;"},
				{content: "7", style: "border-radius: 0;"},
				{content: "8", style: "border-radius: 0;"},
				{content: "9", style: "border-radius: 0;"},
				{content: "*", style: "border-radius: 0 0 0 16px;"},
				{content: "0", style: "border-radius: 0;"},
				{content: "#", style: "border-radius: 0 0 16px 0;"},
			]},
			{name: "DialButton",
			kind: "onyx.Button",
			style: "width: 80%; height: 48px; margin-left: 10%; border-radius: 16px; margin-top: 10px; text-align: center; color: lightgreen; background-color: green; font-size: 24px; font-weight: bold;",
			content: "☏"}
		]},
		{name: "History",
		layoutKind: "FittableRowsLayout",
		style: "width: 33%; z-index: 10; color: white; background-color: #555; box-shadow: 0 0 24px #111;",
		components:[
			{kind: "onyx.Toolbar", components: [
				{content: "Call History"}
			]}
		]}
	],
	create: function() {
		this.inherited(arguments);
		if(enyo.Panels.isScreenNarrow()) {
			this.setIndex(1);
		}
	},
	reflow: function() {
		this.inherited(arguments);
		if(enyo.Panels.isScreenNarrow()) {
			this.$.Contacts.applyStyle("width", "100%");
			this.$.Dialpad.applyStyle("width", "100%");
			this.$.History.applyStyle("width", "100%");
			this.setIndex(1);
			this.setDraggable(true);
		}
		else {
			this.$.Contacts.applyStyle("width", "33%");
			this.$.Dialpad.applyStyle("width", "34%");
			this.$.History.applyStyle("width", "33%");
			this.setIndex(0);
			this.setDraggable(false);
		}
	},
	keyTapped: function(inSender, inEvent) {
		var input = this.$.NumberInput;
		input.setContent(input.getContent() + inSender.getContent());
	},
	deleteTapped: function(inSender, inEvent) {
		var input = this.$.NumberInput;
		input.setContent(input.getContent().substr(0, input.getContent().length - 1));
	}
});

enyo.kind({
	name: "App",
	layoutKind: "FittableRowsLayout",
	components: [
		{kind: "Signals",
		ondeviceready: "deviceready",
		onbackbutton: "handleBackGesture",
		onCoreNaviDragStart: "handleCoreNaviDragStart",
		onCoreNaviDrag: "handleCoreNaviDrag",
		onCoreNaviDragFinish: "handleCoreNaviDragFinish",},
		{name: "AppPanels", kind: "AppPanels", fit: true},
		{kind: "CoreNavi", fingerTracking: true}
	],
	handleBackGesture: function(inSender, inEvent) {
		this.$.AppPanels.setIndex(0);
	},
	handleCoreNaviDragStart: function(inSender, inEvent) {
		if(enyo.Panels.isScreenNarrow()) {
			this.$.AppPanels.dragstartTransition(inEvent);
		}
	},
	handleCoreNaviDrag: function(inSender, inEvent) {
		if(enyo.Panels.isScreenNarrow()) {
			this.$.AppPanels.dragTransition(inEvent);
		}
	},
	handleCoreNaviDragFinish: function(inSender, inEvent) {
		if(enyo.Panels.isScreenNarrow()) {
			this.$.AppPanels.dragfinishTransition(inEvent);
		}
	},
	//Utility Functions
	reverseDrag: function(inEvent) {
		inEvent.dx = -inEvent.dx;
		inEvent.ddx = -inEvent.ddx;
		inEvent.xDirection = -inEvent.xDirection;
		return inEvent;
	}
});
