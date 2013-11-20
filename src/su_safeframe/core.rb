#-------------------------------------------------------------------------------
#
# Copyright 2013, Trimble Navigation Limited
#
# This software is provided as an example of using the Ruby interface
# to SketchUp.
#
# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#-------------------------------------------------------------------------------

require 'su_safeframe.rb'
require 'su_safeframe/locale.rb'

module Sketchup::Extensions::SafeFrameTools

### UI ### ---------------------------------------------------------------------

  unless file_loaded?(__FILE__)
    # Commands
    cmd = UI::Command.new('Set Camera Aspect Ratio') { 
      self.open_camera_window
    }
    cmd.small_icon = File.join(PATH_ICONS, 'camera_aspect_16.png')
    cmd.large_icon = File.join(PATH_ICONS, 'camera_aspect_24.png')
    cmd.tooltip = 'Camera Tools'
    cmd.status_bar_text = 'Camera Tools'
    cmd_set_camera_aspect_ratio = cmd
    
    cmd = UI::Command.new('Reset Camera Aspect Ratio') { 
      self.reset_camera_aspect_ratio
    }
    cmd.small_icon = File.join(PATH_ICONS, 'camera_reset_16.png')
    cmd.large_icon = File.join(PATH_ICONS, 'camera_reset_24.png')
    cmd.tooltip = 'Resets the camera aspect ratio'
    cmd.status_bar_text = 'Resets the camera aspect ratio'
    cmd_reset_camera_aspect_ratio = cmd
    
    # Menus
    menu = UI.menu('Plugins').add_submenu(PLUGIN_NAME)
    menu.add_item(cmd_set_camera_aspect_ratio)
    menu.add_item(cmd_reset_camera_aspect_ratio)

    # Toolbar
    toolbar = UI::Toolbar.new(PLUGIN_NAME)
    toolbar.add_item(cmd_set_camera_aspect_ratio)
    toolbar.add_item(cmd_reset_camera_aspect_ratio)
    
    if toolbar.get_last_state == TB_VISIBLE
      toolbar.restore
      UI.start_timer(0.1, false) { toolbar.restore } # SU bug 2902434
    end
  end


  ### Extension ### ------------------------------------------------------------

  # Bug in SketchUp will cause the camera to shift. If this constant is set to
  # true the extension will try to adjust to that.
  #
  # @since 1.0.0
  FIX_CAMERA_ZOOM = true


  # @since 1.0.0
  def self.export_viewport(width, height, antialias = false, transparent = false)
    title = 'Export 2D Safe Frame'
    if Sketchup.version.to_i < 14
      filename = UI.savepanel('Export Camera Safeframe')
    else
      filetypes = '*.png;*.jpg;*.bmp;*.tif;*.pdf;*.eps;*.epx;*.dwg;*.dxf'
      filename = UI.savepanel('Export Camera Safeframe', nil, filetypes)
    end
    return if filename.nil?
    
    view = Sketchup.active_model.active_view
    options = {
      :filename    => filename,
      :width       => width,
      :height      => height,
      :antialias   => antialias,
      :transparent => transparent,
      :compression => 0.9
    }
    result = view.write_image(options)
    
    if result
      UI.messagebox "Image saved to: #{filename}"
    else
      UI.messagebox 'Failed to save image.'
    end
  end


  # @since 1.0.0
  def self.reset_camera_aspect_ratio
    view = Sketchup.active_model.active_view
    self.set_aspect_ratio(view, 0.0, FIX_CAMERA_ZOOM)
    if @window
      self.width_changed(@window[:txt_width].value)
      @window[:txt_aspect_ratio].value = Locale.float_to_string(0.0)
    end
  end


  # @since 1.0.0
  def self.open_camera_window
    #@window ||= self.create_camera_window
    @window = self.create_camera_window
    @window.show
    @window
  end


  def self.create_camera_window
    puts 'self.create_camera_window'
    view = Sketchup.active_model.active_view
    camera = view.camera

    options = {
      :title     => PLUGIN_NAME,
      :width     => 250,
      :height    => 240,
      :resizable => false
    }
    @window = SKUI::Window.new(options)
    
    # Camera Aspect Ratio Group
    gAspect = SKUI::Groupbox.new('Viewport')
    gAspect.position(5, 5)
    gAspect.right = 5
    gAspect.height = 55
    @window.add_control(gAspect)

    # Aspect Ratio
    eAspectChange = DeferredEvent.new { |value| self.aspect_changed(value) }
    aspect_ratio = Locale.float_to_string(camera.aspect_ratio)
    txtAspectRatio = SKUI::Textbox.new(aspect_ratio)
    txtAspectRatio.name = :txt_aspect_ratio
    txtAspectRatio.position(95, 20)
    txtAspectRatio.width = 30
    txtAspectRatio.on(:textchange) { |control|
      eAspectChange.call(control.value)
    }
    gAspect.add_control(txtAspectRatio)
    
    lblWidth = SKUI::Label.new('Aspect Ratio:', txtAspectRatio)
    lblWidth.position(10, 23)
    gAspect.add_control(lblWidth)
    
    btnResetAspect = SKUI::Button.new('Reset') { |control|
      self.reset_camera_aspect_ratio
    }
    btnResetAspect.position(-10, 19)
    btnResetAspect.size(75, 23)
    gAspect.add_control(btnResetAspect)
    
    # Export Viewport Group
    gExport = SKUI::Groupbox.new('Export 2D')
    gExport.position(5, 65)
    gExport.right = 5
    gExport.height = 110
    @window.add_control(gExport)
    
    # Width
    #width = @settings[ :export_width ]
    width = 800
    eWidthChange = DeferredEvent.new { |value| self.width_changed(value) }
    txtWidth = SKUI::Textbox.new(width)
    txtWidth.name = :txt_width
    txtWidth.position(55, 20)
    txtWidth.width = 40
    txtWidth.on(:textchange) { |control|
      eWidthChange.call(control.value)
    }
    gExport.add_control(txtWidth)
    
    lblWidth = SKUI::Label.new('Width:', txtWidth)
    lblWidth.position(10, 23)
    gExport.add_control(lblWidth)
    
    # Height
    if self.float_equal(view.camera.aspect_ratio, 0.0)
      ratio = view.vpheight.to_f / view.vpwidth
      height = ( view.vpwidth * ratio ).to_i
    else
      ratio = 1.0 / view.camera.aspect_ratio
      height = ( width * ratio ).to_i
    end
    eHeightChange = DeferredEvent.new { |value| self.height_changed(value) }
    txtHeight = SKUI::Textbox.new(height)
    txtHeight.name = :txt_height
    txtHeight.position(160, 20)
    txtHeight.width = 40
    txtHeight.on(:textchange) { |control|
      eHeightChange.call(control.value)
    }
    gExport.add_control(txtHeight)
    
    lblHeight = SKUI::Label.new('Height:', txtHeight)
    lblHeight.position(110, 23)
    gExport.add_control(lblHeight)
    
    # Transparency
    chkTransp = SKUI::Checkbox.new('Transparency')
    chkTransp.name = :chk_transparency
    chkTransp.position(10, 55)
    #chkTransp.checked = @settings[:export_transparency]
    chkTransp.checked = true
    gExport.add_control(chkTransp)
    
    # Anti-aliasing
    chkAA = SKUI::Checkbox.new('Anti-aliasing')
    chkAA.name = :chk_aa
    chkAA.position(10, 80)
    #chkAA.checked = @settings[ :export_antialias ]
    chkAA.checked = false
    gExport.add_control(chkAA)
    
    # Export
    btnExport = SKUI::Button.new('Export') { |control|
      self.export_safeframe
    }
    btnExport.position(-7, -8)
    btnExport.size(75, 23)
    gExport.add_control(btnExport)
    
    # Close
    btnClose = SKUI::Button.new('Close') { |control|
      #@settings[ :export_width ] = @window[:txt_width].value.to_i
      #@settings[ :export_transparency ] = @window[:chk_transparency].checked?
      #@settings[ :export_antialias ] = @window[:chk_aa].checked?
      control.window.close
    }
    btnClose.position(-7, -7)
    btnClose.size(75, 23)
    @window.add_control( btnClose )

    @window
  end
  
  
  # Class that defer a procs execution by a given delay. If a value is given
  # it will only trigger if the value has changed.
  #
  # @since 1.0.0
  class DeferredEvent
    
    # @since 1.0.0
    def initialize(delay = 0.2, &block)
      @proc = block
      @delay = delay
      @last_value = nil
      @timer = nil
    end
    
    # @since 1.0.0
    def call(value)
      return false if value == @last_value
      UI.stop_timer(@timer) if @timer
      done = false
      @timer = UI.start_timer(@delay, false) {
        unless done # Ensure it only runs once.
          done = true
          @proc.call(value)
        end
      }
      true
    end
    
  end # class DeferredEvent
  
  
  # @since 1.0.0
  def self.width_changed(value)
    puts "width_changed( #{value} )"
    view = Sketchup.active_model.active_view
    if view.camera.aspect_ratio == 0.0
      ratio = view.vpheight.to_f / view.vpwidth.to_f
    else
      ratio = 1.0 / view.camera.aspect_ratio
    end
    @window[:txt_height].value = ( value.to_i * ratio ).to_i
  end
  
  
  # @since 1.0.0
  def self.height_changed(value)
    puts "height_changed( #{value} )"
    view = Sketchup.active_model.active_view
    if view.camera.aspect_ratio == 0.0
      ratio = view.vpwidth.to_f / view.vpheight.to_f
    else
      ratio = view.camera.aspect_ratio
    end
    @window[:txt_width].value = ( value.to_i * ratio ).to_i
    nil
  end
  
  
  # @since 1.0.0
  def self.aspect_changed(value)
    puts "aspect_changed( #{value} )"
    aspect_ratio = Locale.string_to_float(value)
    view = Sketchup.active_model.active_view
    self.set_aspect_ratio(view, aspect_ratio, FIX_CAMERA_ZOOM)
    if @window
      self.width_changed(@window[:txt_width].value)
    end
    nil
  end


  # @since 1.0.0
  def self.float_equal(float1, float2, tolerance = 1.0e-3)
    (float1 - float2).abs < tolerance
  end
  
  
  # @since 1.0.0
  def self.set_aspect_ratio(view, ratio, zoom_fix = true)
    # Mimmick what SketchUp does internally.
    ratio = 0.0 if ratio < 0.1
    return false if self.float_equal(view.camera.aspect_ratio, ratio)

    unless zoom_fix
      view.camera.aspect_ratio = ratio
      return true
    end

    # view.field_of_view _might_ be horisontal.
    #
    # If the debug camera window in SU has been used to modify the camera then
    # anything might fail.
    #
    # However, standard behaviour is that when there is no camera aspect ratio
    # set then camera.fov returns vertical AOV and horisontal AOV when aspect
    # ratio is set.

    view_xy_ratio = view.vpwidth.to_f / view.vpheight.to_f
    view_yx_ratio = view.vpheight.to_f / view.vpwidth.to_f

    # Reset any previsly set aspect ratio before computing a new one.
    unless float_equal(view.camera.aspect_ratio, 0.0)
      camera_ratio = view.camera.aspect_ratio
      view.camera.aspect_ratio = 0.0

      safe_frame_ratio = [camera_ratio, view_xy_ratio].min
      new_x_aov = view.field_of_view
      new_y_aov = x_aov_to_y_aov(new_x_aov, safe_frame_ratio)
      view.camera.fov = new_y_aov
    end

    return if float_equal(ratio, 0.0)

    # The fov is now horizontal - calculate new FOV to adjust for the shift
    # that appear because when SU flips FOV orientation it doesn't adjust
    # the values.
    #
    # n = camera.fov
    #
    # +----------+
    # |          |
    # |          | FOV(y) = n
    # +----------+
    #  FOV(x) = ?
    #
    # camera.aspect_ratio > 0
    # 
    # +----------+
    # |          |
    # |          | FOV(y) = ?
    # +----------+
    #  FOV(x) = n
    #
    # The original FOV(y) should be preserved, so a new FOV(x) is calculated
    # that will restore the original FOV(y).
    view.camera.aspect_ratio = ratio
      
    safe_frame_ratio = [ratio, view_xy_ratio].min
    new_y_aov = view.field_of_view                          # Target Y AOV.
    new_x_aov = y_aov_to_x_aov(new_y_aov, safe_frame_ratio) # Target X AOV.
    view.camera.fov = new_x_aov
    true
  end
  
  # @see http://www.gamedev.net/topic/431111-perspective-math-calculating-horisontal-fov-from-vertical/
  #
  # @since 1.0.0
  def self.y_aov_to_x_aov( vaov, ratio )
    return (2.0 * Math.atan( Math.tan(vaov.degrees / 2.0) * ratio )).radians
  end

  # @since 1.0.0
  def self.x_aov_to_y_aov( vaov, ratio )
    return (2.0 * Math.atan( Math.tan(vaov.degrees / 2.0) / ratio )).radians
  end
  
  
  # @since 1.0.0
  def self.export_safeframe
    width = @window[:txt_width].value.to_i
    height = @window[:txt_height].value.to_i
    antialias = @window[:chk_aa].checked
    transparent = @window[:chk_transparency].checked
    self.export_viewport(width, height, antialias, transparent)
  end


  ### DEBUG ### ----------------------------------------------------------------
  
  # Sketchup::Extensions::SafeFrameTools.reload
  #
  # @since 1.0.0
  def self.reload
    original_verbose = $VERBOSE
    $VERBOSE = nil
    filter = File.join(PATH, '*.{rb,rbs}')
    files = Dir.glob(filter).each { |file|
      load file
    }
    files.length
  ensure
    $VERBOSE = original_verbose
  end

end # module

#-------------------------------------------------------------------------------

file_loaded(__FILE__)

#-------------------------------------------------------------------------------
