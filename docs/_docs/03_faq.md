---
layout: page
title: Frequently Asked Questions
permalink: /faq
description: "Below you can find some common questions and answers related to the plugin."
---

# {{ page.title }}

{{ page.description }}

### I installed the plugin but I don't see the state charts nodes!

Make sure you enabled the plugin in the project settings. In the menu go to _Project_ -> _Project Settings_. This opens the project settings dialog. There select the _Plugins_ tab and tick the _Enable_ checkbox near the _Godot State Charts_ plugin.

### How can I find the currently active state?

In a state chart multiple states can be active at the same time. In general, you should avoid tracking active states in your code - this is the responsibility of the state chart. Your code is responsible for _what_ happens, while the state chart is responsible for _when_ it happens. If you need to know whether a certain state is active, you can get a reference to that state's node (using Godot's built-in `get_node` or `GetNode` functions) and then check the `active` property of that node.

### Can you backport the library to Godot 3?

I'm afraid not. While it technically would be totally possible to do so, I don't have the bandwidth for maintaining two versions of the library. I prefer to focus on the latest version of Godot, which is currently 4.

### Can I use this library with C#?

Yes, you can. The library is written in GDScript, but it provides a wrapper API for C# as well. Please check the [manual](./) for more information.
