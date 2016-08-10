# First we pull in the standard API hooks.
require 'sketchup.rb'
# Show the Ruby Console at startup so we can
# see any programming errors we may make.
require 'exporter'

# Add a menu item to launch our plugin.
UI.menu('Plugins').add_item('Make Rooms') do
    table_prompt
end

def table_prompt
    SKETCHUP_CONSOLE.show
    prompts = ['Height (Meters)', 'Length', 'Width', 'Thickness', 'Export Path']
    defaults = ['3', '3', '1', '.2', 'C:/Users/aians/Desktop']
    input = UI.inputbox(prompts, defaults, 'How to Gen Table')
    draw_table input
end

def draw_table(input)
    model = Sketchup.active_model
    entities = model.entities
    entities.clear!
    #draw table top
    length = input[1].to_f.m
    width = input[2].to_f.m
    thickness = input[3].to_f.m
    pt1 = [0, 0, 0]
    pt2 = [length, 0, 0]
    pt3 = [length, width, 0]
    pt4 = [0, width, 0]
    face = entities.add_face pt1, pt2, pt3, pt4
    face.pushpull -1 * thickness
    # draw legs
    height = input[0].to_f.m
    leg_height = height - thickness
    leg1 = [length * 0.1, 0, 0]
    leg2 = [length * 0.1, width, 0]
    face = entities.add_face pt1, leg1, leg2, pt4
    face.pushpull leg_height

    leg3 = [length * 0.9, 0, 0]
    leg4 = [length * 0.9, width, 0]
    face = entities.add_face pt2, leg3, leg4, pt3
    face.pushpull leg_height
    export File.join(input[4], "#{length.to_m}x#{width.to_m}x#{height.to_m}_table.stl")
end
