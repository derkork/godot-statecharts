---
layout: page
title: Installation and Updates
permalink: /installation
description: "Here you can find the installation instructions for the plugin."
---

# {{ page.title }}

## Table of Contents
- [Requirements](#requirements)
- [Installation with the Godot Asset Library](#installation-with-the-godot-asset-library)
- [Manual installation](#manual-installation)
- [Installation with C#](#installation-with-c)
- [Updating from an earlier version](#updating-from-an-earlier-version)

## Requirements

This plugin requires Godot 4.0.3 or later. Earlier versions of Godot 4 may work but are not officially supported. The plugin will not work with Godot 3.x.

## Installation with the Godot Asset Library

The easiest way to install the plugin is to use the Godot Asset Library. Search for "Godot State Charts" and install the plugin. You can exclude the `godot_state_charts_examples` folder if you don't need the examples.

## Manual installation

You can also download a ZIP file of this repository and extract it, then copy the `addons/godot_state_charts` folder into your project's `addons` folder.

After you installed it, make sure you enable the plugin in the project settings:

![Enabling the plugin in the project settings]({{ site.baseurl }}/assets/img/manual/enable_plugin.png)


## Installation with C#

If you want to use this library with C#, make sure you are using the .NET version of Godot 4. This can be downloaded from the [Godot download page](https://godotengine.org/download). The standard version of Godot 4 does not support C#. **If you got Godot from Steam, you have the standard version and need to download the .NET version separately from the Godot website.** There are additional installation steps for the Godot .NET version, so make sure you follow the instructions on the [Godot documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp_basics.html).

After you installed the plugin as described above, you may need to initialize your C# project if you haven't already done so. You can do this by going to the menu _Project_ -> _Tools_ -> _C#_ -> _Create C# solution_.

![Create C# solution]({{ site.baseurl }}/assets/img/manual/create_csharp_solution.png)

> ⚠️ **Note**: the C# API is currently experimental and may change in the future. Please give it a try and let me know if you encounter any issues.

## Updating from an earlier version

The asset library currently has no support for plugin updates, therefore in order to update the plugin, perform the following steps:

- **Be sure you have a backup of your project or have it under version control, so you can go back in case things don't work out as intended.**
- Check the [CHANGES.md](https://github.com/derkork/godot-statecharts/blob/main/CHANGES.md) for any breaking changes that might impact your project and any special update instructions.
- Download the version you want to install from the [Release List](https://github.com/derkork/godot-statecharts/releases) (use the _Source Code ZIP_ link).
- Close Godot. It's important to not have the project opened while running the update.
- In your project locate the `godot_state_charts` folder within the `addons` folder and delete the `godot_state_charts` folder with all of its contents.
- Unpack your downloaded ZIP file somewhere. Inside of the unpacked ZIP file structure, locate the `godot_state_charts` folder within the `addons` folder.
- Move `godot_state_charts` folder you located in the previous step into the `addons` folder of your project.
- The plugin is now updated. You can now open the project again in Godot and continue working on it.
