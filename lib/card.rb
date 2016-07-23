#--
#
# Author::    Jay Johnson 
# Copyright:: Copyright (c) 2015 Jay Johnson
# License::   Distributes under the same terms as Ruby
#
#++

require 'logging'

# Stack Overflow Luhn Checking helper mixin: http://stackoverflow.com/questions/1235863/test-if-a-string-is-basically-an-integer-in-quotes-using-ruby
class String
    def is_i?
       !!(self =~ /\A[-+]?[0-9]+\z/)
    end
end


# 
# This Card implementation is a standalone class and uses
# the associated member variables to track a Card's +@balance+,
# +@limit+, +@number+, and +@status+. If an invalid card number
# is passed in on initialization the Card object defaults to an
# invalid status. Limits and Balances start at 0, after the Card's 
# number is checked the limit is assigned to +limit+.
#
# It also uses the logging helper methods: lg_helper and dlg_helper
# to handle colorize-d logging and abstraction for enhancing rsyslog
# support.
#
class Card

    # 
    # Initializes the Card class to a Invalid state by default until
    # it passes the fraud screens.
    #
    # card_num - new card number for this card
    # limit - new card limit
    # debug - internal debug flag used for testing
    #
    def initialize(card_num, limit, debug=false)
        @card_number    = card_num
        @balance        = 0.0
        @limit          = 0.0
        @status         = "Invalid"

        # allow testers to override the Luhn check
        @bypass_luhn    = false

        # run fraud screens like Luhn 10 check:
        @is_valid       = perform_luhn_check()

        # if the card passes the fraud screens
        if @status == "Valid"
            @limit      = limit
        end

        @debug          = debug
    end

    # 
    # Wrapper for the lg_helper to log the msg at the appropriate
    # log level enumeration. For now the associated log stream is stdout.
    #
    # msg - the string message to log
    # level - the log level enumeration for enhancing to rsyslog
    # debug - defaults to false, ignored for now
    # 
    def lg(msg, level=6, debug=false)
        lg_helper(msg, level)
    end

    # 
    # Wrapper for the dlg_helper class that handles checking if the
    # +@debug+ variable for the class is +true+. If the @debug is false
    # the method does nothing, but if the @debug is true it will log 
    # to the associated log stream (stdout for now).
    #
    # msg - the string message to log
    # level - the log level enumeration for enhancing to rsyslog
    # 
    def dlg(msg, level=6)
        dlg_helper(msg, level, @debug)
    end

    # 
    # Perform the Luhn 10 Checks required to validate fraud screens prior
    # to assuming the account can charge and or credit to this card number.
    #
    # debug - internal debug flag used for testing
    #
    # returns - true if the card passes the fraud screens, false if not
    #
    def perform_luhn_check(debug=false)

        valid_card      = false

        # Assume the cards have to be a minimum length, so far the smallest amount
        # I have seen is 13 characters
        if @card_number.to_s.length < 13
            dlg("ERROR: Credit Cards(#{@card_number.to_s.length}) cannot be under 13 digits", 0)
            return valid_card
        end

        # Assume the cards have to be a maximum length (per the test setup), 
        # so far the largest amount
        # I have seen is 19 characters
        if @card_number.to_s.length > 19
            dlg("ERROR: Credit Cards(#{@card_number.to_s.length}) cannot be over 19 digits", 0)
            return valid_card
        end

        # Make sure to check that only positive numbers are supported as CC numbers
        if @card_number.to_s.is_i?!= true
            dlg("ERROR: Credit Cards(#{@card_number.to_s}) Must be Only Positive Numbers", 0)
            return valid_card
        end

        # Luhn Check from: http://stackoverflow.com/questions/9188360/implementing-the-luhn-algorithm-in-ruby
        dlg("Initial Screens Passed(#{@card_number.to_s}) IsInt(#{@card_number.to_s.is_i?})", 6)

        # Public: Validates number against Luhn 10 scheme
        #
        # Luhn Algo ripped from: http://en.wikipedia.org/wiki/Luhn_algorithm
        # 1. From the rightmost digit, which is the check digit, moving left, double the value of every second digit; if product of this doubling operation is greater than 9 (e.g., 7 * 2 = 14).
        # 2. Sum the digits of the products (e.g., 10: 1 + 0 = 1, 14: 1 + 4 = 5) together with the undoubled digits from the original number.
        # 3. If the total modulo 10 is equal to 0 (if the total ends in zero) then the number is valid according to the Luhn formula; else it is not valid.
        #
        # Returns true or false
        number = @card_number.to_s.
            gsub(/\D/, ''). # remove non-digits
            reverse  # read from right to left

        sum, i = 0, 0

        number.each_char do |ch|
            n = ch.to_i

            # Step 1
            n *= 2 if i.odd?

            # Step 2
            n = 1 + (n - 10) if n >= 10

            sum += n
            i   += 1
        end

        # Step 3
        valid_card      = (sum % 10).zero?

        # end of SO Luhn Check

        # allow rspec tests to toggle this
        if @bypass_luhn
            valid_card  = true
        end

        if valid_card
            
            dlg("Valid Card(#{@card_number})", 5)
            @status     = "Valid"
        else
            dlg("Failed Luhn Card(#{@card_number})", 0)
            @status     = "Invalid"
        end

        valid_card 
    end

    # 
    # Perform the Credit processing required to check if the new balance is over the limit (hard to do that
    # when it is a subtraction). Balances can go negative.
    #
    # amount - float holding the new amount balance to credit to this card
    #
    # returns - 1 if failed, 0 for success
    #
    def _credit_helper(amount)

        status  = 1

        begin
            # subtract the current balance by the new amount
            new_balance     = self.get_balance() - amount.to_i

            # hard to think this could happen, but it's a defensive check
            if new_balance > @limit
                lg("ERROR: Card(#{self.get_number()}) Overcredited(#{new_balance}) Limit(#{@limit})", 0)
            else

                # if the balance is a valid amount, assign the new balance
                status          = set_balance(new_balance)
                dlg("Credit Card(#{self.get_number()}) Balance(#{self.get_balance()})", 5)
                return 0
            end
        rescue Exception => e
            lg("ERROR: Failed to Credit Card(#{self.get_number()}) with Ex(#{e.message})", 0)
        end

        return status
    end

    # 
    # Perform the Charge processing required to check if the new balance is over the limit.
    # Balances can go negative, but they cannot go over the Card +@limit+
    #
    # amount - float holding the new amount balance to credit to this card
    #
    # returns - 1 if failed, 0 for success
    #
    def _charge_helper(amount)

        status              = 1
        begin

            # add the current balance by the new amount
            new_balance     = amount.to_i + self.get_balance()

            # per the SPEC make sure to check if this will go over the allowed limit, it is not permitted
            if new_balance > @limit
                dlg("ERROR: Card(#{self.get_number()}) Overcharged(#{new_balance}) Limit(#{@limit})", 0)

            else
                
                # if the balance is a valid amount, assign the new balance
                self.set_balance(new_balance)
                dlg("Charged Card(#{self.get_number()}) Balance(#{@balance})", 5)
                return 0
            end

        rescue Exception => e
            lg("ERROR: Failed to Charge Card(#{self.get_number()}) with Ex(#{e.message})", 0)
        end

        return status
    end

    # 
    # This method gets the +@balance+ member as an integer
    #
    # returns - +@balance+
    #
    def get_balance()
        @balance.to_i
    end 

    # 
    # This method sets the +@balance+ member as an integer
    #
    # new_balance - new balance for this Card
    #
    # returns - +@balance+
    #
    def set_balance(new_balance)
        @balance    = new_balance.to_i
    end 

    # 
    # This method gets the +@balance+ member as an integer
    #
    # new_balance - new balance for this Card
    #
    # returns - +@limit+
    #
    def get_limit()
        @limit.to_i
    end 

    # 
    # This method sets the +@limit+ member as an integer. This is a stub for
    # future enhancements.
    #
    # new_limit - new limit for this Card
    #
    # returns - +@limit+
    #
    def set_limit(new_limit)
        @limit      = new_limit.to_i
    end 

    # 
    # This method is a stub for future enhancements related to deactivating the card.
    #
    # returns - +@status+
    #
    def deactivate_card()
        @status         = "Invalid"
    end 

    # 
    # This method gets the Card status.
    #
    # returns - +@status+
    #
    def get_status()
        @status.to_s
    end 

    # 
    # This method gets the Card number.
    #
    # returns - +@card_number+
    #
    def get_number()
        @card_number.to_s
    end

    # 
    # This method tests if the Card is valid or not.
    #
    # returns - true if valid, false if not
    #
    def is_valid()
        @status == "Valid"
    end 

    # 
    # This method tests if the Card is invalid or not.
    #
    # returns - true if invalid, false if not
    #
    def is_invalid()
        (@status == "Invalid" or @status == "Failed Luhn")
    end 
end 
