# Copyright 2012-2015 Trimble Navigation Ltd.
#
# License: The MIT License (MIT)
#
# A SketchUp Ruby Extension that adds STL (STereoLithography) file format
# import and export. More info at https://github.com/SketchUp/sketchup-stl
#
# Exporter

require 'sketchup'


current_path = File.dirname(__FILE__)
if current_path.respond_to?(:force_encoding)
  current_path.force_encoding("UTF-8")
end

PLUGIN_PATH         = current_path.freeze
PLUGIN_STRINGS_PATH = File.join(PLUGIN_PATH, 'strings').freeze


STL_ASCII  = 'ASCII'.freeze
STL_BINARY = 'Binary'.freeze

OPTIONS = {
  'selection_only' => false,
  'export_units'   => 'Inches',
  'stl_format'     => STL_ASCII
}


PREF_KEY = 'CommunityExtensions\STL\Exporter'.freeze

def self.file_extension
  'stl'
end

def self.model_name
  title = Sketchup.active_model.title
  title = "Untitled-#{Time.now.to_i.to_s(16)}" if title.empty?
  title
end

def self.select_export_file
  title_template  = "Export To..."
  default_filename = "#{model_name()}.#{file_extension()}"
  dialog_title = sprintf(title_template, default_filename)
  directory = nil
  filename = UI.savepanel(dialog_title, directory, default_filename)
  # Ensure the file has a file extensions if the user omitted it.
  if filename && File.extname(filename).empty?
    filename = "#{filename}.#{file_extension()}"
  end
  filename
end

def self.export(path, options = OPTIONS)
  filemode = 'w'
  if RUBY_VERSION.to_f > 1.8
    filemode << ':ASCII-8BIT'
  end
  file = File.new(path , filemode)
  if options['stl_format'] == STL_BINARY
    file.binmode
    @write_face = method(:write_face_binary)
  else
    @write_face = method(:write_face_ascii)
  end
  scale = scale_factor(options['export_units'])
  write_header(file, model_name(), options['stl_format'])
  if options['selection_only']
    export_ents = Sketchup.active_model.selection
  else
    export_ents = Sketchup.active_model.active_entities
  end
  facet_count = find_faces(file, export_ents, 0, scale, Geom::Transformation.new)
  write_footer(file, facet_count, model_name(), options['stl_format'])
end

def self.find_faces(file, entities, facet_count, scale, tform)
  entities.each do |entity|
    next if entity.hidden? || !entity.layer.visible?
    if entity.is_a?(Sketchup::Face)
      facet_count += write_face(file, entity, scale, tform)
    elsif entity.is_a?(Sketchup::Group) ||
      entity.is_a?(Sketchup::ComponentInstance)
      entity_definition = definition(entity)
      facet_count += find_faces(
        file,
        entity_definition.entities,
        0,
        scale,
        tform * entity.transformation
      )
    end
  end
  facet_count
end

def self.write_face(file, face, scale, tform)
  normal = face.normal
  normal.transform!(tform)
  normal.normalize!
  mesh = face.mesh(0)
  mesh.transform!(tform)
  facets_written = @write_face.call(file, scale, mesh, normal)
  return(facets_written)
end

def self.write_face_ascii(file, scale, mesh, normal)
  vertex_order = get_vertex_order(mesh.points, normal)
  facets_written = 0
  polygons = mesh.polygons
  polygons.each do |polygon|
    if (polygon.length == 3)
      file.write("facet normal #{normal.x} #{normal.y} #{normal.z}\n")
      file.write("  outer loop\n")
      for j in vertex_order do
        pt = mesh.point_at(polygon[j].abs)
        pt = pt.to_a.map{|e| e * scale}
        file.write("    vertex #{pt.x} #{pt.y} #{pt.z}\n")
      end
      file.write("  endloop\nendfacet\n")
      facets_written += 1
    end
  end
  return(facets_written)
end

def self.write_face_binary(file, scale, mesh, normal)
  vertex_order = get_vertex_order(mesh.points, normal)
  facets_written = 0
  polygons = mesh.polygons
  polygons.each do |polygon|
    if (polygon.length == 3)
      norm = mesh.normal_at(polygon[0].abs)
      file.write(norm.to_a.pack("e3"))
      for j in vertex_order do
        pt = mesh.point_at(polygon[j].abs)
        pt = pt.to_a.map{|e| e * scale}
        file.write(pt.pack("e3"))
      end
      file.write([0].pack("v"))
      facets_written += 1
    end
  end
  return(facets_written)
end

def self.write_header(file, model_name, format)
  if format == STL_ASCII
    file.write("solid #{model_name}\n")
  else
    file.write(["SketchUp STL #{model_name}"].pack("A80"))
    # 0xffffffff is a place-holder value. In the binary format,
    # this value is updated in the write_footer method.
    file.write([0xffffffff].pack('V'))
  end
end

def self.write_footer(file, facet_count, model_name, format)
  if format == STL_ASCII
    file.write("endsolid #{model_name}\n")
  else
    # binary - update facet count
    file.flush
    file.seek(80)
    file.write([facet_count].pack('V'))
  end
  file.close
end

# Wrapper to shorten the syntax and create a central place to modify in case
# preferences are stored differently in the future.
def self.read_setting(key, default)
  Sketchup.read_default(PREF_KEY, key, default)
end

# Wrapper to shorten the syntax and create a central place to modify in case
# preferences are stored differently in the future.
def self.write_setting(key, value)
  Sketchup.write_default(PREF_KEY, key, value)
end

# def self.model_units
#   case Sketchup.active_model.options['UnitsOptions']['LengthUnit']
  # when UNIT_METERS
  #   'Meters'
  # when UNIT_CENTIMETERS
  #   'Centimeters'
  # when UNIT_MILLIMETERS
  #   'Millimeters'
  # when UNIT_FEET
  #   'Feet'
  # when UNIT_INCHES
  #   'Inches'
  # end
#   'Inches'
# end

def self.scale_factor(unit_key)
  if unit_key == 'Model Units'
    selected_key = model_units()
  else
    selected_key = unit_key
  end
  case selected_key
  when 'Meters'
    factor = 0.0254
  when 'Centimeters'
    factor = 2.54
  when 'Millimeters'
    factor = 25.4
  when 'Feet'
    factor = 0.0833333333333333
  when 'Inches'
    factor = 1.0
  end
  factor
end

# Flipped insances in SketchUp may not follow the right-hand rule,
# but the STL format expects vertices ordered by the right-hand rule.
# If the SketchUp::Face normal does not match the normal calculated
# using the right-hand rule, then reverse the vertex order written
# to the .stl file.
def self.get_vertex_order(positions, face_normal)
  calculated_normal = (positions[1] - positions[0]).cross( (positions[2] - positions[0]) )
  order = [0, 1, 2]
  order.reverse! if calculated_normal.dot(face_normal) < 0
  order
end

def self.do_options
  path = select_export_file()
  export(path, OPTIONS) unless path.nil?
end # do_options
def definition(instance)
  if instance.respond_to?(:definition)
    return instance.definition
  elsif instance.is_a?(Sketchup::Group)
    # (i) group.entities.parent should return the definition of a group.
    # But because of a SketchUp bug we must verify that group.entities.parent
    # returns the correct definition. If the returned definition doesn't
    # include our group instance then we must search through all the
    # definitions to locate it.
    if instance.entities.parent.instances.include?(instance)
      return instance.entities.parent
    else
      Sketchup.active_model.definitions.each { |definition|
        return definition if definition.instances.include?(instance)
      }
    end
  elsif instance.is_a?(Sketchup::Image)
    Sketchup.active_model.definitions.each { |definition|
      if definition.image? && definition.instances.include?(instance)
        return definition
      end
    }
  end
  return nil # Given entity was not an instance of an definition.
end
