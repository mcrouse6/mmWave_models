# First we pull in the standard API hooks.
require 'sketchup.rb'

# Show the Ruby Console at startup so we can
# see any programming errors we may make.



# Add a menu item to launch our plugin.
UI.menu("Plugins").add_item("Make Collumns") {
  pillars_prompt
}

def draw_collumns(input)
  # Get handles to our model and the Entities collection it contains.
  model = Sketchup.active_model
  entities = model.entities
  entities.clear!
  height = input[0].to_f.m
  side = input[1].to_f.m
  length = input[2].to_f
  width = input[3].to_f
  space = input[4].to_f.m
  offset = space+side
  for i in 0..length-1
    for j in 0..width-1
      x=i*offset
      y=j*offset
      pt1 = [x,y,0]
      pt2 = [x+side,y,0]
      pt3 = [x+side,y+side,0]
      pt4 = [x,y+side,0]
      face = entities.add_face pt1, pt2, pt3, pt4
      face.pushpull -1*height
    end
  end
end

def pillars_prompt
  SKETCHUP_CONSOLE.show
  prompts = ["Height (Meters)", "Side", "Grid Length(Num Collumns)", "Grid Width", "Spacing"]
  defaults = ["3", ".5", "5", "5", ".5"]
  input = UI.inputbox(prompts, defaults, "How to Gen Collumns")
  draw_collumns input
end
