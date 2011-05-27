// Based on "Sexy Drop Down Menu w/jQuery & CSS" by Soh Tanaka
// http://www.noupe.com/tutorial/drop-down-menu-jquery-css.html

$j(function(){

  var nav = $j('#topnav');

	$j("ul.subnav", nav).parent().append("<span></span>"); //Only shows drop down trigger when js is enabled (Adds empty span tag after ul.subnav*)

	$j("li span", nav).click(function() { //When trigger is clicked...

		//Following events are applied to the subnav itself (moving subnav up and down)
    var parent = $j(this).parent();
		parent.find("ul.subnav").slideDown(100).show(); //Drop down the subnav on click

		parent.hover(function() {
		}, function(){
			$j(this).parent().find("ul.subnav").slideUp(100); //When the mouse hovers out of the subnav, move it back up
		});

	//Following events are applied to the trigger (Hover events for the trigger)
	}).hover(function() {
		$j(this).addClass("subhover"); //On hover over, add class "subhover"
    
	}, function(){	//On Hover Out
		$j(this).removeClass("subhover"); //On hover out, remove class "subhover"
	});

});
