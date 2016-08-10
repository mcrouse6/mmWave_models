# First we pull in the standard API hooks.
require 'sketchup.rb'
# Show the Ruby Console at startup so we can
# see any programming errors we may make.
require 'exporter'

export_path = 'C:/Users/aians/Desktop'
# Add a menu item to launch our plugin.
UI.menu("Plugins").add_item("Make Rooms") {
  rooms_prompt
}

def draw_rooms(input)
  # Get handles to our model and the Entities collection it contains.
  model = Sketchup.active_model
  entities = model.entities
  entities.clear!
  min_height = input[0].to_f.m
  min_length = input[1].to_f.m
  min_width = input[2].to_f.m
  pt1 = [0,0,0]
  for i in 0..input[3].to_f
    scaled_height = (input[4].to_f**i)*min_height
    scaled_length = (input[5].to_f**i)*min_length
    scaled_width = (input[6].to_f**i)*min_width
    pt2 = [scaled_length,0,0]
    pt3 = [scaled_length,scaled_width,0]
    pt4 = [0,scaled_width,0]
    face = entities.add_face pt1, pt2, pt3, pt4
    face.pushpull -1*scaled_height
    export File.join(export_path, '#{scaled_length}x#{scaled_width}x#{scaled_height})
    entities.clear!
  end
end

def rooms_prompt
  SKETCHUP_CONSOLE.show
  prompts = ["Min Height (Meters)", "Min Length", "Min Width", "Num Rooms", "H Scale", "L Scale", "W Scale"]
  defaults = ["3", "3", "3", "1", "1", "1", "1"]
  input = UI.inputbox(prompts, defaults, "How to Gen Rooms")
  draw_rooms input
end
