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
require 'su_safeframe/deferred_event.rb'
require 'su_safeframe/locale.rb'
require 'su_safeframe/settings.rb'
require 'su_safeframe/ui.rb'

module Sketchup::Extensions::SafeFrameTools

  # NOTE to Extension Warehouse moderation:
  # This will load the bundled SKUI library into this module - keeping it
  # isolated from everything else. It's dynamically embedding the library as
  # oppose to hard-coding a wrapper which would be awkward to maintain.
  # There is a stub methods left behind: ::SKUI.embed_in - but that is by design
  # and harmless.
  load File.join(PATH, 'SKUI', 'embed_skui.rb')
  ::SKUI.embed_in(self)

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

  # SketchUp will cause the camera to shift when changing aspect ratio. If this
  # constant is set to true the extension will try to adjust to that.
  #
  # @since 1.0.0
  FIX_CAMERA_ZOOM = true


  @settings = Settings.new(PLUGIN_ID)
  @settings.set_default(:export_width,        800)
  @settings.set_default(:export_transparency, false)
  @settings.set_default(:export_antialias,    false)


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


  # @since 1.0.0
  def self.get_camera_xy_aov(view)
    view_aspect = view.vpwidth.to_f / view.vpheight.to_f
    # Ideally the Ruby API should expose the flag that indicates if camera.fov
    # is vertical or horizontal, but alas.
    if float_equal(view.camera.aspect_ratio, 0.0)
      y_aov = view.field_of_view
      x_aov = y_aov_to_x_aov(y_aov, view_aspect)
    else
      x_aov = view.field_of_view
      y_aov = x_aov_to_y_aov(x_aov, view.camera.aspect_ratio)
    end
    [x_aov, y_aov]
  end


  # @since 1.0.0
  def self.set_aov_x(view, x_aov)
    if float_equal(view.camera.aspect_ratio, 0.0)
      view_aspect = view.vpwidth.to_f / view.vpheight.to_f
      y_aov = x_aov_to_y_aov(x_aov, view_aspect)
      view.camera.fov = y_aov
    else
      view.camera.fov = x_aov
    end
    nil
  end


  # @since 1.0.0
  def self.set_aov_y(view, y_aov)
    if float_equal(view.camera.aspect_ratio, 0.0)
      view.camera.fov = y_aov
    else
      x_aov = y_aov_to_x_aov(y_aov, view.camera.aspect_ratio)
      view.camera.fov = x_aov
    end
    nil
  end


  # @see http://www.gamedev.net/topic/431111-perspective-math-calculating-horisontal-fov-from-vertical/
  #
  # @since 1.0.0
  def self.y_aov_to_x_aov(vaov, ratio)
    return (2.0 * Math.atan( Math.tan(vaov.degrees / 2.0) * ratio )).radians
  end

  # @since 1.0.0
  def self.x_aov_to_y_aov(vaov, ratio)
    return (2.0 * Math.atan( Math.tan(vaov.degrees / 2.0) / ratio )).radians
  end
  
  
  # @since 1.0.0
  def self.export_safeframe
    width = @window[:txt_width].value.to_i
    height = @window[:txt_height].value.to_i
    antialias = @window[:chk_aa].checked?
    transparent = @window[:chk_transparency].checked?
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
