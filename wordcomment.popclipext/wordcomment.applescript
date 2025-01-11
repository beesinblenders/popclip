tell application "Microsoft Word"
	activate
end tell

tell application "System Events"
	tell process "Microsoft Word"
		click menu item "Commentaire" of menu "Insérer" of menu bar 1
	end tell
end tell