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

  # The precision floating point values are displayed at.
  # @since 1.0.0
  PRECISION = 2

  # @since 1.0.0
  def self.create_camera_window
    #puts 'self.create_camera_window'
    view = Sketchup.active_model.active_view
    camera = view.camera

    options = {
      :title           => PLUGIN_NAME,
      :preferences_key => PLUGIN_ID,
      :width           => 255,
      :height          => 290,
      :resizable       => false
    }
    @window = SKUI::Window.new(options)
    
    # Camera Aspect Ratio Group
    gAspect = SKUI::Groupbox.new('Viewport')
    gAspect.position(5, 5)
    gAspect.right = 5
    gAspect.height = 125
    @window.add_control(gAspect)

    # Aspect Ratio
    eAspectChange = DeferredEvent.new { |value| self.aspect_changed(value) }
    aspect_ratio = Locale.float_to_string(camera.aspect_ratio, PRECISION)
    txtAspectRatio = SKUI::Textbox.new(aspect_ratio)
    txtAspectRatio.name = :txt_aspect_ratio
    txtAspectRatio.position(100, 20)
    txtAspectRatio.width = 45
    txtAspectRatio.on(:textchange) { |control|
      eAspectChange.call(control.value)
    }
    gAspect.add_control(txtAspectRatio)
    
    lblWidth = SKUI::Label.new('Aspect Ratio:', txtAspectRatio)
    lblWidth.position(10, 23)
    lblWidth.width = 85
    lblWidth.align = :right
    gAspect.add_control(lblWidth)
    
    btnResetAspect = SKUI::Button.new('Reset') { |control|
      zero = Locale.float_to_string(0.0)
      @window[:txt_aspect_ratio].value = zero
      self.aspect_changed(zero)
    }
    btnResetAspect.position(-10, 19)
    btnResetAspect.size(75, 23)
    gAspect.add_control(btnResetAspect)

    # Angle of View Info
    x_aov, y_aov = self.get_camera_xy_aov(view)
    x_aov = Locale.float_to_string(x_aov, PRECISION)
    y_aov = Locale.float_to_string(y_aov, PRECISION)

    eAovXChange = DeferredEvent.new { |value| self.aov_x_changed(value) }
    txtAovX = SKUI::Textbox.new(x_aov)
    txtAovX.name = :txt_aov_x
    txtAovX.position(100, 50)
    txtAovX.width = 45
    txtAovX.on(:textchange) { |control|
      eAovXChange.call(control.value)
    }
    gAspect.add_control(txtAovX)

    lblAovX = SKUI::Label.new("AOV X°:", txtAovX)
    lblAovX.position(10, 55)
    lblAovX.width = 85
    lblAovX.align = :right
    gAspect.add_control(lblAovX)

    eAovYChange = DeferredEvent.new { |value| self.aov_y_changed(value) }
    txtAovY = SKUI::Textbox.new(y_aov)
    txtAovY.name = :txt_aov_y
    txtAovY.position(100, 75)
    txtAovY.width = 45
    txtAovY.on(:textchange) { |control|
      eAovYChange.call(control.value)
    }
    gAspect.add_control(txtAovY)

    lblAovY = SKUI::Label.new("AOV Y°:", txtAovY)
    lblAovY.position(10, 80)
    lblAovY.width = 85
    lblAovY.align = :right
    gAspect.add_control(lblAovY)
    
    # Export Viewport Group
    gExport = SKUI::Groupbox.new('Export 2D')
    gExport.position(5, 120)
    gExport.right = 5
    gExport.height = 125
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

    lblUnits = SKUI::Label.new('px')
    lblUnits.position(-10, 23)
    gExport.add_control(lblUnits)
    
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
    #puts "width_changed( #{value} )"
    view = Sketchup.active_model.active_view
    if view.camera.aspect_ratio == 0.0
      ratio = view.vpheight.to_f / view.vpwidth.to_f
    else
      ratio = 1.0 / view.camera.aspect_ratio
    end
    @window[:txt_height].value = ( value.to_i * ratio ).to_i
    nil
  end
  
  
  # @since 1.0.0
  def self.height_changed(value)
    #puts "height_changed( #{value} )"
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
    #puts "aspect_changed( #{value} )"
    aspect_ratio = Locale.string_to_float(value)
    view = Sketchup.active_model.active_view
    self.set_aspect_ratio(view, aspect_ratio, FIX_CAMERA_ZOOM)
    if @window
      self.width_changed(@window[:txt_width].value)
      self.update_aov
    end
    nil
  end


  # @since 1.0.0
  def self.aov_x_changed(value)
    #puts "aov_x_changed( #{value} )"
    view = Sketchup.active_model.active_view

    aov_x = Locale.string_to_float(value)
    self.set_aov_x(view, aov_x)

    x_aov, y_aov = self.get_camera_xy_aov(view)
    y_aov = Locale.float_to_string(y_aov, PRECISION)
    @window[:txt_aov_y].value = y_aov
    nil
  end


  # @since 1.0.0
  def self.aov_y_changed(value)
    #puts "aov_y_changed( #{value} )"
    view = Sketchup.active_model.active_view

    aov_y = Locale.string_to_float(value)
    self.set_aov_y(view, aov_y)

    x_aov, y_aov = self.get_camera_xy_aov(view)
    x_aov = Locale.float_to_string(x_aov, PRECISION)
    @window[:txt_aov_x].value = x_aov
    nil
  end


  # @since 1.0.0
  def self.update_aov
    #puts "update_aov()"
    view = Sketchup.active_model.active_view
    x_aov, y_aov = self.get_camera_xy_aov(view)
    x_aov = Locale.float_to_string(x_aov, PRECISION)
    y_aov = Locale.float_to_string(y_aov, PRECISION)
    @window[:txt_aov_x].value = x_aov
    @window[:txt_aov_y].value = y_aov
    nil
  end


end # module
