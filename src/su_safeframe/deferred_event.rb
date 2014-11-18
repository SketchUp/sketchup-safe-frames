#-------------------------------------------------------------------------------
#
# Copyright 2013-2014 Trimble Navigation Ltd.
# License: The MIT License (MIT)
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
