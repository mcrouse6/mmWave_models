# First we pull in the standard API hooks.
require 'sketchup.rb'
# Show the Ruby Console at startup so we can
# see any programming errors we may make.
require 'exporter'



# Add a menu item to launch our plugin.
UI.menu("Plugins").add_item("Make Room") {
  SKETCHUP_CONSOLE.show
  prompts = ["Height (Meters)", "Length", "Width"]
  defaults = ["3", "3", "3"]
  input = UI.inputbox(prompts, defaults, "How to Gen Room")
  draw_room input
  do_options
}

def draw_room(input)
  # Get handles to our model and the Entities collection it contains.
  model = Sketchup.active_model
  entities = model.entities
  height = input[0].to_f.m
  length = input[1].to_f.m
  width = input[2].to_f.m

  pt1 = [0,0,0]
  pt2 = [length,0,0]
  pt3 = [length,width,0]
  pt4 = [0,width,0]
  face = entities.add_face pt1, pt2, pt3, pt4
  face.pushpull -1*height
end
