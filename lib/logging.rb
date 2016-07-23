#--
#
# Author::    Jay Johnson 
# Copyright:: Copyright (c) 2015 Jay Johnson
# License::   Distributes under the same terms as Ruby
#
#++

require 'colorize'

# 
# This method implements a wrapper for printing or logging that is 
# shared across the system. I usually use logging as a singleton object, 
# but for simplicity I used these as 'singleton methods'.
#
# msg - the string message to log
# level - the log level enumeration for enhancing to rsyslog
# 
def lg_helper(msg, level=6)
    if    level == 6
        puts msg
    elsif level == 0
        puts msg.red
    elsif level == 1
        puts msg.red
    elsif level == 2
        puts msg.yellow
    elsif level == 3
        puts msg.yellow
    elsif level == 4
        puts msg.blue
    elsif level == 5
        puts msg.green
    elsif level > 5
        puts msg
    end
end

# 
# This method implements a wrapper for printing or logging that is 
# shared across the system. I usually use logging as a singleton object,
# but for simplicity I used these as 'singleton methods'. This method 
# is intended for tracing errors similar to compiling a C/C++ binary
# that has the debug preprocessor logging enabled. 
#
# msg - the string message to log
# level - the log level enumeration for enhancing to rsyslog
# debug - flag for logging this message usually the member variable
#         of the owning object invoking this method.
# 
def dlg_helper(msg, level=6, debug=false)
    if debug
        lg_helper(msg, level)
    end
end

