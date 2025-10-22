@echo Starting tests.
@echo Please inspect %APPDATA%\Godot\app_userdata\godot-state-charts\logs\godot.log for results.
godots exec -- --path %~dp0 -u -d -s addons/gut/gut_cmdln.gd -gexit %*
