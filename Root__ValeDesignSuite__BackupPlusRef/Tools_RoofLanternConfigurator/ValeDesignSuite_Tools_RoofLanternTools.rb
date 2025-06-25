# =============================================================================
# ValeDesignSuite::RoofLanternTools
# =============================================================================
#
# NAMESPACE : ValeDesignSuite
# MODULE    : RoofLanternTools  
# AUTHOR    : Adam Noble - Vale Garden Houses
# TYPE      : SketchUpRuby Script
# PURPOSE   : Programmatically generate a 3D model of a roof lantern
# CREATED   : 20-May-2025
#
# DESCRIPTION:
# This plugin generates a 3D roof lantern model in SketchUp based on user-selected
# wire frame lines. It creates a complete roof lantern with configurable elements:
#
# - Ridge beams (250mm height x 50mm width)
# - Hip beams (200mm height x 50mm width)
# - Glazing bars (100mm height x 35mm width)
# - Optional lighting blocks at ridge-hip intersections
#
# The plugin allows for:
# - Custom roof pitch configuration
# - Fine-grained Z-offset control for all elements
# - Automatic calculation of proper angles and heights
# - Creation of a continuous ridge beam
# - Properly angled hip-end bars
#
# USAGE:
# 1. Draw the wire frame lines representing the roof lantern plan
# 2. Tag the lines appropriately (ridge, hips, glazing bars)
# 3. Select all lines
# 4. Access the tool via the Vale Design Suite main interface
# 5. Configure pitch and Z-offsets in the dialog
#
# -----------------------------------------------------------------------------
#
# DEVELOPMENT LOG:
# 20-May-2025 - Version 1.0.0 - FIRST STABLE VERSION
# - Integrated and refactored from the original ValeEngine script
# - Restructured to follow ValeDesignSuite naming conventions and structure
# - Maintained all functionality from the original script
# - Updated documentation and comments
#
# 22-May-2025 - Version 2.0.0 - UI INTEGRATION
# - Removed standalone menu item
# - Integrated with ValeDesignSuite main UI
# - Exposed module-level method for launching the generator
#
# =============================================================================

module ValeDesignSuite
  module RoofLanternTools

    # -------------------------------------------------------
    # CONSTANTS  -  Roof Member Profiles
    MM_TO_INCH    = 0.0393701    # <-- CRITICAL: This is the conversion factor for inches to millimeters In SketchUp
    RIDGE_PROFILE = { height: 250 * MM_TO_INCH  ,  width: 50 * MM_TO_INCH }.freeze
    HIP_PROFILE   = { height: 200 * MM_TO_INCH  ,  width: 50 * MM_TO_INCH }.freeze
    BAR_PROFILE   = { height: 100 * MM_TO_INCH  ,  width: 35 * MM_TO_INCH }.freeze
    STRICT_TOL    = 1.0e-6
    DEF_TOL       = (Sketchup.active_model.tolerance rescue 0.001)

    # CONSTANTS  -  Roof Member Z Offset
    Z_OFFSET_RIDGE_BEAM   =  -50 * MM_TO_INCH    # <-- Vertical offset from ridge (Default : 50mm Downwards)
    Z_OFFSET_HIP_BEAM     =  -20 * MM_TO_INCH    # <-- Vertical offset from ridge (Default : 20mm Downwards)
    Z_OFFSET_BAR          =   20 * MM_TO_INCH    # <-- Vertical offset from ridge (Default : 20mm Upwards)  

    # CONSTANTS  -  Roof Lighting Block
    LIGHT_BLOCK_SIZE      =  135 * MM_TO_INCH    # <-- Width/depth of octagon
    LIGHT_BLOCK_HEIGHT    =  290 * MM_TO_INCH    # <-- Height of block
    LIGHT_BLOCK_Z_OFFSET  =  -70 * MM_TO_INCH    # <-- Vertical offset from ridge (-70mm down)
    LIGHT_BLOCK_SIDES     =  8                   # <-- Number of sides for octagon

    # -------------------------------------------------------
    # MODULE-LEVEL METHOD TO LAUNCH THE ROOF LANTERN GENERATOR
    # This is the main entry point called from the UI
    def self.generate_roof_lantern(params = {})
      Generator.new.generate_roof_lantern(params)
    end

    # -------------------------------------------------------
    # TOLERANCE HELPERS
    class ::Float
      def almost?(o, t=DEF_TOL)
        (self-o.to_f).abs < t
      end
    end

    class ::Length
      def almost?(o, t=DEF_TOL)
        (to_f-o.to_f).abs < t
      end
    end

    class ::Geom::Point3d
      def almost_xy?(o, t=STRICT_TOL)
        (x-o.x).abs < t && (y-o.y).abs < t
      end
    end

    # -------------------------------------------------------
    # UTILITIES MODULE
    module Utilities
      # Create necessary layer tags for the roof lantern components
      def self.ensure_tags(model)
        %w[1-ridge 2-hips 3-glaze-bars].each { |n| model.layers.add(n) unless model.layers[n] }
      end

      # Create a beam between two points with the specified profile
      def self.add_beam(p0, p1, profile, ents)
        vec = p1 - p0
        return if vec.length.almost?(0.0, STRICT_TOL)
        e   = ents.add_edges(p0, p1).first
        dir, z = e.line[1].normalize, Geom::Vector3d.new(0, 0, 1)
        proj   = Geom::Vector3d.new(dir.x, dir.y, 0)

        if proj.length.almost?(0.0, STRICT_TOL)
          x = Geom::Vector3d.new(1, 0, 0)
          y = dir.cross(x).normalize
        else
          x = z.cross(proj).normalize
          x = proj.cross(z).normalize if x.length.almost?(0.0, STRICT_TOL)
          y = dir.cross(x).normalize
        end

        hw, hh = profile[:width]/2.0, profile[:height]/2.0
        pts = [
          p0.offset(x,-hw).offset(y,-hh),
          p0.offset(x, hw).offset(y,-hh),
          p0.offset(x, hw).offset(y, hh),
          p0.offset(x,-hw).offset(y, hh)
        ]
        face = ents.add_face(*pts)
        face.reverse! if face.normal.dot(dir) < 0
        face.followme(e)
        e.erase!
      end

      # Enhanced beam creation to handle multiple segments as a single beam
      def self.add_continuous_beam(points, profile, ents)
        return if points.length < 2
        
        # Create a single clean edge from the first to the last point
        start_pt = points.first
        end_pt = points.last
        
        # Create a single beam between start and end points
        add_beam(start_pt, end_pt, profile, ents)
      end

      # Create octagonal lighting block at specified center point
      def self.create_lighting_block(center_point, light_block_z_offset, ents)
        # Apply the vertical offset to the center point
        adjusted_center = Geom::Point3d.new(
          center_point.x, 
          center_point.y, 
          center_point.z + light_block_z_offset
        )
        
        # Calculate the radius of the circumscribed circle for the octagon
        radius = LIGHT_BLOCK_SIZE / 2.0
        
        # Create the octagonal base
        base_points = []
        LIGHT_BLOCK_SIDES.times do |i|
          angle = i * (2 * Math::PI / LIGHT_BLOCK_SIDES)
          x = adjusted_center.x + radius * Math.cos(angle)
          y = adjusted_center.y + radius * Math.sin(angle)
          base_points << Geom::Point3d.new(x, y, adjusted_center.z - LIGHT_BLOCK_HEIGHT/2.0)
        end
        
        # Create the base face
        base_face = ents.add_face(base_points)
        
        # Extrude the face
        base_face.pushpull(LIGHT_BLOCK_HEIGHT)
        
        # Return the created group
        return base_face
      end
    end

    # -------------------------------------------------------
    # ROOF TRIGONOMETRY MODULE
    module RoofTrigonometry
      # Calculate roof pitch angle from rise and run
      def self.pitch_to_angle(pitch)
        Math.atan(pitch) * 180.0 / Math::PI
      end

      # Calculate unit rise for a given pitch
      def self.unit_rise(pitch)
        pitch
      end

      # Calculate unit run (always 1.0 for normalized pitch)
      def self.unit_run
        1.0
      end

      # Calculate unit rafter length for a given pitch (hypotenuse)
      def self.unit_rafter_length(pitch)
        Math.sqrt(pitch * pitch + 1.0)
      end

      # Calculate hip angle for a given roof pitch
      def self.hip_angle(pitch)
        Math.atan(pitch / Math.sqrt(2.0)) * 180.0 / Math::PI
      end

      # Calculate hip run for a given roof pitch and unit run
      def self.hip_run(pitch)
        Math.sqrt(2.0)
      end

      # Calculate hip rafter length for a given pitch
      def self.hip_rafter_length(pitch)
        Math.sqrt(pitch * pitch + 2.0)
      end

      # Calculate backing angle for hip rafters
      def self.hip_backing_angle(pitch)
        Math.atan(pitch) * 180.0 / Math::PI
      end

      # Calculate proper angle between hip and jack rafter in plan view
      def self.hip_jack_plan_angle(pitch, corner_angle=90.0)
        corner_angle / 2.0
      end

      # Function to sort vertices into a connected chain
      def self.sort_vertices_into_chain(vertices, edges)
        return [] if vertices.empty? || edges.empty?
        
        # Create a mapping of vertices to their connected edges
        vertex_to_edges = {}
        vertices.each { |v| vertex_to_edges[v] = [] }
        
        edges.each do |edge|
          vertex_to_edges[edge.start] ||= []
          vertex_to_edges[edge.end] ||= []
          vertex_to_edges[edge.start] << edge
          vertex_to_edges[edge.end] << edge
        end
        
        # Find endpoints (vertices with only one connected edge)
        endpoints = vertices.select { |v| vertex_to_edges[v].size == 1 }
        
        # If no endpoints (closed loop), start with any vertex
        start_vertex = endpoints.first || vertices.first
        
        # Build the chain
        chain = [start_vertex]
        visited_edges = []
        
        while chain.size < vertices.size
          current = chain.last
          next_edge = vertex_to_edges[current].find { |e| !visited_edges.include?(e) }
          break unless next_edge
          
          visited_edges << next_edge
          next_vertex = (next_edge.start == current) ? next_edge.end : next_edge.start
          chain << next_vertex
        end
        
        return chain
      end
    end

    # -------------------------------------------------------
    # MAIN GENERATOR CLASS
    class Generator
      def initialize
        @model = Sketchup.active_model
        @version = "2.0.0" # Version for this integration
      end
      
      def generate_roof_lantern(params = {})
        Utilities.ensure_tags(@model)

        edges = @model.selection.grep(Sketchup::Edge)
        return UI.messagebox('Select the 2-D centre-lines first.') if edges.empty?
        return UI.messagebox('All selected edges must lie on Z = 0.') unless edges.all? { |e|
          e.start.position.z.almost?(0.0, STRICT_TOL) && e.end.position.z.almost?(0.0, STRICT_TOL)
        }

        # Get user inputs from params passed from HTML UI
        pitch_deg = params['pitch_deg'].to_f
        add_mouldings = (params['add_mouldings'] == 'Yes')
        
        # Convert user inputs from mm back to inches
        ridge_z_offset = params['ridge_z_offset_mm'].to_f * MM_TO_INCH
        hip_z_offset = params['hip_z_offset_mm'].to_f * MM_TO_INCH
        bar_z_offset = params['bar_z_offset_mm'].to_f * MM_TO_INCH
        light_block_z_offset = params['light_block_z_offset_mm'].to_f * MM_TO_INCH
        
        return UI.messagebox('Pitch must be > 0° and < 90°.') unless pitch_deg > 0 && pitch_deg < 90
        pitch_rad = pitch_deg.degrees
        roof_pitch = Math.tan(pitch_rad) # Tangent of pitch angle = rise/run

        # Separate edges by layer
        ridge_raw = edges.select { |e| e.layer.name == '1-ridge' }
        hip_raw   = edges.select { |e| e.layer.name == '2-hips' }
        bar_raw   = edges.select { |e| e.layer.name == '3-glaze-bars' }
        return UI.messagebox("No edges tagged '1-ridge'.") if ridge_raw.empty?

        # overall run/height
        bb = Geom::BoundingBox.new
        edges.each { |e| bb.add(e.start.position); bb.add(e.end.position) }
        run = [bb.width, bb.depth].max / 2.0
        ht  = run * Math.tan(pitch_rad)

        @model.start_operation("VGH | Roof Lantern Generator v#{@version}", true)

        begin
          # Create component groups
          create_component_groups(add_mouldings)
          
          # Process roof elements
          process_roof_elements(ridge_raw, hip_raw, bar_raw, ht, roof_pitch, 
                              ridge_z_offset, hip_z_offset, bar_z_offset, 
                              light_block_z_offset, add_mouldings)
          
          # Clean up and finalize
          @temp_group.erase! if @temp_group
          @model.commit_operation
          @model.selection.clear
          
          # Report success
          if add_mouldings
            @model.layers['1-ridge'].visible        = false
            @model.layers['2-hips'].visible         = false
            @model.layers['3-glaze-bars'].visible   = false
          end
          
          UI.messagebox("VGH | Roof Lantern Has Been Successfully Generated ✅")
        rescue => ex
          @model.abort_operation rescue nil
          @temp_group.erase! rescue nil
          UI.messagebox("Error: #{ex.message}\n#{ex.backtrace.join("\n")}")
        end
      end
      
      private
      
      def create_component_groups(add_mouldings)
        # Create the ROOT container for all components
        @root = @model.active_entities.add_group
        @root.name = "VGH_RoofLantern_v#{@version}"
        
        # Create separate groups for each component type
        @grp_ridge = @root.entities.add_group
        @grp_ridge.name = 'RidgeBeam'  # Singular - there's just one ridge beam
        
        @grp_hips = @root.entities.add_group
        @grp_hips.name = 'HipBeams'
        
        @grp_bars = @root.entities.add_group
        @grp_bars.name = 'GlazingBars'
        
        # Create group for lighting blocks (only if requested)
        if add_mouldings
          @grp_lighting = @root.entities.add_group
          @grp_lighting.name = 'LightingBlocks'
        end

        # Create a temporary calculation group
        @temp_group = @model.active_entities.add_group
        @temp_group.name = "TempCalcGroup"
      end
      
      def process_roof_elements(ridge_raw, hip_raw, bar_raw, height, roof_pitch, 
                             ridge_z_offset, hip_z_offset, bar_z_offset, 
                             light_block_z_offset, add_mouldings)
        # Create temporary edges for calculations
        temp_ridge_edges = ridge_raw.map { |e| @temp_group.entities.add_edges(e.start.position, e.end.position).first }
        temp_hip_edges = hip_raw.map { |e| @temp_group.entities.add_edges(e.start.position, e.end.position).first }
        temp_bar_edges = bar_raw.map { |e| @temp_group.entities.add_edges(e.start.position, e.end.position).first }
        
        # Process ridge
        ridge_data = process_ridge(temp_ridge_edges, height)
        
        # Process hips
        hip_data = process_hips(temp_hip_edges, ridge_data, roof_pitch)
        
        # Process glazing bars
        process_glazing_bars(temp_bar_edges, ridge_data, hip_data, roof_pitch)
        
        # Create the final beams with proper offsets
        create_ridge_beam(ridge_data, ridge_z_offset)
        create_hip_beams(hip_data, hip_z_offset)
        create_glazing_bars(temp_bar_edges, bar_z_offset)
        
        # Create lighting blocks if requested
        if add_mouldings
          create_lighting_blocks(hip_data, light_block_z_offset)
        end
      end
      
      def process_ridge(temp_ridge_edges, height)
        # Get all ridge vertices
        ridge_vertices = temp_ridge_edges.flat_map { |e| [e.start, e.end] }.uniq
        
        # Sort the ridge vertices into a connected chain
        sorted_ridge_vertices = RoofTrigonometry.sort_vertices_into_chain(ridge_vertices, temp_ridge_edges)
        
        # Get the true ridge endpoints (first and last vertices in the sorted chain)
        ridge_endpoints = []
        if sorted_ridge_vertices.size >= 2
          ridge_endpoints = [sorted_ridge_vertices.first, sorted_ridge_vertices.last]
        end
        
        # Lift ridge to peak height
        @temp_group.entities.transform_entities(
          Geom::Transformation.translation([0, 0, height]),
          ridge_vertices
        )
        
        # Store all ridge points in order (after lifting)
        ridge_points = sorted_ridge_vertices.map(&:position)
        
        # Return ridge data
        {
          vertices: ridge_vertices,
          sorted_vertices: sorted_ridge_vertices,
          endpoints: ridge_endpoints,
          points: ridge_points
        }
      end
      
      def process_hips(temp_hip_edges, ridge_data, roof_pitch)
        # Group hip edges by connection to ridge
        hip_lines = []  # Will store complete hip line data
        ridge_to_hip_map = {} # Maps ridge endpoints to connected hip edges
        
        # Find hip edges connected to ridge endpoints
        ridge_data[:endpoints].each do |ridge_endpoint|
          connected_hip_edges = temp_hip_edges.select { |e| 
            e.start == ridge_endpoint || e.end == ridge_endpoint 
          }
          
          ridge_to_hip_map[ridge_endpoint] = connected_hip_edges
        end
        
        # Build hip chains - follow connected edges from ridge to eave
        hip_chains = []
        
        # Process each ridge endpoint and its connected hips
        ridge_to_hip_map.each do |ridge_endpoint, hip_start_edges|
          hip_start_edges.each do |start_edge|
            # Create a new chain starting with this edge
            chain = [start_edge]
            # Determine the vertex at the opposite end from the ridge
            current = (start_edge.start == ridge_endpoint) ? start_edge.end : start_edge.start
            visited = [start_edge]
            
            # Follow the chain as far as possible
            while true
              next_edge = temp_hip_edges.find { |e| 
                !visited.include?(e) && (e.start == current || e.end == current)
              }
              
              break unless next_edge
              
              chain << next_edge
              visited << next_edge
              current = (next_edge.start == current) ? next_edge.end : next_edge.start
            end
            
            # Store the complete hip chain
            hip_data = {
              ridge_vertex: ridge_endpoint,
              eave_vertex: current,
              edges: chain
            }
            
            hip_chains << hip_data
          end
        end
        
        # Calculate hip angles and lift hip vertices
        hip_pitch_angle = RoofTrigonometry.hip_angle(roof_pitch)  # Angle of hip rafter to horizontal
        
        # Process each hip chain
        hip_chains.each do |hip_data|
          ridge_vertex = hip_data[:ridge_vertex]
          eave_vertex = hip_data[:eave_vertex]
          
          # Ridge vertex is already lifted to peak height
          ridge_point = ridge_vertex.position
          
          # Calculate the 2D projection of the hip line
          ridge_xy = Geom::Point3d.new(ridge_point.x, ridge_point.y, 0)
          eave_xy = Geom::Point3d.new(eave_vertex.position.x, eave_vertex.position.y, 0)
          
          # Calculate the horizontal distance from ridge to eave
          hip_run_length = ridge_xy.distance(eave_xy)
          
          # Calculate the backing angle (actual 3D angle of hip rafter)
          backing_angle = RoofTrigonometry.hip_backing_angle(roof_pitch)
          
          # Calculate eave height based on hip run and pitch
          hip_rise = hip_run_length * Math.tan(hip_pitch_angle.degrees)
          eave_height = ridge_point.z - hip_rise
          eave_height = [0, eave_height].max  # Ensure non-negative
          
          # Store hip line data for later use with glazing bars
          hip_lines << {
            ridge_point: ridge_point,
            eave_point: Geom::Point3d.new(eave_xy.x, eave_xy.y, eave_height),
            ridge_xy: ridge_xy,
            eave_xy: eave_xy,
            backing_angle: backing_angle,
            run_length: hip_run_length,
            pitch_angle: hip_pitch_angle
          }
          
          # Lift eave vertex to calculated height
          @temp_group.entities.transform_entities(
            Geom::Transformation.translation([0, 0, eave_height]),
            [eave_vertex]
          )
          
          # Lift any intermediate vertices proportionally along the hip line
          hip_data[:edges].each do |edge|
            [edge.start, edge.end].each do |v|
              # Skip ridge and eave vertices (already processed)
              next if v == ridge_vertex || v == eave_vertex
              
              # Get 2D projection of vertex
              v_xy = Geom::Point3d.new(v.position.x, v.position.y, 0)
              
              # Calculate proportional distance along hip line
              t = ridge_xy.distance(v_xy) / hip_run_length
              
              # Interpolate height
              v_height = ridge_point.z - (t * (ridge_point.z - eave_height))
              
              # Apply transformation
              dz = v_height - v.position.z
              unless dz.almost?(0.0, STRICT_TOL)
                @temp_group.entities.transform_entities(
                  Geom::Transformation.translation([0, 0, dz]),
                  [v]
                )
              end
            end
          end
        end
        
        return {
          chains: hip_chains,
          lines: hip_lines
        }
      end
      
      def process_glazing_bars(temp_bar_edges, ridge_data, hip_data, roof_pitch)
        ridge_vertices = ridge_data[:vertices]
        hip_lines = hip_data[:lines]
        
        # Process each bar
        temp_bar_edges.each do |bar_edge|
          start_v = bar_edge.start
          end_v = bar_edge.end
          
          # Project bar endpoints to XY plane
          start_xy = Geom::Point3d.new(start_v.position.x, start_v.position.y, 0)
          end_xy = Geom::Point3d.new(end_v.position.x, end_v.position.y, 0)
          
          # Check if bar connects directly to ridge
          on_ridge_start = ridge_vertices.include?(start_v)
          on_ridge_end = ridge_vertices.include?(end_v)
          
          if on_ridge_start || on_ridge_end
            # This is a direct ridge-to-eave glazing bar
            ridge_v = on_ridge_start ? start_v : end_v
            eave_v = on_ridge_start ? end_v : start_v
            
            # Ridge vertex already at correct height
            ridge_p = ridge_v.position
            eave_xy = Geom::Point3d.new(eave_v.position.x, eave_v.position.y, 0)
            ridge_xy = Geom::Point3d.new(ridge_p.x, ridge_p.y, 0)
            
            # Calculate run and eave height
            bar_run = ridge_xy.distance(eave_xy)
            eave_height = ridge_p.z - (bar_run * roof_pitch)
            eave_height = [0, eave_height].max
            
            # Lift eave vertex
            @temp_group.entities.transform_entities(
              Geom::Transformation.translation([0, 0, eave_height]),
              [eave_v]
            )
          else
            # This is likely a hip-end bar - determine which hip it relates to
            closest_hip = nil
            min_dist = Float::INFINITY
            start_project_point = nil
            end_project_point = nil
            
            # Find the closest hip line for this bar
            hip_lines.each do |hip|
              hip_line_xy = [hip[:ridge_xy], hip[:eave_xy]]
              
              # Calculate distance from bar endpoints to this hip line
              start_dist = start_xy.distance_to_line(hip_line_xy)
              end_dist = end_xy.distance_to_line(hip_line_xy)
              
              # Find project points on hip line
              start_proj = start_xy.project_to_line(hip_line_xy)
              end_proj = end_xy.project_to_line(hip_line_xy)
              
              if start_dist < min_dist || end_dist < min_dist
                min_dist = [start_dist, end_dist].min
                closest_hip = hip
                start_project_point = start_proj
                end_project_point = end_proj
              end
            end
            
            if closest_hip
              # Process each vertex of the bar
              [
                {vertex: start_v, xy: start_xy, proj: start_project_point},
                {vertex: end_v, xy: end_xy, proj: end_project_point}
              ].each do |data|
                v = data[:vertex]
                v_xy = data[:xy]
                proj_point = data[:proj]
                
                # Skip if vertex is already at final height
                next if ridge_vertices.include?(v)
                
                # Calculate how far along the hip line this point projects
                hip_ridge_xy = closest_hip[:ridge_xy]
                hip_run = closest_hip[:run_length]
                t = hip_ridge_xy.distance(proj_point) / hip_run
                
                # Calculate the height at that point on the hip
                hip_ridge_z = closest_hip[:ridge_point].z
                hip_eave_z = closest_hip[:eave_point].z
                hip_z_at_proj = hip_ridge_z - (t * (hip_ridge_z - hip_eave_z))
                
                # Calculate perpendicular distance from vertex to hip line
                perp_dist = v_xy.distance(proj_point)
                
                # Calculate the additional drop from hip to this point
                # Here we use the compound angle calculation based on the hip angle and bar position
                hip_pitch_angle_rad = closest_hip[:pitch_angle].degrees
                
                # The drop is based on perpendicular distance and the compound angle
                # This uses standard hip roof framing calculations
                additional_drop = perp_dist * roof_pitch
                
                # Final height is hip height minus additional drop
                final_height = hip_z_at_proj - additional_drop
                final_height = [0, final_height].max
                
                # Apply transformation
                @temp_group.entities.transform_entities(
                  Geom::Transformation.translation([0, 0, final_height - v.position.z]),
                  [v]
                )
              end
            else
              # If no hip is found, use standard ridge-based height calculation
              [start_v, end_v].each do |v|
                # Skip if vertex is already at final height
                next if ridge_vertices.include?(v)
                
                # Find closest point on ridge
                v_xy = Geom::Point3d.new(v.position.x, v.position.y, 0)
                min_dist = Float::INFINITY
                
                # Create pairs of ridge points to form line segments
                ridge_segments = []
                ridge_data[:points].each_cons(2) do |p1, p2|
                  ridge_segments << [
                    Geom::Point3d.new(p1.x, p1.y, 0),
                    Geom::Point3d.new(p2.x, p2.y, 0)
                  ]
                end
                
                ridge_segments.each do |line|
                  dist = v_xy.distance_to_line(line)
                  min_dist = dist if dist < min_dist
                end
                
                # Calculate height based on distance from ridge
                height = ridge_data[:points].first.z - (min_dist * roof_pitch)
                height = [0, height].max
                
                # Apply transformation
                @temp_group.entities.transform_entities(
                  Geom::Transformation.translation([0, 0, height - v.position.z]),
                  [v]
                )
              end
            end
          end
        end
      end
      
      def create_ridge_beam(ridge_data, ridge_z_offset)
        # Create a single continuous ridge beam
        if ridge_data[:sorted_vertices].size >= 2
          # Apply the Z offset for ridge beam
          ridge_start = ridge_data[:sorted_vertices].first.position
          ridge_end = ridge_data[:sorted_vertices].last.position
          
          # Apply Z offset to ridge beam
          ridge_start_offset = Geom::Point3d.new(
            ridge_start.x,
            ridge_start.y,
            ridge_start.z + ridge_z_offset
          )
          
          ridge_end_offset = Geom::Point3d.new(
            ridge_end.x,
            ridge_end.y,
            ridge_end.z + ridge_z_offset
          )
          
          # Create a single continuous ridge beam with proper Z offset
          Utilities.add_beam(ridge_start_offset, ridge_end_offset, RIDGE_PROFILE, @grp_ridge.entities)
        end
      end
      
      def create_hip_beams(hip_data, hip_z_offset)
        # Process each hip chain to create beams
        hip_data[:chains].each_with_index do |hip_data, idx|
          sub = @grp_hips.entities.add_group
          sub.name = "HipBeam_#{idx + 1}"
          
          # Get ridge and eave endpoints
          ridge_v = hip_data[:ridge_vertex]
          eave_v = hip_data[:eave_vertex]
          
          # Apply Z offset to hip beam
          ridge_pos = ridge_v.position
          eave_pos = eave_v.position
          
          # Calculate Z offsets - the ridge end gets hip_z_offset from its position
          # The eave end also gets offset, but we ensure it doesn't go below 0
          ridge_pos_offset = Geom::Point3d.new(
            ridge_pos.x,
            ridge_pos.y,
            ridge_pos.z + hip_z_offset
          )
          
          eave_pos_offset = Geom::Point3d.new(
            eave_pos.x,
            eave_pos.y,
            [eave_pos.z + hip_z_offset, 0].max
          )
          
          # Create a single beam from ridge to eave with proper Z offset
          Utilities.add_beam(ridge_pos_offset, eave_pos_offset, HIP_PROFILE, sub.entities)
        end
      end
      
      def create_glazing_bars(temp_bar_edges, bar_z_offset)
        # Create bars individually
        temp_bar_edges.each_with_index do |bar_edge, idx|
          sub = @grp_bars.entities.add_group
          sub.name = "Bar_#{idx + 1}"
          
          # Apply Z offset to the bar
          start_pos = bar_edge.start.position
          end_pos = bar_edge.end.position
          
          # Apply the same offset to both ends
          # We ensure the offset doesn't push the bar below 0
          start_pos_offset = Geom::Point3d.new(
            start_pos.x,
            start_pos.y,
            [start_pos.z + bar_z_offset, 0].max
          )
          
          end_pos_offset = Geom::Point3d.new(
            end_pos.x,
            end_pos.y,
            [end_pos.z + bar_z_offset, 0].max
          )
          
          # Create the bar with proper Z offset
          Utilities.add_beam(start_pos_offset, end_pos_offset, BAR_PROFILE, sub.entities)
        end
      end
      
      def create_lighting_blocks(hip_data, light_block_z_offset)
        # Create a lighting block at each hip-ridge intersection point
        hip_data[:chains].each_with_index do |hip_data, idx|
          # Get the ridge vertex where this hip connects
          ridge_v = hip_data[:ridge_vertex]
          
          # Create a sub-group for this lighting block
          sub = @grp_lighting.entities.add_group
          sub.name = "LightingBlock_#{idx + 1}"
          
          # Create the octagonal lighting block with user-defined offset
          Utilities.create_lighting_block(ridge_v.position, light_block_z_offset, sub.entities)
        end
      end
    end

  end # module RoofLanternTools
end # module ValeDesignSuite

# =============================================================================
# END OF FILE
# =============================================================================
