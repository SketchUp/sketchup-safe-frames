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


end # module
