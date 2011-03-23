var loadingStatus = null;
var popupStatus = null;

function loadingView() {
	if($("#modal-bg").length == 0) {
		$("<div id=\"modal-bg\"><img id=\"loading-icon\" src=\"/images/loading.gif\" width=\"91\" height=\"120\" alt=\"로딩이미지\"/></div>")
		.css({"display":"none","background-color": "white", "position": "absolute", "top": "0", "left": "0","z-index":"10"})
		.appendTo('body')
	}
	if(!loadingStatus) {
		loadingStatus = "view";
		startX = ($(document).width()/2)-(91/2);
		startY = ($(window).height()/2)-(120/2)+$(document).scrollTop();
		$("#loading-icon").css({"position": "absolute","top":startY,"left":startX}).show()
		$("#modal-bg")
			.css({"width": "100%","min-width":"960px", "height": $(document).height()})
			.stop().fadeTo(0,"0.8")
	} else {
		if(popupStatus) {
			if(loadingStatus == "view") {
				loadingStatus = "top";
				$("#modal-bg").css("z-index","130");	
			} else {
				loadingStatus = "view";
				$("#modal-bg").css("z-index","10");
			}
		} else {
			loadingStatus = null;
			$("#modal-bg").stop().fadeOut(0,function() {$("#loading-icon").hide();});
		}
	}
}

function popupView(popWidth, popHeight, url, post, callback) {
	if(typeof(post) == "function") {
		callback = post;
		post = null;
	}
	if($("#popup-view").length == 0) {
		$("<div id=\"popup-view\"></div>")
		.appendTo('body');
		$("<a id=\"popup-closeButton\"></a>")
		.appendTo('body');
	}
	$("#popup-view")
	.css({"display":"none","background-color": "White", "position": "absolute","z-index":"100","overflow":"hidden"})
	.mousedown(function(){$(document).mousemove(function(e){return false;});})
	
	if(!popupStatus && url) {
		loadingView();
		popupStatus = Array("view",popWidth,popHeight)
		startX = ($(document).width()/2)-(popWidth/2);
		startY = ($(window).height()/2)-(popHeight/2)+$(document).scrollTop();
		if(startY < 20) startY = 20;
		$("#popup-closeButton").css({"top":startY+10,"left":startX+popWidth-68})
		$("#popup-view")
		.css({"top": startY, "left": startX, "width":popWidth, "height":popHeight})
		.load(url+" #ajax_content",post,function(responseText, textStatus, XMLHttpRequest) { $(this).show();$("#popup-closeButton").live("click",function(){popupView()}).show(); if(typeof(callback) == "function") callback(responseText, textStatus, XMLHttpRequest);})
	} else if(popupStatus[0] == "view" && url) {
		startX = ($(document).width()/2)-(popWidth/2);
		startY = ($(window).height()/2)-(popHeight/2)+$(document).scrollTop()
		$("#popup-closeButton").fadeOut("fast",function() {$("#popup-closeButton").css({"top":startY+10,"left":startX+popWidth-68})})
		$("#popup-view #ajax_content").fadeOut("fast",
		function() {
			$("#ajax_content").remove();
			$("#popup-view").load(url+" #ajax_content",post,
			function(responseText, textStatus, XMLHttpRequest) {
				$("#popup-view #ajax_content").css("display","none");
				$("#popup-view").animate({top:startY,left:startX,width: popWidth, height: popHeight },function () { $("#popup-view #ajax_content").show(); $("#popup-closeButton").live("click",function(){popupView()}).show(); })
				if(typeof(callback) == "function") callback(responseText, textStatus, XMLHttpRequest);
			})
		})
	} else if(popupStatus[0] == "view" && !url) {
		popupStatus = null;
		$("#popup-view").hide();
		$("#popup-closeButton").hide()
		loadingView();
	}

}
