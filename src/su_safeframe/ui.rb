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

module Sketchup::Extensions::SafeFrameTools


  def self.create_camera_window
    puts 'self.create_camera_window'
    view = Sketchup.active_model.active_view
    camera = view.camera

    options = {
      :title           => PLUGIN_NAME,
      :preferences_key => PLUGIN_ID,
      :width           => 250,
      :height          => 240,
      :resizable       => false
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
    width = @settings[:export_width]
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
      height = ( width * ratio ).to_i
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
    chkTransp.checked = @settings[:export_transparency]
    gExport.add_control(chkTransp)
    
    # Anti-aliasing
    chkAA = SKUI::Checkbox.new('Anti-aliasing')
    chkAA.name = :chk_aa
    chkAA.position(10, 80)
    chkAA.checked = @settings[:export_antialias]
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
      @settings[:export_width]        = @window[:txt_width].value.to_i
      @settings[:export_transparency] = @window[:chk_transparency].checked?
      @settings[:export_antialias]    = @window[:chk_aa].checked?
      control.window.close
    }
    btnClose.position(-7, -7)
    btnClose.size(75, 23)
    @window.add_control( btnClose )

    @window
  end

  
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


end # module
