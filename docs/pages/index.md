---
layout: page
title: Home
permalink: /
description: ""
---

# {{ site.title }}

{{ page.description }}

<style type="text/css">
img {
    align: center;
    display: block;
    margin-left: auto;
    margin-right: auto;
}
</style>

**If you prefer to learn in video form, there is also a [video tutorial available on YouTube](https://www.youtube.com/watch?v=E9h9VnbPGuw) to get you started.**

## Index

{%- for section in site.data.toc %}
- [{{ section.title }}]({{ section.url }})
{%- if section.links %}
    {%- for link in section.links %}
    - [{{ link.title }}]({{ link.url }})
    {%- endfor %}
{%- endif %}
{%- endfor %}
