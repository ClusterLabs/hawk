// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function expand_block(id)
{
  new Effect.BlindDown($(id), { duration: 0.3, fps: 100 });
  $(id).removeClassName('closed');
  $(id+'::button').removeClassName('tri-closed').addClassName('tri-open');
}

function collapse_block(id)
{
  new Effect.BlindUp($(id), { duration: 0.3, fps: 100 });
  $(id).addClassName('closed');
  $(id+'::button').removeClassName('tri-open').addClassName('tri-closed');
}

function toggle_collapse(id)
{
  if ($(id).hasClassName('closed')) {
    expand_block(id);
  } else {
    collapse_block(id);
  }
}

