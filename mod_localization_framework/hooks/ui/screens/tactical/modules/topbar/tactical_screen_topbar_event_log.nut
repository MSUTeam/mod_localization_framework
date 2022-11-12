// ::mods_hookExactClass("ui/screens/tactical/modules/topbar/tactical_screen_topbar_event_log", function(o) {
// 	o.logEx = function( _text )
// 	{
// 		if (_text.find("Chance:") != null)
// 		{
// 			if (_text.find("astray and hits") != null)
// 			{
// 				// use regex to get the variables: attackerColor, attackerName, skillName, targetColor, targetName, chance, rolled
// 				_text = ::Localization.getLoc("Tactical.EventLog.AstrayHit",
// 					attackerColor,
// 					attackerName,
// 					skillName,
// 					targetColor,
// 					targetName,
// 					chance,
// 					rolled
// 					);
// 			}
// 			else if (_text.find("astray and misses") != null)
// 			{
// 				// use regex to get the variables: attackerColor, attackerName, skillName, targetColor, targetName, chance, rolled
// 				_text = ::Localization.getLoc("Tactical.EventLog.AstrayMiss",
// 					attackerColor,
// 					attackerName,
// 					skillName,
// 					targetColor,
// 					targetName,
// 					chance,
// 					rolled
// 					);
// 			}
// 			// and so on
// 			else if (_text.find("and hits"))
// 			{

// 			}
// 		}
// 	}
// });
