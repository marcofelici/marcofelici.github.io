---
layout: archive
title: "Blog posts"
permalink: /blogPosts/
author_profile: true
---

{% if author.googlescholar %}
  You can also find my articles on <u><a href="{{author.googlescholar}}">my Google Scholar profile</a>.</u>
{% endif %}

{% include base_path %}

{% for post in site.blogPosts reversed %}
  {% include archive-single.html %}
{% endfor %}
