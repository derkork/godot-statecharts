@echo Starting tests.
godots exec -- --path %~dp0 -u -d -s addons/gut/gut_cmdln.gd -gexit %* & ^
type %APPDATA%\Godot\app_userdata\godot-state-charts\logs\godot.log
